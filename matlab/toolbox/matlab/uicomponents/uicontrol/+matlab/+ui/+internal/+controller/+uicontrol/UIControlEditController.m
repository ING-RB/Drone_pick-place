
classdef UIControlEditController < matlab.ui.internal.controller.uicontrol.UIControlController
    % UIControlEditController Web-based controller for uicontrol edit.

    %   Copyright 2023 The MathWorks, Inc.

    methods( Access = 'protected' )
        function defineViewProperties( obj )
            defineViewProperties@matlab.ui.internal.controller.uicontrol.UIControlController(obj);
            obj.PropertyManagementService.defineViewProperty('HorizontalAlignment');

            % Maps to Value
            obj.PropertyManagementService.defineViewProperty('String');

            % Maps to Multiline
            obj.PropertyManagementService.defineViewProperty('Min');
            obj.PropertyManagementService.defineViewProperty('Max');
        end

        function definePropertyDependencies( obj )
            definePropertyDependencies@matlab.ui.internal.controller.uicontrol.UIControlController(obj);
            obj.PropertyManagementService.definePropertyDependency("String", "Value");

            obj.PropertyManagementService.definePropertyDependency("Min", "Multiline");
            obj.PropertyManagementService.definePropertyDependency("Max", "Multiline");
        end

        function defineRequireUpdateProperties( obj )
            defineRequireUpdateProperties@matlab.ui.internal.controller.uicontrol.UIControlController(obj);
        end

        function handleEvent(obj, src, event)
            handleEvent@matlab.ui.internal.controller.uicontrol.UIControlController(obj, src, event);
            switch event.Data.Name
                case 'ValueChanged'
                    obj.processStringChanged(event);
                    obj.triggerActionEvent();
            end
        end

    end

    methods

        function val = fallbackDefaultBackgroundColor ( ~ )
            val = [1,1,1];
        end
        
        function className = getViewModelType(obj, ~)
            % Depends on min and max.
            if obj.Model.Max - obj.Model.Min <= 1
                % This is a single line thing
                className = 'matlab.ui.control.UIControlEditField';
            else
                % This supports multiline.
                className = 'matlab.ui.control.UIControlTextArea';
            end
        end
        function val = updateValue(obj)
            import matlab.ui.internal.controller.uicontrol.UIControlConversionRules.convertStringToValue;
            val = convertStringToValue(obj.Model.String, ...
                obj.Model.Min, ...
                obj.Model.Max);
        end

        function val = updateMultiline(obj)
            import matlab.ui.internal.controller.uicontrol.UIControlConversionRules.convertMinMaxToMultiline;
            val = convertMinMaxToMultiline(obj.Model.Min, ...
                obj.Model.Max);
        end
    end
end
