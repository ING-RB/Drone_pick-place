classdef SendOnlyQueue < parallel.internal.dataqueue.Queue
    % Interface for internal implementations of DataQueue that can only
    % send data.
    
    % Copyright 2020-2021 The MathWorks, Inc.
    
    % Common methods implemented by all Queue implementation classes
    methods
        function out = poll(~, ~) %#ok<STOUT>
            error(message("MATLAB:parallel:dataqueue:NoQueue"));
        end
        
        function out = drain(~) %#ok<STOUT>
            error(message("MATLAB:parallel:dataqueue:NoQueue"));
        end
        
        function clear(~)
            error(message("MATLAB:parallel:dataqueue:NoQueue"));
        end
        
        function sz = getSize(~)
            sz = 0;
        end
    end
end
