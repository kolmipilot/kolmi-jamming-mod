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
    [_target, "Peral_F35B_CM_Launcher"] call BIS_fnc_fire;
    // launcher that fired the missile (used to pin the seeker in the tracker)
    private _shooter = _vehicle;
    if (isNull _shooter) then {
        _shooter = _instigator;
    };

    // Poll this missile until it hits / explodes / disappears
    private _pfh = [{
        params ["_args", "_handle"];
        _args params ["_target", "_missile", "_shooter", "_seeker"];

        // Stop tracking once the missile is gone
        if (isNull _target || isNull _missile || !alive _missile) exitWith {
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
        // flicker while the IR/radar signatures come and go mid-flight.
        if (_seeker isEqualTo "Unknown") then {
            // Real data samples:
            //   IR MANPADS : [missile,"missile",["missile"]], [shooter,"marked"/"locked",["ir"]]
            //   Radar SAM  : [missile,"missile",["radar","missile"]], [unit,"locked",["radar"]]
            private _shooterSensors = [];
            private _irInPicture = false;
            private _radarInPicture = false;
            private _laserInPicture = false;

            {
                private _sensors = _x select 2;
                if (_sensors isEqualType "") then {
                    _sensors = [_sensors];
                };

                // 1) sensors of the entry belonging to the thing that fired this missile
                if ((_x select 0) isEqualTo _shooter) then {
                    _shooterSensors = _sensors apply {toLower _x};
                };

                // 2) whole sensor picture as a fallback
                {
                    switch (toLower _x) do {
                        case "ir": { _irInPicture = true };
                        case "radar": { _radarInPicture = true };
                        case "laser": { _laserInPicture = true };
                    };
                } forEach _sensors;
            } forEach _threats;

            // 3) the missile's own entry sensors
            private _ownThreat = _threats param [_threats findIf {(_x select 0) isEqualTo _missile}, [], [[]]];
            private _own = [];
            if (count _ownThreat > 0) then {
                _own = _ownThreat select 2;
                if (_own isEqualType "") then {
                    _own = [_own];
                };
                _own = _own apply {toLower _x};
            };

            // priority: shooter -> own entry -> whole picture
            if ("ir" in _shooterSensors) then { _seeker = "IR" };
            if (_seeker isEqualTo "Unknown" && {"radar" in _shooterSensors}) then { _seeker = "ARH" };
            if (_seeker isEqualTo "Unknown" && {"laser" in _shooterSensors}) then { _seeker = "Laser" };

            if (_seeker isEqualTo "Unknown" && {"radar" in _own}) then { _seeker = "ARH" };
            if (_seeker isEqualTo "Unknown" && {"laser" in _own}) then { _seeker = "Laser" };

            if (_seeker isEqualTo "Unknown" && _irInPicture) then { _seeker = "IR" };
            if (_seeker isEqualTo "Unknown" && _radarInPicture) then { _seeker = "ARH" };
            if (_seeker isEqualTo "Unknown" && _laserInPicture) then { _seeker = "Laser" };

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
            systemChat format ["Incoming Missile, seeker: %1 | %2 m | dir %3", _seeker, _distanceM, _dir];
        };
    }, 1, [_target, _missile, _shooter, "Unknown"]] call CBA_fnc_addPerFrameHandler;

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
    private _markerName = format ["LaunchSite_%1", netId _target + "_" + str (tickTime)];
    _marker = createMarkerLocal [_markerName, _randomizedPos];
    _marker setMarkerColorLocal "ColorRed";
    _marker setMarkerShapeLocal "ELLIPSE";
    _marker setMarkerSizeLocal [_errorRadius, _errorRadius];
    _marker setMarkerAlphaLocal 0.6;
    private _textMarker = createMarkerLocal [format ["%1_text", _markerName], _randomizedPos];
    _textMarker setMarkerShapeLocal "ICON";
    _textMarker setMarkerTypeLocal "mil_dot";
    _textMarker setMarkerColorLocal "ColorRed";
    _textMarker setMarkerTextLocal " DAS: Launch Detected";

}, [_target, _vehicle], 15] call CBA_fnc_waitAndExecute;



    // Remember the tracking handle for stopDas
    _plane setVariable [QGVAR(DasPfhs), (_plane getVariable [QGVAR(DasPfhs), []]) + [_pfh], true];
}, _plane] call CBA_fnc_addBISEventHandler;

_plane setVariable [QGVAR(DasId), _id, true];
