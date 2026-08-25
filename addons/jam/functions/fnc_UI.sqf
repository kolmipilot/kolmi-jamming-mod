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

        // Stop the UI if the plane or pilot is dead
        if (isNull _plane || {!alive _plane} || {!alive _unit}) exitWith {
            [nil, 0, true] call FUNC(displayHint);
            [_handle] call CBA_fnc_removePerFrameHandler;
            _plane setVariable [QGVAR(uiPfhHandle), nil];
        };

        private _dasArray  = _plane getVariable [QGVAR(dasArray),  []];
        private _now = time;

        // Keep resolved entries for HIDE_DELAY so JAMMED/DODGED stays visible.
        // Any dead missile that never got a resolved state is marked DODGED here
        // so it is never dropped as - or shown as - an unresolved TRACKED threat.
        _dasArray = _dasArray select {
            private _missile = _x param [0, objNull];
            private _state = _x param [4, "TRACKING"];
            private _expiry = _x param [5, 0];
            private _live = !(isNull _missile) && {alive _missile};

            if (!_live && {!(_state in ["JAMMED", "DODGED"])}) then {
                _x set [4, "DODGED"];
                _x set [5, _now + HIDE_DELAY];
                _state = "DODGED";
                _expiry = _now + HIDE_DELAY;
            };

            _live || {_state in ["JAMMED", "DODGED"] && {_now < _expiry}}
        };
        _plane setVariable [QGVAR(dasArray), _dasArray, true];

        // Only process UI if player is still in this plane
        if (vehicle _unit isNotEqualTo _plane) exitWith {};

        // ---- Build missile rows ----
        private _rows         = [];
        private _activeMissiles   = 0; // live + undecided (Tracked / Jamming)
        private _resolvedMissiles = 0; // jammed or dodged, still within expiry

        {
            _x params [
                ["_missile", objNull, [objNull]],
                ["_seeker",  "Unknown", [""]],
                ["_distance", 0, [0]],
                ["_dir",      0, [0]]
            ];

            private _state = _x param [4, "TRACKING"];
            private _isLive = !(isNull _missile) && {alive _missile};

            // If the missile is already gone but the resolved state never got
            // written (edge timing), never show it as TRACKED - treat as DODGED.
            if (!_isLive && {!(_state in ["JAMMED", "DODGED", "JAMMING"])}) then {
                _state = "DODGED";
            };

            private _isResolved = _state in ["JAMMED", "DODGED"];

            // _activeMissiles counts ONLY live undecided threats. Resolved
            // JAMMED/DODGED are counted separately so they stay visible during
            // their expiry window instead of flipping the title straight to THREAT CLEAR.
            if (_isLive) then { _activeMissiles = _activeMissiles + 1; };
            if (_isResolved) then { _resolvedMissiles = _resolvedMissiles + 1; };

            if (_isResolved || _isLive) then {
                private _color = switch _state do {
                    case "JAMMING": {"#ff9d00"};
                    case "JAMMED": {"#00cc44"};
                    case "DODGED": {"#00cc44"};
                    default {"#ff4d4d"};
                };
                private _label = switch _state do {
                    case "JAMMING": {"JAMMING"};
                    case "JAMMED": {"JAMMED"};
                    case "DODGED": {"DODGED"};
                    default {"TRACKED"};
                };

                _rows pushBack (parseText format [
                    "<t color='%1'>[%2] %3 | %4 m | dir %5</t><br/>",
                    _color, _label, _seeker, round _distance, round _dir
                ]);
                TRACE_1("UI rows",_rows);
            };
        } forEach _dasArray;

        // Only undecided (live) threats keep the grace-period clock alive.
        if (_activeMissiles > 0) then {
            _args set [2, time];
            _lastThreatTime = time;
        };

        private _timeSinceThreat = time - _lastThreatTime;

        // Exit only when EVERYTHING is gone - including resolved-but-visible rows.
        if (_activeMissiles == 0 && {_resolvedMissiles == 0} && {_timeSinceThreat >= HIDE_DELAY}) exitWith {
            TRACE_1("UI PFH stopping - threats cleared",_plane);
            [nil, 0, true] call FUNC(displayHint);
            [_handle] call CBA_fnc_removePerFrameHandler;
            _plane setVariable [QGVAR(uiPfhHandle), nil];
        };

        // ---- Build full display ----
        // No "THREAT CLEAR" screen: once a missile is resolved you keep seeing
        // its [JAMMED] / [DODGED] row under the "THREAT RESOLVED" header for the
        // full HIDE_DELAY. Only an empty title is shown in the trailing grace.
        private _titleRow = if (_activeMissiles > 0) then {
            parseText "<t align='center'><t color='#ff4d4d'>Electronic Warfare System</t></t><br/>"
        } else {
            if (_resolvedMissiles > 0) then {
                parseText "<t align='center'><t color='#00cc44'>THREAT RESOLVED</t></t><br/>"
            } else {
                parseText ""
            };
        };

        private _allRows  = [_titleRow] + _rows;
        private _msg      = composeText _allRows;

        [_msg, count _allRows] call FUNC(displayHint);

    }, 0.1, [_plane, _unit, time]] call CBA_fnc_addPerFrameHandler;

    TRACE_2("UI PFH started",_plane,_pfh);
    _plane setVariable [QGVAR(uiPfhHandle), _pfh, true];
};

