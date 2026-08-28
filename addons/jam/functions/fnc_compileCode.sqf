#include "..\script_component.hpp"
/*
* Author: kolmipilot
* This cant be called manualy!
*
*
* Arguments:
* 0: string
*
* Return Value:
* Code
*
* Example:
* [backpack player, "Cfgweapons"] call kolmiJAM_jam_fnc_compileCOde;
*
* Public: No
*/
params ["_str"];

private _code = compile _str;

_code
