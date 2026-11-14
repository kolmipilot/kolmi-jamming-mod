#include "..\script_component.hpp"
/*
 * Author: kolmipilot
 * Description: Sets plane ECM time.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: ECM time <NUMBER> (Default: 60)
 *
 * Return Value:
 * None
 *
 * Example:
 * [player, 60] call kolmiJAM_jam_fnc_setECMTime;
 *
 * Public: Yes
 */

params [
    ["_unit", objNull, [objNull]],
    ["_ecmTime", 60, [0]]
];

if (!isServer || {isNull _unit}) exitWith {};

private _unitClass = typeOf _unit;

private _ewsUnits = missionNamespace getVariable [QGVAR(ewsUnits), []];

private _index = _ewsUnits findIf {(_x select 0) isEqualTo _unitClass};

if (_index != -1) then {
    (_ewsUnits select _index) set [2, _ecmTime];
} else {
    _ewsUnits pushBack [_unitClass, GVAR(EcmRange), _ecmTime, GVAR(EcmCoolTime)];
};

missionNamespace setVariable [QGVAR(ewsUnits), _ewsUnits];
