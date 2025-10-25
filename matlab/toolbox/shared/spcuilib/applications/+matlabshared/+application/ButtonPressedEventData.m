classdef ButtonPressedEventData < event.EventData
    properties
        ButtonName
    end
    
    methods
        function this = ButtonPressedEventData(buttonName)
            this.ButtonName = buttonName;
        end
    end
end

% [EOF]
