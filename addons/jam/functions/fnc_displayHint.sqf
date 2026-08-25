#include "..\script_component.hpp"
/*
 * Author: kolmipilot
 * Display a structured text hint on the custom kolmiJAM hint control.
 * The text should be composed via composeText before calling this function.
 * Call with _hide = true to fade the hint out without showing anything.
 *
 * Arguments:
 * 0: Structured text to display (result of composeText) <TEXT>   (optional)
 * 1: Number of content rows for dynamic height sizing    <NUMBER> (default: 1)
 * 2: Hide the hint instead of showing it                 <BOOL>   (default: false)
 *
 * Return Value:
 * None
 *
 * Example:
 * [composeText _rows, count _rows] call kolmiJAM_jam_fnc_displayHint
 * [nil, 0, true] call kolmiJAM_jam_fnc_displayHint  // hide
 *
 * Public: Yes
 */

params [
    ["_text",     nil],           // Text type from composeText – no type check possible in SQF
    ["_rowCount", 1,   [0]],
    ["_hide",     false, [false]]
];

// ---- HIDE MODE ---- (no control reference needed)
if (_hide) exitWith {
    ("kolmiJAM_RscHint" call BIS_fnc_rscLayer) cutText ["", "PLAIN", 0];
};

// ---- SHOW MODE ----
// cutRsc MUST come before getVariable:
// HintConfig onLoad = "uiNamespace setVariable ['kolmiJAM_ctrlHint', ...]"
// fires synchronously when the display is created by cutRsc.
("kolmiJAM_RscHint" call BIS_fnc_rscLayer) cutRsc ["kolmiJAM_RscHint", "PLAIN", 0, true];

disableSerialization;
private _ctrlHint = uiNamespace getVariable ["kolmiJAM_ctrlHint", controlNull];

// Guard – should never be null now, but be safe
if (isNull _ctrlHint) exitWith {};

_ctrlHint ctrlSetBackgroundColor GVAR(displayTextColor);
_ctrlHint ctrlSetTextColor GVAR(displayTextFontColor);

// --- Position / size ---
// Match SizeEx from HintConfig: (((safeZoneW/safeZoneH) min 1.2)/1.2)/25
private _lineH = (((safeZoneW / safeZoneH) min 1.2) / 1.2) / 25;
private _width = 10;
private _wPos  = _width * (((safeZoneW / safeZoneH) min 1.2) / 40);

// Height scales with row count; structured text needs extra room for line spacing
private _hPos = ((_rowCount + 1) * _lineH * 1.8) max (3 * _lineH);

// Use profile-saved position (supports drag-to-move via CfgUIGrids)
private _xPos = profileNamespace getVariable [
    "IGUI_GRID_kolmiJAM_displayText_X",
    (safeZoneX + safeZoneW) - _wPos - (2.9 * (((safeZoneW / safeZoneH) min 1.2) / 40))
];
private _yPos = profileNamespace getVariable [
    "IGUI_GRID_kolmiJAM_displayText_Y",
    safeZoneY + 0.175 * safeZoneH
];

// Clamp to screen bounds
_xPos = safeZoneX max (_xPos min (safeZoneX + safeZoneW - _wPos));
_yPos = safeZoneY max (_yPos min (safeZoneY + safeZoneH - _hPos));

// Shift left when Zeus UI is open so it doesn't overlap the CREATE list
if (!isNull curatorCamera) then {
    _xPos = _xPos min ((safeZoneX + safeZoneW - 12.5 * (((safeZoneW / safeZoneH) min 1.2) / 40)) - _wPos);
};

private _position = [_xPos, _yPos, _wPos, _hPos];

_ctrlHint ctrlSetStructuredText _text;
_ctrlHint ctrlSetPosition _position;
_ctrlHint ctrlCommit 0;


