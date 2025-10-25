classdef UIControlPushButtonController < matlab.ui.internal.controller.uicontrol.UIControlController
    % UIControlPushButtonController Web-based controller for uicontrol pushbutton.
    %   Copyright 2023 The MathWorks, Inc.
    methods( Access = 'protected' )
        function defineViewProperties( obj )
            defineViewProperties@matlab.ui.internal.controller.uicontrol.UIControlController(obj);

            % Maps to Text
            obj.PropertyManagementService.defineViewProperty('String');

            % Maps to IconURL
            obj.PropertyManagementService.defineViewProperty("CData");
            obj.PropertyManagementService.definePropertyDependency("CData", "IconURL");
        end

        function definePropertyDependencies( obj )
            definePropertyDependencies@matlab.ui.internal.controller.uicontrol.UIControlController(obj);
            obj.PropertyManagementService.definePropertyDependency("String", "Text");
        end

        function defineRequireUpdateProperties( obj )
            defineRequireUpdateProperties@matlab.ui.internal.controller.uicontrol.UIControlController(obj);
        end

        function handleEvent(obj, src, event)
            handleEvent@matlab.ui.internal.controller.uicontrol.UIControlController(obj, src, event);
            switch event.Data.Name
                case 'ButtonPushed'
                    obj.triggerActionEvent();
            end
        end
    end

    methods
        function className = getViewModelType(~, ~)
            className = 'matlab.ui.control.UIControlButton';
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
