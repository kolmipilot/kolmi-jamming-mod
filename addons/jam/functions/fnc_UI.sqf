#include "..\script_component.hpp"

/*
 * Author: kolmipilot
 *
 * Start UI monitoring PFH for missile tracking
 * Should be called once when UI is needed
 * Arguments:
 * 0: Plane <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [ace_player] call kolmiJAM_jam_fnc_UI
 */
params ["_unit"];
private _plane = vehicle _unit;

// Check if UI PFH is already running - if so, do nothing
if (!isNil {_plane getVariable QGVAR(uiPfhHandle)}) then {
    TRACE_1("UI PFH already running",_plane);
} else {
    // Start the UI monitoring PFH
    private _pfh = [{
        params ["_args", "_handle"];
        _args params ["_plane", "_unit"];

        private _dasArray = _plane getVariable [QGVAR(dasArray), []];
        private _decmArray = _plane getVariable [QGVAR(decmArray), []];

        // Clean up stale missiles from DAS array (in case they weren't removed by DAS PFH yet)
        _dasArray = _dasArray select {!(isNull (_x param [0, objNull])) && {alive (_x param [0, objNull])}};
        _plane setVariable [QGVAR(dasArray), _dasArray, true];

        // Clean up stale entries from DECM array
        _decmArray = _decmArray select {!(isNull (_x param [0, objNull]))};
        _plane setVariable [QGVAR(decmArray), _decmArray, true];

        // Exit if no missiles to display
        if (_dasArray isEqualTo [] && _decmArray isEqualTo []) exitWith {
            TRACE_1("UI PFH stopping - no data",_plane);
            [_handle] call CBA_fnc_removePerFrameHandler;
            _plane setVariable [QGVAR(uiPfhHandle), nil];
        };

        // Only process if player is in this plane
        if (vehicle _unit isNotEqualTo _plane) exitWith {};

        // Build display from DAS data, merge with DECM jam status
        private _rows = [
            parseText "<t align='center'><t color='#ff4d4d'>Electronic Warfare System</t></t><br/>"
        ];
        private _hasJammedRadar = false;

        {
            _x params [
                ["_missile", objNull, [objNull]],
                ["_seeker", "Unknown", [""]],
                ["_distance", 0, [0]],
                ["_dir", 0, [0]]
            ];

            // Skip invalid missiles
            if (!(isNull _missile) && {alive _missile}) then {
                // Find jam status from DECM array
                private _decmEntry = _decmArray findIf {(_x param [0, objNull]) isEqualTo _missile};
                private _jammed = false;
                if (_decmEntry >= 0) then {
                    _jammed = _decmArray select _decmEntry select 1;
                };

                // Color: red if tracked, orange if jammed
                private _color = ["#ff4d4d", "#ff9d00"] select _jammed;
                private _label = ["TRACKED", "JAMMED"] select _jammed;

                // Track if we have jammed radar for warning message
                if (_seeker isEqualTo "ARH" && _jammed) then {
                    _hasJammedRadar = true;
                };

                _rows pushBack (parseText format [
                    "<t color='%1'>[%2] %3 | %4 m | dir %5</t><br/>",
                    _color,
                    _label,
                    _seeker,
                    round _distance,
                    round _dir
                ]);
            };
        } forEach _dasArray;

        // Add warning if we have jammed radar
        if (_hasJammedRadar) then {
            _rows pushBack (parseText "<br/><t color='#ff9d00' size='1.1'>RADAR JAMMED!</t>");
        };

        if (count _rows > 1) then {
            private _msg = composeText _rows;
            [_msg, 5, _unit] call ace_common_fnc_displayTextStructured;
        };
    }, 0.1, [_plane, _unit]] call CBA_fnc_addPerFrameHandler;

    TRACE_2("UI PFH started",_plane,_pfh);
    _plane setVariable [QGVAR(uiPfhHandle), _pfh, true];
};
