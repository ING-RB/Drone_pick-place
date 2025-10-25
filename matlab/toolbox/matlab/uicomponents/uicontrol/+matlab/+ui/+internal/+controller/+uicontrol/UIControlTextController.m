classdef UIControlTextController < matlab.ui.internal.controller.uicontrol.UIControlController
    % UIControlTextController Web-based controller for uicontrol text.

    %   Copyright 2023 The MathWorks, Inc.
    methods( Access = 'protected' )
        function defineViewProperties( obj )
            defineViewProperties@matlab.ui.internal.controller.uicontrol.UIControlController(obj);
            obj.PropertyManagementService.defineViewProperty('HorizontalAlignment');

            % Maps to Text naively
            obj.PropertyManagementService.defineViewProperty('String');
        end

        function definePropertyDependencies( obj )
            definePropertyDependencies@matlab.ui.internal.controller.uicontrol.UIControlController(obj);
            obj.PropertyManagementService.definePropertyDependency("String", "Text");
        end

        function defineRequireUpdateProperties( obj )
            defineRequireUpdateProperties@matlab.ui.internal.controller.uicontrol.UIControlController(obj);
        end
    end

    methods
        function className = getViewModelType(~, ~)
            className = 'matlab.ui.control.UIControlLabel';
        end
        function val = updateText(obj)
            val = obj.Model.String;
        end
    end
end
