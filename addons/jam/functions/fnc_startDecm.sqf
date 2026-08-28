#include "..\script_component.hpp"

params ["_plane"];

_plane setVariable [QGVAR(DecmActive), true, true];
_plane setVariable [QGVAR(DecmPfhs), [], true];

private _id = [_plane, "IncomingMissile", {
    params ["_target", "_ammo", "_vehicle", "_instigator", "_missile"];

    private _plane = _thisArgs;

    private _seeker = "Unknown";
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
    TRACE_3("DECM classified seeker",_missile,_ammo,_seeker);

    if (_seeker isEqualTo "ARH") then {

    private _pfh = [{
        params ["_args", "_handle"];
        _args params ["_target", "_missile", "_plane", "_ammo", "_seeker"];

        if (isNull _plane || {!alive _plane} || {!(isNull (driver _plane)) && {!alive (driver _plane)}}) exitWith {
            [_handle] call CBA_fnc_removePerFrameHandler;
        };

        if (isNull _target || isNull _missile || !alive _missile) exitWith {
            TRACE_2("DECM missile removed",_missile,_target);
            private _pfhs = _plane getVariable [QGVAR(DecmPfhs), []];
            private _pfhIndex = _pfhs find _handle;
            if (_pfhIndex >= 0) then {
                _pfhs deleteAt _pfhIndex;
                _plane setVariable [QGVAR(DecmPfhs), _pfhs, true];
            };
            [_handle] call CBA_fnc_removePerFrameHandler;
        };

        TRACE_3("DECM tick",_missile,_ammo,_seeker);

            private _dasArray = _plane getVariable [QGVAR(dasArray), []];
            private _dasIndex = _dasArray findIf {(_x param [0, objNull]) isEqualTo _missile};
            if (_dasIndex >= 0) then {
                private _dasEntry = _dasArray select _dasIndex;
                _dasEntry set [4, "JAMMING"];
                _dasEntry set [5, 0];
                _dasArray set [_dasIndex, _dasEntry];
            } else {
                _dasArray pushBack [_missile, _seeker, 0, 0, "JAMMING", 0];
            };
            _plane setVariable [QGVAR(dasArray), _dasArray, true];

            private _jamRoll = random 100;
            private _jammed = _jamRoll > 100 - GVAR(MissleJammingChance);
            TRACE_5("DECM jam check",_missile,_seeker,_jamRoll,GVAR(MissleJammingChance),_jammed);

            if (_jammed) then {
                TRACE_2("DECM jam success",_missile,_target);
                _dasArray = _plane getVariable [QGVAR(dasArray), []];
                _dasIndex = _dasArray findIf {(_x param [0, objNull]) isEqualTo _missile};
                if (_dasIndex >= 0) then {
                    private _dasEntry = _dasArray select _dasIndex;
                    _dasEntry set [4, "JAMMED"];
                    _dasEntry set [5, time + 7];
                    _dasArray set [_dasIndex, _dasEntry];
                } else {
                    _dasArray pushBack [_missile, _seeker, 0, 0, "JAMMED", time + 7];
                };
                _plane setVariable [QGVAR(dasArray), _dasArray, true];
                if (vehicle player isEqualTo _target) then {
                    [player] call FUNC(UI);
                };
                if (_missile distance _plane < 500) then {
                    private _ewdir = (getDir _missile) - 180;
                    _missile setDir _ewdir;
                    [{
                        params ["_mssl"];
                        if (!isNull _mssl) then {
                            deleteVehicle _mssl;
                        };
                    }, _missile, 1] call CBA_fnc_waitAndExecute;
                } else {
                    deleteVehicle _missile;
                };
            } else {
                TRACE_2("DECM jam fail",_missile,_target);
            };
    }, GVAR(MissleJammingInterval), [_target, _missile, _plane, _ammo, _seeker]] call CBA_fnc_addPerFrameHandler;
    _plane setVariable [QGVAR(DecmPfhs), (_plane getVariable [QGVAR(DecmPfhs), []]) + [_pfh], true];
    };
}, _plane] call CBA_fnc_addBISEventHandler;

_plane setVariable [QGVAR(DecmId), _id, true];

