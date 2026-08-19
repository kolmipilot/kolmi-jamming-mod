
class RscStructuredText;

class RscTitles {
    
    class kolmiJAM_RscHint {
        idd = -1;
        onLoad = "uiNamespace setVariable ['kolmiJAM_ctrlHint', (_this select 0) displayCtrl 1];";
        movingEnable = 0;
        duration = 10e10;
        fadeIn = 0;
        fadeOut = 1;
        name = "kolmiJAM_RscHint";

        class controls {
            class HintBox: RscStructuredText {
                idc = 1;
                text = "";
                //size = "1 / 40 / (getResolution select 5)";
                SizeEx = "(((((safeZoneW / safeZoneH) min 1.2) / 1.2) / 25) * 1)";
                colorText[] = {1, 1, 1, 1};
                colorBackground[] = {0, 0, 0, 0.5};
                x = "safeZoneW + safeZoneX - 0 * safeZoneW";  //safeZoneW + safeZoneX - 0.2 * safeZoneW;
                y = "safeZoneY + 0.2 * safeZoneH";
                w = "0.2 * safeZoneW";
                h = "0.1 * SafeZoneH";
                font = "RobotoCondensed";
            };
        };
    };

};
