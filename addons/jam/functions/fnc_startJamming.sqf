#include "..\script_component.hpp"
params ["_plane"];

_plane setVariable [QGVAR(EwsActive), true, true];
TRACE_1("ecm activated for plane:",_plane);
systemChat format ["SYSTEM: SENSOR JAMMING ACTIVE. RANGE: %1 m, TIME: %2 s", GVAR(EcmRange), GVAR(EcmTime)];

private _range = GVAR(EcmRange);
private _sleep_time = GVAR(EcmTime);
private _cooltime = GVAR(EcmCoolTime);
private _side = side (driver _plane);

private _ewsUnits = missionNamespace getVariable [QGVAR(ewsUnits), []];
private _index = _ewsUnits findIf {(_x select 0) isEqualTo typeOf _plane};

if (_index != -1) then {
    private _planeData = _ewsUnits select _index;

    _range = _planeData select 1;
    _sleep_time = _planeData select 2;
    _cooltime = _planeData select 3;
};

_plane setVariable [QGVAR(ecmHostiles), [], true];

private _pfh = [{
    params ["_args", "_handle"];
    _args params ["_range", "_sleep_time", "_plane", "_side", "_cooltime", "_startTime"];

    if (isNull _plane || {!alive _plane}) exitWith {
        [_handle] call CBA_fnc_removePerFrameHandler;
    };

    private _hostiles = _plane getVariable [QGVAR(ecmHostiles), []];

    {
        if ((side _x != _side) && {[_side, side _x] call BIS_fnc_sideIsEnemy} && {!(_x in _hostiles)}) then {
            _hostiles pushBack _x;
        };
    } forEach (_plane nearEntities [["Air", "Tank", "Car", "LandVehicle", "AllVehicles"], _range]);

    {
        private _unit = _x;
        if (alive _unit) then {
            private _unit_type = typeOf _unit;
            private _components = "getText (_x >> 'componentType') == 'ActiveRadarSensorComponent'" configClasses (configFile >> "CfgVehicles" >> _unit_type >> "Components" >> "SensorsManagerComponent" >> "Components");

            if (count _components > 0) then {
                private _componame = configName (_components select 0);

                [QGVAR(disableSensorEvent), [_unit, _componame], _unit] call CBA_fnc_targetEvent;
            };
        };
    } forEach _hostiles;

    _plane setVariable [QGVAR(ecmHostiles), _hostiles, true];
    TRACE_1("ecm for enemies",_hostiles);

    if (diag_tickTime - _startTime >= _sleep_time) exitWith {
        [_handle] call CBA_fnc_removePerFrameHandler;
        [_plane, _hostiles, _cooltime] call FUNC(stopJamming);
    };
}, GVAR(SensorJammingInterval), [_range, _sleep_time, _plane, _side, _cooltime, diag_tickTime]] call CBA_fnc_addPerFrameHandler;

_plane setVariable [QGVAR(ecmPfh), _pfh];
