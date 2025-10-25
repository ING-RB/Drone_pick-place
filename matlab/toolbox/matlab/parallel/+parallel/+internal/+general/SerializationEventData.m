%SerializationEventData Event data for SerializationNotifier

% Copyright 2018-2020 The MathWorks, Inc.

classdef (ConstructOnLoad) SerializationEventData < event.EventData
    properties
        ClassName
        Operation % 'serialized' or 'deserialized'
    end
    methods
        function obj = SerializationEventData(className, operation)
            obj.ClassName = className;
            obj.Operation = operation;
        end
    end
end


