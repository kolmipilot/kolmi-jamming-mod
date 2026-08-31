#include "..\script_component.hpp"
params ["_plane", "_hostiles", "_cooltime"];

systemChat format ["SYSTEM: SENSOR JAMMING COMPLETED. COOLDOWN: %1 sec", _cooltime];

// Restore Sensors where targets live
{
    private _unit = _x;
    if (alive _unit) then {
        private _unit_type = typeOf _unit;
        private _components = "getText (_x >> 'componentType') == 'ActiveRadarSensorComponent'" configClasses (configFile >> "CfgVehicles" >> _unit_type >> "Components" >> "SensorsManagerComponent" >> "Components");
        
        if (count _components > 0) then {
            private _componame = configName (_components select 0);
            
            // Re-enable via dedicated target event
            [QGVAR(restoreSensorEvent), [_unit, _componame], _unit] call CBA_fnc_targetEvent;
        };
    };
} forEach _hostiles;

// Stand-by / available again after the cooldown (measured from when jamming ended).
[{
    params ["_plane"];
    if (!isNull _plane) then {
        _plane setVariable [QGVAR(EwsActive), false, true];
        systemChat "SYSTEM: SENSOR JAMMER STAND-BY. READY FOR USE.";
    };
}, [_plane], _cooltime] call CBA_fnc_waitAndExecute;
