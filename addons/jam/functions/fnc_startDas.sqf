#include "..\script_component.hpp"

params ["_plane"];

_plane setVariable [QGVAR(DasActive), true, true];

// Handles of the per-missile polling loops, so stopDas can clean them up
_plane setVariable [QGVAR(DasPfhs), [], true];

// Catch every missile fired on the plane. Engine event params:
// _this = [target, ammo, vehicle, instigator, missile]
private _id = [_plane, "IncomingMissile", {
    params ["_target", "_ammo", "_vehicle", "_instigator", "_missile"];

    // Event handlers run in their own scope - get the plane via CBA's _thisArgs instead
    private _plane = _thisArgs;
    if (GVAR(enableVodkaEffect)) then {
        [_target, "Peral_F35B_CM_Launcher"] call BIS_fnc_fire;
    };
    // launcher that fired the missile (used to pin the seeker in the tracker)
    private _shooter = _vehicle;
    if (isNull _shooter) then {
        _shooter = _instigator;
    };

    // Poll this missile until it hits / explodes / disappears
    private _pfh = [{
        params ["_args", "_handle"];
        _args params ["_target", "_missile", "_shooter", "_seeker", "_ammo"];

        // Stop tracking once the missile is gone
        if (isNull _target || isNull _missile || !alive _missile) exitWith {
            private _dasArray = _target getVariable [QGVAR(dasArray), []];
            private _dasIndex = _dasArray findIf {(_x param [0, objNull]) isEqualTo _missile};
            if (_dasIndex >= 0) then {
                _dasArray deleteAt _dasIndex;
                _target setVariable [QGVAR(dasArray), _dasArray, true];
            };
            [_handle] call CBA_fnc_removePerFrameHandler;
        };

        private _distanceM = _target distance _missile;
        private _dir = _target getDir _missile;

        // getSensorThreats returns [[object, type, sensors], ...]:
        //   object  - the missile / marking-locking unit
        //   type    - "missile" | "locked" | "marked"
        //   sensors - e.g. ["radar","missile"], ["ir"], ["laser"], ["visual"], ...
        private _threats = getSensorThreats _target;
        TRACE_1("sensor threats",_threats);

        // Detect the seeker ONCE and cache it in _args, so the label doesn't
        // flicker while the missile sensor signatures come and go mid-flight.
        if (_seeker isEqualTo "Unknown") then {
            // 1) missile's own entry sensors only
            private _ownThreat = _threats param [_threats findIf {(_x select 0) isEqualTo _missile}, [], [[]]];
            private _own = [];
            if (count _ownThreat > 0) then {
                _own = _ownThreat select 2;
                if (_own isEqualType "") then {
                    _own = [_own];
                };
                _own = _own apply {toLower _x};
            };

            if ("ir" in _own) then { _seeker = "IR" };
            if (_seeker isEqualTo "Unknown" && {"radar" in _own}) then { _seeker = "ARH" };
            if (_seeker isEqualTo "Unknown" && {"laser" in _own}) then { _seeker = "Laser" };

            // 2) ACE seeker metadata
            if (_seeker isEqualTo "Unknown") then {
                private _ammoCfg = configFile >> "CfgAmmo" >> _ammo >> "ace_missileguidance";
                private _defaultSeeker = toUpper getText (_ammoCfg >> "defaultSeekerType");

                if (_defaultSeeker in ["SALH", "LIDAR", "SACLOS", "MCLOS"]) then {
                    _seeker = "Laser";
                } else {
                    if (_defaultSeeker isEqualTo "SARH") then {
                        _seeker = "ARH";
                    } else {
                        if (_defaultSeeker in ["THERMAL", "OPTIC"]) then {
                            _seeker = "IR";
                        };
                    };
                };
            };

            // 3) vanilla lock type
            if (_seeker isEqualTo "Unknown") then {
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

                if (_lockValues isNotEqualTo []) then {
                    if (2 in _lockValues) then { _seeker = "IR" };
                    if (_seeker isEqualTo "Unknown" && {8 in _lockValues}) then { _seeker = "ARH" };
                    if (_seeker isEqualTo "Unknown" && {4 in _lockValues}) then { _seeker = "Laser" };
                };
            };

            _args set [3, _seeker];
        };

        // Tag every missile threat with the seeker as a 4th element:
        // [missileObj, "missile", [sensors], seeker]
        private _missileThreats = (_threats select {(_x select 1) isEqualTo "missile"}) apply {
            _x + [_seeker]
        };

        // The missile from this event, inside the threat list
        private _index = _missileThreats findIf {(_x select 0) isEqualTo _missile};
        if (_index >= 0) then {
            private _seeker = (_missileThreats select _index) select 3;
            private _dasArray = _target getVariable [QGVAR(dasArray), []];
            private _dasIndex = _dasArray findIf {(_x param [0, objNull]) isEqualTo _missile};
            private _dasEntry = [_missile, _seeker, _distanceM, _dir];

            if (_dasIndex >= 0) then {
                _dasArray set [_dasIndex, _dasEntry];
            } else {
                _dasArray pushBack _dasEntry;
            };

            _target setVariable [QGVAR(dasArray), _dasArray, true];
        };
    }, 1, [_target, _missile, _shooter, "Unknown", _ammo]] call CBA_fnc_addPerFrameHandler;

    [{
    params ["_target", "_vehicle"];
    if (isNull _target || isNull _vehicle) exitWith {};
    private _distanceM = _target distance _vehicle;
    private _truePosition = position _vehicle;
    private _errorRadius = _distanceM * 0.05;
    private _randomAngle = random 360;
    private _randomDist = random _errorRadius;
    private _jameX = (_truePosition select 0) + (_randomDist * sin _randomAngle);
    private _jameY = (_truePosition select 1) + (_randomDist * cos _randomAngle);
    private _randomizedPos = [_jameX, _jameY, 0];
    private _markerName = format ["LaunchSite_%1_%2", netId _target, diag_tickTime + random 1000000];
    private _marker = createMarkerLocal [_markerName, _randomizedPos];
    _marker setMarkerColorLocal "ColorRed";
    _marker setMarkerShapeLocal "ELLIPSE";
    _marker setMarkerSizeLocal [_errorRadius, _errorRadius];
    _marker setMarkerAlphaLocal 0.6;

    private _type = if (_vehicle isKindOf "Air") then {"AA"} else {"SAM"};
    private _textMarker = createMarkerLocal [format ["%1_text", _markerName], _randomizedPos];
    _textMarker setMarkerShapeLocal "ICON";
    _textMarker setMarkerTypeLocal "mil_dot";
    _textMarker setMarkerColorLocal "ColorRed";
    _textMarker setMarkerTextLocal format [" DAS: %1 Launch Detected", _type];

}, [_target, _vehicle], 15] call CBA_fnc_waitAndExecute;

    // Remember the tracking handle for stopDas
    _plane setVariable [QGVAR(DasPfhs), (_plane getVariable [QGVAR(DasPfhs), []]) + [_pfh], true];
    
    // Start UI monitoring PFH on first missile
    if (vehicle player isEqualTo _target) then {
        [player] call FUNC(UI);
    };
}, _plane] call CBA_fnc_addBISEventHandler;

_plane setVariable [QGVAR(DasId), _id, true];
