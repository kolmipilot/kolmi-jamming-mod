#include "..\script_component.hpp"
/*
 * Author: kolmipilot
 * Description: Sets plane ECM Cool time.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: ECM Cool time <NUMBER> (Default: 90)
 *
 * Return Value:
 * None
 *
 * Example:
 * [player, 90] call kolmiJAM_jam_fnc_setECMCoolTime;
 *
 * Public: Yes
 */

params [
    ["_unit", objNull, [objNull]],
    ["_ecmCoolTime", 90, [0]]
];

if (!isServer || {isNull _unit}) exitWith {};

private _unitClass = typeOf _unit;

private _ewsUnits = missionNamespace getVariable [QGVAR(ewsUnits), []];

private _index = _ewsUnits findIf {(_x select 0) isEqualTo _unitClass};

if (_index != -1) then {
    (_ewsUnits select _index) set [3, _ecmCoolTime];
} else {
    _ewsUnits pushBack [_unitClass, GVAR(EcmRange), GVAR(EcmTime), _ecmCoolTime];
};

missionNamespace setVariable [QGVAR(ewsUnits), _ewsUnits];
