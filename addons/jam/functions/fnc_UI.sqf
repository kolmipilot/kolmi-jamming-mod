#include "..\script_component.hpp"

/*
 * Author: kolmipilot
 *
 * Start UI monitoring PFH for missile tracking
 * Should be called once when UI is needed
 * Arguments:
 * 0: Unit (player) <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [ace_player] call kolmiJAM_jam_fnc_UI
 */
params ["_unit"];
private _plane = vehicle _unit;

// How long (seconds) to keep the hint visible after all threats are gone/jammed
#define HIDE_DELAY 7

// Check if UI PFH is already running - if so, do nothing
if (!isNil {_plane getVariable QGVAR(uiPfhHandle)}) then {
    TRACE_1("UI PFH already running",_plane);
} else {
    // Start the UI monitoring PFH
    private _pfh = [{
        params ["_args", "_handle"];
        _args params ["_plane", "_unit", "_lastThreatTime"];

        private _dasArray  = _plane getVariable [QGVAR(dasArray),  []];
        private _decmArray = _plane getVariable [QGVAR(decmArray), []];

        // Clean up stale missiles from DAS array
        _dasArray = _dasArray select {!(isNull (_x param [0, objNull])) && {alive (_x param [0, objNull])}};
        _plane setVariable [QGVAR(dasArray), _dasArray, true];

        // Clean up stale entries from DECM array
        _decmArray = _decmArray select {!(isNull (_x param [0, objNull]))};
        _plane setVariable [QGVAR(decmArray), _decmArray, true];

        // Only process UI if player is still in this plane
        if (vehicle _unit isNotEqualTo _plane) exitWith {};

        // ---- Build active missile rows ----
        private _rows         = [];
        private _hasJammedRadar = false;
        private _activeMissiles = 0;

        {
            _x params [
                ["_missile", objNull, [objNull]],
                ["_seeker",  "Unknown", [""]],
                ["_distance", 0, [0]],
                ["_dir",      0, [0]]
            ];

            if (!(isNull _missile) && {alive _missile}) then {
                _activeMissiles = _activeMissiles + 1;

                // Look up jam status from DECM array
                private _decmEntry = _decmArray findIf {(_x param [0, objNull]) isEqualTo _missile};
                private _jammed    = false;
                if (_decmEntry >= 0) then {
                    _jammed = _decmArray select _decmEntry select 1;
                };

                // Color: orange if jammed, red if still tracking
                private _color = ["#ff4d4d", "#ff9d00"] select _jammed;
                private _label = ["TRACKED", "JAMMED"]  select _jammed;

                if (_seeker isEqualTo "ARH" && _jammed) then { _hasJammedRadar = true; };

                _rows pushBack (parseText format [
                    "<t color='%1'>[%2] %3 | %4 m | dir %5</t><br/>",
                    _color, _label, _seeker, round _distance, round _dir
                ]);
            };
        } forEach _dasArray;

        // Radar-jam warning row
        if (_hasJammedRadar) then {
            _rows pushBack (parseText "<br/><t color='#ff9d00' size='1.1'>RADAR JAMMED!</t>");
        };

        // ---- Threat timer logic ----
        if (_activeMissiles > 0) then {
            // Threats present – reset the grace-period clock
            _args set [2, time];
            _lastThreatTime = time;
        };

        private _timeSinceThreat = time - _lastThreatTime;

        if (_activeMissiles == 0 && _timeSinceThreat >= HIDE_DELAY) exitWith {
            // Grace period expired – hide hint and stop PFH
            TRACE_1("UI PFH stopping - threats cleared",_plane);
            [nil, 0, true] call FUNC(displayHint);
            [_handle] call CBA_fnc_removePerFrameHandler;
            _plane setVariable [QGVAR(uiPfhHandle), nil];
        };

        // ---- Build full display ----
        // Title row + missile rows (+ optional RADAR JAMMED)
        private _titleRow = if (_activeMissiles > 0) then {
            parseText "<t align='center'><t color='#ff4d4d'>Electronic Warfare System</t></t><br/>"
        } else {
            // All threats gone/jammed – show CLEAR countdown
            private _remaining = round (HIDE_DELAY - _timeSinceThreat);
            parseText format ["<t align='center'><t color='#00cc44'>THREAT CLEAR (%1s)</t></t><br/>", _remaining]
        };

        private _allRows  = [_titleRow] + _rows;
        private _msg      = composeText _allRows;

        [_msg, count _allRows] call FUNC(displayHint);

    }, 0.1, [_plane, _unit, 0]] call CBA_fnc_addPerFrameHandler;

    TRACE_2("UI PFH started",_plane,_pfh);
    _plane setVariable [QGVAR(uiPfhHandle), _pfh, true];
};

