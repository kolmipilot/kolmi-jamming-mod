class Cfg3DEN {
    class Attributes {
    class Slider;

        // ECM Range: 0-20000, default 5000
        class GVAR(ecmRangeSlider): Slider {
            attributeLoad = "params [""_ctrlGroup""];\
                private _slider = _ctrlGroup controlsGroupCtrl 100;\
                private _edit = _ctrlGroup controlsGroupCtrl 101;\
                _slider sliderSetPosition _value;\
                _edit ctrlSetText ([_value, 1, 0] call CBA_fnc_formatNumber);";

            attributeSave = "params [""_ctrlGroup""];\
                sliderPosition (_ctrlGroup controlsGroupCtrl 100);";

            onLoad = "params [""_ctrlGroup""];\
                private _slider = _ctrlGroup controlsGroupCtrl 100;\
                private _edit = _ctrlGroup controlsGroupCtrl 101;\
                _slider sliderSetRange [0, 20000];\
                _slider ctrlAddEventHandler [""SliderPosChanged"", {\
                    params [""_slider""];\
                    private _edit = (ctrlParentControlsGroup _slider) controlsGroupCtrl 101;\
                    private _value = sliderPosition _slider;\
                    _edit ctrlSetText ([_value, 1, 0] call CBA_fnc_formatNumber);\
                }];\
                _edit ctrlAddEventHandler [""KillFocus"", {\
                    params [""_edit""];\
                    private _slider = (ctrlParentControlsGroup _edit) controlsGroupCtrl 100;\
                    private _value = ((parseNumber ctrlText _edit) min 20000) max 0;\
                    _slider sliderSetPosition _value;\
                    _edit ctrlSetText ([_value, 1, 0] call CBA_fnc_formatNumber);\
                }];";
        };

        // ECM Time: 0-600, default 60
        class GVAR(ecmTimeSlider): Slider {
            attributeLoad = "params [""_ctrlGroup""];\
                private _slider = _ctrlGroup controlsGroupCtrl 100;\
                private _edit = _ctrlGroup controlsGroupCtrl 101;\
                _slider sliderSetPosition _value;\
                _edit ctrlSetText ([_value, 1, 0] call CBA_fnc_formatNumber);";

            attributeSave = "params [""_ctrlGroup""];\
                sliderPosition (_ctrlGroup controlsGroupCtrl 100);";

            onLoad = "params [""_ctrlGroup""];\
                private _slider = _ctrlGroup controlsGroupCtrl 100;\
                private _edit = _ctrlGroup controlsGroupCtrl 101;\
                _slider sliderSetRange [0, 600];\
                _slider ctrlAddEventHandler [""SliderPosChanged"", {\
                    params [""_slider""];\
                    private _edit = (ctrlParentControlsGroup _slider) controlsGroupCtrl 101;\
                    private _value = sliderPosition _slider;\
                    _edit ctrlSetText ([_value, 1, 0] call CBA_fnc_formatNumber);\
                }];\
                _edit ctrlAddEventHandler [""KillFocus"", {\
                    params [""_edit""];\
                    private _slider = (ctrlParentControlsGroup _edit) controlsGroupCtrl 100;\
                    private _value = ((parseNumber ctrlText _edit) min 600) max 0;\
                    _slider sliderSetPosition _value;\
                    _edit ctrlSetText ([_value, 1, 0] call CBA_fnc_formatNumber);\
                }];";
        };

        // ECM CoolTime: 0-1000, default 90
        class GVAR(ecmCoolTimeSlider): Slider {
            attributeLoad = "params [""_ctrlGroup""];\
                private _slider = _ctrlGroup controlsGroupCtrl 100;\
                private _edit = _ctrlGroup controlsGroupCtrl 101;\
                _slider sliderSetPosition _value;\
                _edit ctrlSetText ([_value, 1, 0] call CBA_fnc_formatNumber);";

            attributeSave = "params [""_ctrlGroup""];\
                sliderPosition (_ctrlGroup controlsGroupCtrl 100);";

            onLoad = "params [""_ctrlGroup""];\
                private _slider = _ctrlGroup controlsGroupCtrl 100;\
                private _edit = _ctrlGroup controlsGroupCtrl 101;\
                _slider sliderSetRange [0, 1000];\
                _slider ctrlAddEventHandler [""SliderPosChanged"", {\
                    params [""_slider""];\
                    private _edit = (ctrlParentControlsGroup _slider) controlsGroupCtrl 101;\
                    private _value = sliderPosition _slider;\
                    _edit ctrlSetText ([_value, 1, 0] call CBA_fnc_formatNumber);\
                }];\
                _edit ctrlAddEventHandler [""KillFocus"", {\
                    params [""_edit""];\
                    private _slider = (ctrlParentControlsGroup _edit) controlsGroupCtrl 100;\
                    private _value = ((parseNumber ctrlText _edit) min 1000) max 0;\
                    _slider sliderSetPosition _value;\
                    _edit ctrlSetText ([_value, 1, 0] call CBA_fnc_formatNumber);\
                }];";
        };
    };

    class Object {
        class AttributeCategories {
            class kolmiJAM_attributes {
                displayName = CSTRING(Eden_AttributeCategory);
                collapsed = 1;

                class Attributes {
                    class kolmiJAM_hasEWS {
                        displayName = CSTRING(Eden_HasEWS_DisplayName);
                        tooltip = CSTRING(Eden_HasEWS_Description);
                        property = "kolmiJAM_hasEWS";
                        control = "Checkbox";
                        expression = QUOTE(if (isServer) then {[ARR_2(_this,_value)] call FUNC(setEWS)});
                        defaultValue = "(false)";
                        condition = "script";
                        conditionScript = "_this isKindOf 'Plane'";
                        typeName = "BOOL";
                    };
                    class kolmiJAM_ecmRange {
                        displayName = CSTRING(Eden_ECMRange_DisplayName);
                        tooltip = CSTRING(Eden_ECMRange_Description);
                        property = "kolmiJAM_ecmRange";
                        control = QGVAR(ecmRangeSlider);
                        expression = QUOTE(if (isServer) then {[ARR_2(_this,_value)] call FUNC(setECMRange)});
                        defaultValue = 5000;
                        condition = "script";
                        conditionScript = "_this isKindOf 'Plane'";
                        typeName = "NUMBER";
                    };

                    class kolmiJAM_ecmTime {
                        displayName = CSTRING(Eden_ECMTime_DisplayName);
                        tooltip = CSTRING(Eden_ECMTime_Description);
                        property = "kolmiJAM_ecmTime";
                        control = QGVAR(ecmTimeSlider);
                        expression = QUOTE(if (isServer) then {[ARR_2(_this,_value)] call FUNC(setECMTime)});
                        defaultValue = 60;
                        condition = "script";
                        conditionScript = "_this isKindOf 'Plane'";
                        typeName = "NUMBER";
                    };

                    class kolmiJAM_ecmCoolTime {
                        displayName = CSTRING(Eden_ECMCoolTime_DisplayName);
                        tooltip = CSTRING(Eden_ECMCoolTime_Description);
                        property = "kolmiJAM_ecmCoolTime";
                        control = QGVAR(ecmCoolTimeSlider);
                        expression = QUOTE(if (isServer) then {[ARR_2(_this,_value)] call FUNC(setECMCoolTime)});
                        defaultValue = 90;
                        condition = "script";
                        conditionScript = "_this isKindOf 'Plane'";
                        typeName = "NUMBER";
                    };
                };
            };
        };
    };
};
