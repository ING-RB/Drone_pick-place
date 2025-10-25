classdef UicontrolCallbackEventData < event.EventData
    %
    
    % Copyright 2019 The MathWorks, Inc.

    properties (SetAccess = private, GetAccess = public)
        PropertyName
        PropertyValue
        HasData = false;

        % The original callback event that was created when the
        % UIComponent's callback was fired.
        OriginalEvent
    end
    
    methods
        function obj = UicontrolCallbackEventData(originalEvent, propertyName, propertyValue)
            obj.OriginalEvent = originalEvent;
            if nargin == 1
                obj.HasData = false;
            else
                obj.PropertyValue = propertyValue;
                obj.PropertyName = propertyName;
                obj.HasData = true;
            end
        end
    end
end