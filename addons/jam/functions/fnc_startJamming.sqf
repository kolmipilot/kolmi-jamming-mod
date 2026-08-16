#include "..\script_component.hpp"
params ["_plane"];

// Lock state globally instantly
_plane setVariable [QGVAR(EwsActive), true, true];

private _range = GVAR(EcmRange);
private _sleep_time = GVAR(EcmTime);
private _cooltime = GVAR(EcmCoolTime);
private _side = side (driver _plane);

/* for AWS implemenation, for now only for pearl f35
private _pylons = getPylonMagazines _plane;
{
    private _ecm = getNumber (configFile >> "CfgMagazines" >> _x >> "AWS_ECMJAMMER");
    if (_ecm == 1) then {
        _range = _range + 5000;
        _sleep_time = _sleep_time + 10;
        _cooltime = _cooltime - 10;     
    };
} forEach _pylons;
*/
systemChat format["SYSTEM: SENSOR JAMMING INITIATED. TIME: %1 sec", _sleep_time];

// Detect targets
private _getunits = _plane nearEntities [["Air", "Tank"], _range];
private _hostiles = [];

{
    if ((side _x != _side) && {[_side, side _x] call BIS_fnc_sideIsEnemy}) then {
        _hostiles pushBack _x;
    };
} forEach _getunits;

// Disable Sensors utilizing CBA target events natively
{
    private _unit = _x;
    private _unit_type = typeOf _unit;
    private _components = "getText (_x >> 'componentType') == 'ActiveRadarSensorComponent'" configClasses (configFile >> "CfgVehicles" >> _unit_type >> "Components" >> "SensorsManagerComponent" >> "Components");
    
    if (count _components > 0) then {
        private _componame = configName (_components select 0);
        
        // Emits safely over the network targeting the specific computer owning the asset
        [QGVAR(disableSensorEvent), [_unit, _componame], _unit] call CBA_fnc_targetEvent;
    };
} forEach _hostiles;

// Schedule the cleanup execution asynchronously without locking the frame or spawning a thread
[
    FUNC(stopJamming), 
    [_plane, _hostiles, _cooltime], 
    _sleep_time
] call CBA_fnc_waitAndExecute;
