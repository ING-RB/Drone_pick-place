% UIControlToggleButtonController Web-based controller for uicontrol togglebutton.
classdef UIControlToggleButtonController < matlab.ui.internal.controller.uicontrol.UIControlController
    %

    %   Copyright 2023 The MathWorks, Inc.
    methods( Access = 'protected' )
        function defineViewProperties( obj )
            defineViewProperties@matlab.ui.internal.controller.uicontrol.UIControlController(obj);

            % Determines Toggle State
            obj.PropertyManagementService.defineViewProperty("Max");
            obj.PropertyManagementService.defineViewProperty("Min");
            obj.PropertyManagementService.defineViewProperty("Value");

            % Maps to Text
            obj.PropertyManagementService.defineViewProperty("String");

            % Maps to IconURL
            obj.PropertyManagementService.defineViewProperty("CData");
        end

        function definePropertyDependencies( obj )
            definePropertyDependencies@matlab.ui.internal.controller.uicontrol.UIControlController(obj);
            obj.PropertyManagementService.definePropertyDependency("Max", "Value");
            obj.PropertyManagementService.definePropertyDependency("Min", "Value");

            obj.PropertyManagementService.definePropertyDependency("String", "Text");
            obj.PropertyManagementService.definePropertyDependency("CData", "IconURL");
        end

        function defineRequireUpdateProperties( obj )
            defineRequireUpdateProperties@matlab.ui.internal.controller.uicontrol.UIControlController(obj);
            obj.PropertyManagementService.defineRequireUpdateProperty("Value");
        end

        function handleEvent(obj, src, event)
            handleEvent@matlab.ui.internal.controller.uicontrol.UIControlController(obj, src, event);
            switch event.Data.Name
                case 'ValueChanged'
                    obj.processValueChanged(event);
                    newValue = obj.Model.Min;
                    if event.Data.Value == 1
                        newValue = obj.Model.Max;
                    end
                    obj.updateValueFromView(newValue);
                    obj.triggerActionEvent();
            end
        end
    end

    methods
        function className = getViewModelType(~, ~)
            className = 'matlab.ui.control.UIControlStateButton';
        end
        function val = updateValue(obj)
            import matlab.ui.internal.controller.uicontrol.UIControlConversionRules.convertMinMaxToValue;
            val = convertMinMaxToValue(obj.Model.Value, obj.Model.Max);
        end

        function val = updateText(obj)
            import matlab.ui.internal.controller.uicontrol.UIControlConversionRules.convertStringToText;
            val = convertStringToText(obj.Model.String);
        end

        function val = updateIconURL(obj)
            import matlab.ui.internal.controller.uicontrol.UIControlConversionRules.convertCData;
            val = convertCData(obj.Model.CData);
        end
    end
end
