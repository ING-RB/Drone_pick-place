classdef PropertyChangedEventData < event.EventData
    properties
        PropertyName
    end
    
    methods
        function this = PropertyChangedEventData(propName)
            this.PropertyName = propName;
        end

        function tag = getFullTag(this)
            src = this.Source;
            tag = sprintf('%s.%s.%s', src.Tab.Tag, src.Tag, this.PropertyName);
        end
    end
end

% [EOF]
