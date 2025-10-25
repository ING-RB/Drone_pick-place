classdef SaveCompletedEventData < event.EventData
    properties
        Status
        Exception
    end

    methods
        function obj = SaveCompletedEventData(status, exception)
            obj.Status = status;
            obj.Exception = exception;
        end
    end
end