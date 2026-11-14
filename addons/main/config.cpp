#include "script_component.hpp"

class CfgPatches {
    class ADDON {
        name = COMPONENT_NAME;
        units[] = {};
        weapons[] = {};
        requiredVersion = REQUIRED_VERSION;
        requiredAddons[] = {"ace_common"};
        author = "kolmipilot";
        authors[] = {"kolmipilot"};
        authorUrl = "https://github.com/kolmipilot/kolmi-jamming-mod";
        VERSION_CONFIG;
    };
};

#include "CfgEventHandlers.hpp"
