
[
    QGVAR(ewsPlanes),
    "EDITBOX",
    [LLSTRING(SETTING_EWS_PLANES), LLSTRING(SETTING_EWS_PLANES_DISC)],
    CBA_SETTINGS_CAT,
    "'Peral_F35B'",
    1,
    {
        // Cache the parsed list; GVAR(ewsPlanes) itself stays the raw CBA setting string
        missionNamespace setVariable [QGVAR(ewsPlanesList), [_this, "CfgVehicles"] call FUNC(getList), true];
    },
    true
] call CBA_fnc_addSetting;

[
    QGVAR(EcmRange),
    "SLIDER",
    ["Ecm range in m", "ECM range in meters"],
    CBA_SETTINGS_CAT,
    [0, 20000, 5000, 0],
    1
] call CBA_fnc_addSetting;

[
    QGVAR(EcmTime),
    "SLIDER",
    ["Ecm time in s", "ECM working time in s"],
    CBA_SETTINGS_CAT,
    [0, 600, 60, 0],
    1
] call CBA_fnc_addSetting;

[
    QGVAR(EcmCoolTime),
    "SLIDER",
    ["Ecm cool time in", "ECM cool time in s"],
    CBA_SETTINGS_CAT,
    [0, 1000, 90, 0],
    1
] call CBA_fnc_addSetting;

[
    QGVAR(MissleJammingChance),
    "SLIDER",
    ["DECM missle jamming chance", "DECM missle jamming chance"],
    CBA_SETTINGS_CAT,
    [0, 100, 30, 0],
    1
] call CBA_fnc_addSetting;

[
    QGVAR(MissleJammingInterval),
    "SLIDER",
    ["DECM missle jamming Interval in s", "DECM missle jamming Interval in s"],
    CBA_SETTINGS_CAT,
    [0, 60, 2, 0],
    1
] call CBA_fnc_addSetting;