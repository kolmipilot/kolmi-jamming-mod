#include "..\script_component.hpp"
/*
 * Author: kolmipilot
 * Description: Sets if the plane class has EWS.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Has EWS <BOOL> (Default: true)
 *
 * Return Value:
 * None
 *
 * Public: Yes
 */

params [
    ["_unit", objNull, [objNull]],
    ["_hasEWS", true, [true]]
];

TRACE_2("setEWS called",_unit,_hasEWS);

if (!isServer) exitWith {
    TRACE_1("setEWS aborted: not server",_unit);
};

if (isNull _unit) exitWith {
    TRACE_1("setEWS aborted: null unit",_unit);
};

private _unitClass = typeOf _unit;
private _ewsUnits = missionNamespace getVariable [QGVAR(ewsUnits), []];

TRACE_2("setEWS current data",_unitClass,_ewsUnits);

private _index = _ewsUnits findIf {(_x select 0) isEqualTo _unitClass};

TRACE_2("setEWS search result",_unitClass,_index);

if (_hasEWS) then {
    if (_index isEqualTo -1) then {
        _ewsUnits pushBack [_unitClass, GVAR(EcmRange)];
        TRACE_2("setEWS added plane",_unitClass,GVAR(EcmRange));
    } else {
        TRACE_1("setEWS plane already exists",_unitClass);
    };
} else {
    if (_index != -1) then {
        _ewsUnits deleteAt _index;
        TRACE_1("setEWS removed plane",_unitClass);
    } else {
        TRACE_1("setEWS plane not found for removal",_unitClass);
    };
};

missionNamespace setVariable [QGVAR(ewsUnits), _ewsUnits];

TRACE_1("setEWS final data",_ewsUnits);
