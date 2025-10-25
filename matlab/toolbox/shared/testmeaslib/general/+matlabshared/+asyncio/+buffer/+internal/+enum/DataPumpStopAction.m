classdef DataPumpStopAction 
    %DATAPUMPSTOPACTION Represents the action for a data pump to take after
    %it stops.
        
    % Copyright 2018 The MathWorks, Inc.
    
    enumeration
        None    % Take no action after stop
        Drain   % Drain the buffer into the sink
        Flush   % Flush the buffer (no data sent to sink)
    end
end
