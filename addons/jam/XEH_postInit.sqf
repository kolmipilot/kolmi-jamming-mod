#include "script_component.hpp"

missionNamespace setVariable [QGVAR(ewsPlanesList), [GVAR(ewsPlanes), "CfgVehicles"] call FUNC(getList), true];

if (hasInterface) then {
    [{
        {
        diag_log format ["Adding eventhandler init for %1",_x];
        [_x, "Init", {
            params ["_unit"];
            diag_log format ["eventhandler init called %1",_unit];
            _unit addAction [
                "[S-J] OVRD", 
                {
                    params ["_target", "_caller", "_actionId", "_arguments"];
                    _target call FUNC(startJamming);
                }, 
                [], 6, false, false, "", 
                "(_this in _target) && !(_target getVariable [""kolmiJAM_jam_EwsActive"", false])"
            ];
            _unit addAction [
                "[DAS] OPR", 
                {
                    params ["_target", "_caller", "_actionId", "_arguments"];
                    _target call FUNC(startDas);
                }, 
                [], 6, false, false, "", 
                "(_this in _target) && !(_target getVariable [""kolmiJAM_jam_DasActive"", false])"
            ];
            _unit addAction [
                "[DAS] OFF", 
                {
                    params ["_target", "_caller", "_actionId", "_arguments"];
                    _target call FUNC(stopDas);
                }, 
                [], 6, false, false, "", 
                "(_this in _target) && (_target getVariable [""kolmiJAM_jam_DasActive"", false])"
            ];
            _unit addAction [
                "[DECM] AUTO", 
                {
                    params ["_target", "_caller", "_actionId", "_arguments"];
                    _target call FUNC(startDecm);
                }, 
                [], 6, false, false, "", 
                "(_this in _target) && !(_target getVariable [""kolmiJAM_jam_DecmActive"", false])"
            ];
            _unit addAction [
                "[DECM] STBY", 
                {
                    params ["_target", "_caller", "_actionId", "_arguments"];
                    _target call FUNC(stopDecm);
                }, 
                [], 6, false, false, "", 
                "(_this in _target) && (_target getVariable [""kolmiJAM_jam_DecmActive"", false])"
            ];
        }, false, [], true] call CBA_fnc_addClassEventHandler;
    } forEach GVAR(ewsPlanesList);
    }, []] call CBA_fnc_execNextFrame;

};

[QGVAR(disableSensorEvent), {
    params ["_unit", "_componentName"];
    if (local _unit) then {
        _unit enableVehicleSensor [_componentName, false];
    };
}] call CBA_fnc_addEventHandler;

[QGVAR(restoreSensorEvent), {
    params ["_unit", "_componentName"];
    if (local _unit) then {
        _unit enableVehicleSensor [_componentName, true];
    };
}] call CBA_fnc_addEventHandler;
