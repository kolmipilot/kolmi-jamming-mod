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

// Reset unresolved missile display states when jamming is disabled.
private _dasArray = _plane getVariable [QGVAR(dasArray), []];
{
    private _state = _x param [4, "TRACKING"];
    if !(_state in ["JAMMED", "DODGED"]) then {
        _x set [4, "TRACKING"];
        _x set [5, 0];
    };
} forEach _dasArray;
_plane setVariable [QGVAR(dasArray), _dasArray, true];

// 4) stop the UI PFH if it's running
private _uiPfhHandle = _plane getVariable [QGVAR(uiPfhHandle), nil];
if (!isNil "_uiPfhHandle" && {_uiPfhHandle >= 0}) then {
    [_uiPfhHandle] call CBA_fnc_removePerFrameHandler;
    _plane setVariable [QGVAR(uiPfhHandle), nil];
};

_plane setVariable [QGVAR(DecmActive), false, true];
