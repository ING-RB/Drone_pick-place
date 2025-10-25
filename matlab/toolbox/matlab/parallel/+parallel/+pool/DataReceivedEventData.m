classdef (Hidden) DataReceivedEventData < event.EventData
    %

    % Copyright 2016-2021 The MathWorks, Inc.
    
    properties (SetAccess = immutable)
        ReceivedData
    end
    
    methods
        function obj = DataReceivedEventData(data)
            obj.ReceivedData = data;
        end
    end
end