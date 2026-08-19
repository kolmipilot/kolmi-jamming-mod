class CfgUIGrids {
    class IGUI {
        class Presets {
            class Arma3 {
                class Variables {
                    grid_kolmiJAM_displayText[] = {
                        {
                            "((safeZoneX + safeZoneW) - (10 *(((safeZoneW / safeZoneH) min 1.2) / 40)) - 2.9 *(((safeZoneW / safeZoneH) min 1.2) / 40))",
                            "safeZoneY + 0.175 * safeZoneH",
                            "(10 *(((safeZoneW / safeZoneH) min 1.2) / 40))",
                            "(3 *((((safeZoneW / safeZoneH) min 1.2) / 1.2) / 25))"
                        },
                        "(((safeZoneW / safeZoneH) min 1.2) / 40)",
                        "((((safeZoneW / safeZoneH) min 1.2) / 1.2) / 25)"
                    };
                };
            };
        };

        class Variables {
            class grid_kolmiJAM_displayText {
                displayName = "kolmiJAM hint";
                description = "Textual in game feedback to the player.";
                preview = "\a3\Ui_f\data\GUI\Cfg\UIGrids\grid_hint_ca.paa";
                saveToProfile[] = {0,1};
            };
        };
    };
};
