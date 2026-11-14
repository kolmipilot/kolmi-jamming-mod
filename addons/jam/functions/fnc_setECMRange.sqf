#include "..\script_component.hpp"
/*
 * Author: kolmipilot
 * Description: Sets plane ECM range.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: ECM range <NUMBER> (Default: 1000)
 *
 * Return Value:
 * None
 *
 * Example:
 * [player, 1500] call kolmiJAM_jam_fnc_setECMRange;
 *
 * Public: Yes
 */

params [
    ["_unit", objNull, [objNull]],
    ["_ecmRange", 1000, [0]]
];

if (!isServer || {isNull _unit}) exitWith {};

private _unitClass = typeOf _unit;

private _ewsUnits = missionNamespace getVariable [QGVAR(ewsUnits), []];

private _index = _ewsUnits findIf {(_x select 0) isEqualTo _unitClass};

if (_index != -1) then {
    (_ewsUnits select _index) set [1, _ecmRange];
} else {
    _ewsUnits pushBack [_unitClass, _ecmRange, GVAR(EcmTime), GVAR(EcmCoolTime)];
};

missionNamespace setVariable [QGVAR(ewsUnits), _ewsUnits];
