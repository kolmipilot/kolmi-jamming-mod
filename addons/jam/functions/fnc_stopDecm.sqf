#include "..\script_component.hpp"

/*
 * Author: kolmipilot
 *
 * Disables Decm on the plane:
 *   - stops every per-missile tracker (PFHs stored in QGVAR(DasPfhs))
 *   - removes the "IncomingMissile" event handler added in fnc_startDas
 *   - deletes the local "LaunchSite_" markers (createMarkerLocal)
 *
 * Arguments:
 * 0: Plane <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [plane] call kolmiJAM_jam_fnc_stopDecm
 */
params ["_plane"];

// 1) stop all per-missile trackers
private _pfhs = _plane getVariable [QGVAR(DecmPfhs), []];
{
    [_x] call CBA_fnc_removePerFrameHandler;
} forEach _pfhs;
_plane setVariable [QGVAR(DecmPfhs), [], true];

// 2) remove the IncomingMissile event handler
private _handlerId = _plane getVariable [QGVAR(DecmId), -1];
if (_handlerId >= 0 && {!isNull _plane}) then {
    _plane removeEventHandler ["IncomingMissile", _handlerId];
    _plane setVariable [QGVAR(DecmId), -1, true];
};


_plane setVariable [QGVAR(DecmActive), false, true];
