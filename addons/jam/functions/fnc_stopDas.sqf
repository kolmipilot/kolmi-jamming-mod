#include "..\script_component.hpp"

/*
 * Author: kolmipilot
 *
 * Disables DAS on the plane:
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
 * [plane] call kolmiJAM_jam_fnc_stopDas
 */
params ["_plane"];

// 1) stop all per-missile trackers
private _pfhs = _plane getVariable [QGVAR(DasPfhs), []];
{
    [_x] call CBA_fnc_removePerFrameHandler;
} forEach _pfhs;
_plane setVariable [QGVAR(DasPfhs), [], true];

// 2) remove the IncomingMissile event handler
private _handlerId = _plane getVariable [QGVAR(DasId), -1];
if (_handlerId >= 0 && {!isNull _plane}) then {
    _plane removeEventHandler ["IncomingMissile", _handlerId];
    _plane setVariable [QGVAR(DasId), -1, true];
};

// 3) clean up the DAS launch markers (local, from createMarkerLocal in fnc_startDas)
private _dasMarkers = allMapMarkers select {(_x find "LaunchSite_") == 0};
{
    deleteMarkerLocal _x;
} forEach _dasMarkers;

_plane setVariable [QGVAR(DasActive), false, true];
