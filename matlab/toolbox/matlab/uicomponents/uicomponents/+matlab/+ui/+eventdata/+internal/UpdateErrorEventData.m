classdef UpdateErrorEventData < event.EventData
    %UPDATEERROREVENTDATA Argument to notify() used when an exception
    %occurs in the update method of a derived component container.
    %   Currently used by App Designer to present the exception in code
    %   view
    
    %Copyright 2021, MathWorks Inc.
    
    properties
        Exception
    end
    
    methods
        function eventData = UpdateErrorEventData(ex)
            eventData.Exception = ex;
        end
    end
end

