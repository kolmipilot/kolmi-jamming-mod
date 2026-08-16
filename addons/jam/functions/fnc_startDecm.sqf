#include "..\script_component.hpp"

params ["_plane"];

_plane setVariable [QGVAR(DecmActive), true, true];

// Handles of the per-missile polling loops, so stopDas can clean them up
_plane setVariable [QGVAR(DecmPfhs), [], true];

// Catch every missile fired on the plane. Engine event params:
// _this = [target, ammo, vehicle, instigator, missile]
private _id = [_plane, "IncomingMissile", {
    params ["_target", "_ammo", "_vehicle", "_instigator", "_missile"];

    private _plane = _thisArgs;
    private _shooter = _vehicle;
    if (isNull _shooter) then {
        _shooter = _instigator;
    };
    private _pfh = [{
        params ["_args", "_handle"];
        _args params ["_target", "_missile", "_shooter", "_seeker"];

        // Stop tracking once the missile is gone
        if (isNull _target || isNull _missile || !alive _missile) exitWith {
            [_handle] call CBA_fnc_removePerFrameHandler;
        };

        if (random 100 > 100-GVAR(MissleJammingChance)) then {
            deleteVehicle _missile;
            systemChat "Incoming Missile Jammed";
        } else {
            systemChat "Jamming failed, drop countermeasures"
        }

    }, GVAR(MissleJammingInterval), [_target, _missile, _shooter, "Unknown"]] call CBA_fnc_addPerFrameHandler;

    _plane setVariable [QGVAR(DecmPfhs), (_plane getVariable [QGVAR(DecmPfhs), []]) + [_pfh], true];
}, _plane] call CBA_fnc_addBISEventHandler;

_plane setVariable [QGVAR(DecmId), _id, true];
