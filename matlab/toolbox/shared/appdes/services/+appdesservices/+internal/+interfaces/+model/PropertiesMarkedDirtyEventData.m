classdef PropertiesMarkedDirtyEventData < event.EventData

    properties
        PropertyNames
    end

    methods
        function obj = PropertiesMarkedDirtyEventData(propNames)
            obj.PropertyNames = propNames;
        end
    end
end