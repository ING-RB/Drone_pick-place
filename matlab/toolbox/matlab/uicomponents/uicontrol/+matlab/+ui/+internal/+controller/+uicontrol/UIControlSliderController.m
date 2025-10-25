classdef UIControlSliderController < matlab.ui.internal.controller.uicontrol.UIControlController
    % UIControlSliderController Web-based controller for uicontrol-slider.

    %   Copyright 2023 The MathWorks, Inc.
    methods( Access = 'protected' )


        function defineViewProperties( obj )
            defineViewProperties@matlab.ui.internal.controller.uicontrol.UIControlController(obj);

            obj.PropertyManagementService.defineViewProperty("SliderStep");
            obj.PropertyManagementService.defineViewProperty("Value");

            % Determines Limits
            obj.PropertyManagementService.defineViewProperty('Max');
            obj.PropertyManagementService.defineViewProperty('Min');
        end

        function definePropertyDependencies( obj )
            definePropertyDependencies@matlab.ui.internal.controller.uicontrol.UIControlController(obj);
            obj.PropertyManagementService.definePropertyDependency("Max", "Limits");
            obj.PropertyManagementService.definePropertyDependency("Min", "Limits");

            obj.PropertyManagementService.definePropertyDependency("SliderStep", "Step");
        end

        function defineRequireUpdateProperties( obj )
            defineRequireUpdateProperties@matlab.ui.internal.controller.uicontrol.UIControlController(obj);
        end

        function handleEvent(obj, src, event)
            handleEvent@matlab.ui.internal.controller.uicontrol.UIControlController(obj, src, event);
            switch event.Data.Name
                case 'mousedragging'
                    obj.processValueChanged(event);
                    obj.triggerContinuousValueChangeEvent();
                case 'mousedragreleased'
                    obj.processValueChanged(event);
                    obj.triggerActionEvent();
                case 'mouseclicked'
                    obj.processValueChanged(event);
                    obj.triggerActionEvent();
            end
        end
    end

    methods
        function className = getViewModelType(~, ~)
            className = 'matlab.ui.control.internal.ScrollbarSlider';
        end

        function val = updateLimits(obj)
            import matlab.ui.internal.controller.uicontrol.UIControlConversionRules.convertMinMaxToLimits;
            val = convertMinMaxToLimits(obj.Model.Min, obj.Model.Max);
        end

        function val = updateStep(obj)
            val = obj.Model.SliderStep;
        end
    end
end
