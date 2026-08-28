#include "..\script_component.hpp"
params ["_plane"];

// Lock state globally instantly
_plane setVariable [QGVAR(EwsActive), true, true];
TRACE_1("ecm activated for plane:",_plane);

private _range = GVAR(EcmRange);
private _sleep_time = GVAR(EcmTime);
private _cooltime = GVAR(EcmCoolTime);
private _side = side (driver _plane);

// Hostiles accumulate across re-sweeps, so sensors are restored for ALL of them.
_plane setVariable [QGVAR(ecmHostiles), [], true];

private _pfh = [{
    params ["_args", "_handle"];
    _args params ["_range", "_sleep_time", "_plane", "_side", "_cooltime", "_startTime"];

    // stop everything if the plane is dead
    if (isNull _plane || {!alive _plane}) exitWith {
        [_handle] call CBA_fnc_removePerFrameHandler;
    };

    private _hostiles = _plane getVariable [QGVAR(ecmHostiles), []];

    // add any new hostiles that entered range since the last sweep
    {
        if ((side _x != _side) && {[_side, side _x] call BIS_fnc_sideIsEnemy} && {!(_x in _hostiles)}) then {
            _hostiles pushBack _x;
        };
    } forEach (_plane nearEntities [["Air", "Tank", "Car", "LandVehicle", "AllVehicles"], _range]);

    // disable radar sensors on all tracked hostiles
    {
        private _unit = _x;
        if (alive _unit) then {
            private _unit_type = typeOf _unit;
            private _components = "getText (_x >> 'componentType') == 'ActiveRadarSensorComponent'" configClasses (configFile >> "CfgVehicles" >> _unit_type >> "Components" >> "SensorsManagerComponent" >> "Components");

            if (count _components > 0) then {
                private _componame = configName (_components select 0);

                // Emits safely over the network targeting the specific computer owning the asset
                [QGVAR(disableSensorEvent), [_unit, _componame], _unit] call CBA_fnc_targetEvent;
            };
        };
    } forEach _hostiles;

    _plane setVariable [QGVAR(ecmHostiles), _hostiles, true];
    TRACE_1("ecm for enemies",_hostiles);

    // jamming window over - stop the sweep and restore all jammed sensors
    if (diag_tickTime - _startTime >= _sleep_time) exitWith {
        [_handle] call CBA_fnc_removePerFrameHandler;
        [_plane, _hostiles, _cooltime] call FUNC(stopJamming);
    };
}, GVAR(SensorJammingInterval), [_range, _sleep_time, _plane, _side, _cooltime, diag_tickTime]] call CBA_fnc_addPerFrameHandler;

_plane setVariable [QGVAR(ecmPfh), _pfh];

[
    {
        params ["_plane"];
        _plane setVariable [QGVAR(EwsActive), false, true];
        systemChat "SYSTEM: SENSOR JAMMER STAND-BY.";
    },
    [_plane],
    _cooltime
] call CBA_fnc_waitAndExecute;
