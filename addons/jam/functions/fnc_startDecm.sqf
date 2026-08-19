#include "..\script_component.hpp"

params ["_plane"];

_plane setVariable [QGVAR(DecmActive), true, true];
_plane setVariable [QGVAR(DecmPfhs), [], true];

// Initialize jamming array for storing jam status
_plane setVariable [QGVAR(decmArray), [], true];

// Catch every missile fired on the plane. Engine event params:
// _this = [target, ammo, vehicle, instigator, missile]
private _id = [_plane, "IncomingMissile", {
    params ["_target", "_ammo", "_vehicle", "_instigator", "_missile"];

    // event handlers run in their own scope - take the plane from _thisArgs
    private _plane = _thisArgs;

    // Poll every MissleJammingInterval - classify and update jam status
    private _pfh = [{
        params ["_args", "_handle"];
        _args params ["_target", "_missile", "_plane", "_ammo", "_seeker"];

        // Stop tracking once the missile is gone
        if (isNull _target || isNull _missile || !alive _missile) exitWith {
            TRACE_2("DECM missile removed",_missile,_target);
            private _decmArray = _plane getVariable [QGVAR(decmArray), []];
            private _decmIndex = _decmArray findIf {(_x param [0, objNull]) isEqualTo _missile};
            if (_decmIndex >= 0) then {
                _decmArray deleteAt _decmIndex;
                _plane setVariable [QGVAR(decmArray), _decmArray, true];
            };

            private _pfhs = _plane getVariable [QGVAR(DecmPfhs), []];
            private _pfhIndex = _pfhs find _handle;
            if (_pfhIndex >= 0) then {
                _pfhs deleteAt _pfhIndex;
                _plane setVariable [QGVAR(DecmPfhs), _pfhs, true];
            };
            [_handle] call CBA_fnc_removePerFrameHandler;
        };

        TRACE_4("DECM tick",_missile,_ammo,_seeker,"classifying");

        // Decide ONCE if it is radar homing using only ammo metadata
        if (_seeker isEqualTo "Unknown") then {
            private _ammoCfg = configFile >> "CfgAmmo" >> _ammo >> "ace_missileguidance";
            private _defaultSeeker = toUpper getText (_ammoCfg >> "defaultSeekerType");

            if (_defaultSeeker in ["SARH"]) then {
                _seeker = "ARH";
            } else {
                if (_defaultSeeker in ["SALH", "LIDAR", "SACLOS", "MCLOS", "THERMAL", "OPTIC"]) then {
                    _seeker = "Other";
                } else {
                    private _weaponLockCfg = configFile >> "CfgAmmo" >> _ammo >> "weaponLockSystem";
                    private _lockValues = [];

                    if (isNumber _weaponLockCfg) then {
                        private _lockSystem = getNumber _weaponLockCfg;
                        {
                            private _flag = _x;
                            if ((_lockSystem % (_flag * 2)) >= _flag) then {
                                _lockValues pushBack _flag;
                            };
                        } forEach [1, 2, 4, 8, 16];
                    } else {
                        if (isText _weaponLockCfg) then {
                            private _lockText = toLowerANSI getText _weaponLockCfg;
                            if (_lockText != "") then {
                                _lockValues = (_lockText splitString "+") apply {parseNumber _x};
                            };
                        };
                    };

                    if (8 in _lockValues) then {
                        _seeker = "ARH";
                    } else {
                        _seeker = "Other";
                    };
                };
            };

            _args set [4, _seeker];
            TRACE_3("DECM classified seeker",_missile,_ammo,_seeker);
        };

        // For ARH missiles, roll jamming chance
        if (_seeker isEqualTo "ARH") then {
            private _jamRoll = random 100;
            private _jammed = _jamRoll > 100 - GVAR(MissleJammingChance);
            TRACE_5("DECM jam check",_missile,_seeker,_jamRoll,GVAR(MissleJammingChance),_jammed);

            // Store jam status in decmArray for UI to read
            private _decmArray = _plane getVariable [QGVAR(decmArray), []];
            private _decmIndex = _decmArray findIf {(_x param [0, objNull]) isEqualTo _missile};
            private _decmEntry = [_missile, _jammed];

            if (_decmIndex >= 0) then {
                _decmArray set [_decmIndex, _decmEntry];
            } else {
                _decmArray pushBack _decmEntry;
            };

            _plane setVariable [QGVAR(decmArray), _decmArray, true];

            if (_jammed) then {
                TRACE_2("DECM jam success",_missile,_target);
                // Immediately refresh UI to show orange/JAMMED state
                if (vehicle player isEqualTo _target) then {
                    [player] call FUNC(UI);
                };
                // Remove from DAS array immediately so it doesn't linger
                private _dasArray = _target getVariable [QGVAR(dasArray), []];
                private _dasIndex = _dasArray findIf {(_x param [0, objNull]) isEqualTo _missile};
                if (_dasIndex >= 0) then {
                    _dasArray deleteAt _dasIndex;
                    _target setVariable [QGVAR(dasArray), _dasArray, true];
                };
                // Delete the missile immediately
                waitUntil {_missile distance _plane < 500};

                _ewdir = getDir _missile;
                _ewdir = _ewdir - 180;
                _missile setDir _ewdir;
                [{
                    params ["_mssl"];
                    deleteVehicle _mssl;
                }, _missile, 1] call CBA_fnc_waitAndExecute;
            } else {
                TRACE_2("DECM jam fail",_missile,_target);
            };
        };
    }, GVAR(MissleJammingInterval), [_target, _missile, _plane, _ammo, "Unknown"]] call CBA_fnc_addPerFrameHandler;

    _plane setVariable [QGVAR(DecmPfhs), (_plane getVariable [QGVAR(DecmPfhs), []]) + [_pfh], true];
}, _plane] call CBA_fnc_addBISEventHandler;

_plane setVariable [QGVAR(DecmId), _id, true];

