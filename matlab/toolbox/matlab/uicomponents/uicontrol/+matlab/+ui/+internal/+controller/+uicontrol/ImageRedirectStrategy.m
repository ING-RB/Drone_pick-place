classdef ImageRedirectStrategy < matlab.ui.internal.controller.uicontrol.UicontrolRedirectStrategy
	%

	% Copyright 2020 The MathWorks, Inc.

    properties (Access = private)
        UicontrolModel
    end

    methods
        function handleCallbackFired(obj, src, event)
            newEvent = obj.translateEvent(src, event);
            notify(obj, 'CallbackFired', newEvent);
            executeCallback(obj, src, event);
        end

        function shouldChange = isNewUIComponentNeeded(obj, uicontrolModel, propName, uicomponent)
            if isa(uicomponent, 'matlab.ui.control.Image') ...
                    && ~isempty(uicontrolModel.CData) ...
                    && any(strcmp(uicontrolModel.Style, {'radiobutton', 'checkbox'}))
                % If style is radiobutton or checkbox, and CData is set,
                % the image component can be reused.  In that case override
                % the superclass behavior.
                shouldChange = false;
                return;
            end

            shouldChange = isNewUIComponentNeeded@matlab.ui.internal.controller.uicontrol.UicontrolRedirectStrategy(obj, uicontrolModel, propName, uicomponent);

            shouldChange = shouldChange || isempty(uicontrolModel.CData);
        end

        function creationFcn = getComponentCreationFunction(obj, uicontrolModel)
            creationFcn = @uiimage;
        end
    end

    methods (Access = protected)
        function component = postCreateUIComponent(obj, component, uicontrolModel)
            obj.UicontrolModel = uicontrolModel;
            component.ImageClickedFcn = @obj.handleCallbackFired;
        end
    end

    methods (Access = private)
        function newEvent = translateEvent(obj, ~, event)
            % Determine if the value should be flipped from Max to Min or
            % vice versa depending on the current value of the uicontrol
            % model.  The uicontrol model has yet to be updated at this
            % point.
            if obj.UicontrolModel.Value == obj.UicontrolModel.Min
                value = obj.UicontrolModel.Max;
            else
                value = obj.UicontrolModel.Min;
            end

            newEvent = matlab.ui.internal.controller.uicontrol.UicontrolCallbackEventData(event, 'Value', value);
        end
    end
end
