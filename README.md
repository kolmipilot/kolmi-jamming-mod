# kolmipilot's Jamming Mod

Electronic warfare mod for Arma 3 planes. Once installed it adds a self-contained defensive suite to supported aircraft: missile warning (DAS), countermeasures against radar-homing missiles (DECM) and a sensor jamming mode (S-J) that blinds hostile radar in a wide area.

## Features

| System | What it does |
| --- | --- |
| **DAS – Directional Alert System** | Detects incoming missiles, identifies the seeker type (IR / ARH / Laser), shows distance + bearing and triangulates the launch site on the map. |
| **DECM – Defensive Electronic Countermeasures** | Targets **radar-homing (ARH) missiles only**. Tries to jam them based on the configurable chance/interval; a jammed missile is destroyed. Non-radar (IR/laser) missiles are reported as "drop countermeasures" instead. |
| **S-J – Sensor Jamming** | Large-radius area jam. Every X seconds it shuts down the active radar sensors of all hostile vehicles in range, then restores them after the jam duration. |

All three systems stop automatically when the aircraft or pilot dies, and active missile tracks are shown on a small on-screen EW panel (red = tracked, orange = jamming, green = jammed / dodged).

## Adding planes

Supported planes are chosen in the CBA settings:

> `kolmiJAM` → **EWS Planes** (EDITBOX)

Enter class names separated by commas, e.g. `'Peral_F35B','B_Plane_Fighter_01_F'`.
Only classes that exist in `CfgVehicles` are kept, so there is no need to worry about typos - invalid entries are simply ignored.

Once a supported plane spawns, use the **`[EWS] Enable`** scroll-wheel action to turn on the defensive suite.

## Per-plane configuration (Eden Editor)

You can also configure EWS settings individually for specific aircraft classes directly in Eden Editor.

Select an aircraft and open its attributes under **kolmiJAM Attributes**. You can:

- Enable or disable EWS for that aircraft class.
- Set a custom ECM range.
- Set a custom ECM active time.
- Set a custom ECM cooldown time.

**Per-plane settings override the global CBA settings** for that aircraft class. If a plane has no individual configuration, it falls back to the current global CBA values.

This allows different aircraft classes to use different ECM ranges, active times and cooldowns without changing the global configuration for other planes.

## Tuning (CBA settings)

| Setting | Effect |
| --- | --- |
| ECM range in m | Default radius of the sensor jamming area. |
| ECM time in s | Default duration of sensor jamming. |
| ECM cool time in s | Default cooldown before the jammer can be used again. |
| DECM missile jamming chance | % chance each attempt destroys an ARH missile. |
| DECM missile jamming interval in s | How often DECM retries on a missile. |
| S-J jamming interval in s | How often the area jam re-scans and blinds hostiles. |
| DAS auto flare | Enable/disable automatic countermeasure drop on missile detection. |

## Custom auto flaring for any plane

The automatic flare drop is **not hard-coded to one aircraft**. By default DAS runs this code when a missile is detected:

```sqf
params ['_plane'];
[_plane, 'Peral_F35B_CM_Launcher'] call BIS_fnc_fire;
```

The `Peral_F35B_CM_Launcher` magazine is specific to the Peral F-35B, so on other aircraft the default flare may not exist. The auto flare code is a **CBA EDITBOX setting** (`kolmiJAM` → **Auto flare code**); if you know SQF you can replace it with anything you want, for example:

```sqf
// vanilla aircraft - fires one flare from the built-in countermeasure system
params ['_plane'];
_plane fire "CMFlareLauncher";
```

Any SQF code that accepts `params ['_plane']` (the object under fire) works, so a missions/addon maker can adapt flaring to any plane, add chaff, play a sound, or run a fully custom scripted routine. If you ever see a script error, check that your code still begins with `params ['_plane'];`.

## Function reference

Only functions intended for third-party use are listed; internal helpers are excluded.

| Function | Description |
| --- | --- |
| `kolmiJAM_jam_fnc_startDas` | `[plane] call ...` – begin missile detection / tracking (DAS). |
| `kolmiJAM_jam_fnc_stopDas` | `[plane] call ...` – stop DAS and remove all trackers/markers. |
| `kolmiJAM_jam_fnc_startDecm` | `[plane] call ...` – enable DECM against radar-homing missiles. |
| `kolmiJAM_jam_fnc_stopDecm` | `[plane] call ...` – disable DECM and clean up its handlers. |
| `kolmiJAM_jam_fnc_startJamming` | `[plane] call ...` – start the area radar sensor jammer (S-J). |
| `kolmiJAM_jam_fnc_stopJamming` | `[plane, hostiles, cooldown] call ...` – restore sensors and end the jam. |
| `kolmiJAM_jam_fnc_UI` | `[player] call ...` – show/keep alive the EW threat panel. |
| `kolmiJAM_jam_fnc_getList` | `["'Class1','Class2'", "CfgVehicles"] call ...` – return only existing config classes from a CSV string. |

## Requirements

- Arma 3
- CBA_A3
- ACE (used for missile seeker metadata) – recommended, not strictly required
