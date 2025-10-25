classdef (Hidden) FunctionHandleHolder
    % This class is undocumented. It is required to load function-based suites
    % created prior to R2019b.
    
    % Copyright 2014-2019 The MathWorks, Inc.
    
    properties (SetAccess=immutable)
        Function
    end
    
    methods (Access=private)
        function holder = FunctionHandleHolder(fcn)
            holder.Function = fcn;
        end
    end
    
    methods (Static)
        function holder = loadobj(serialized)
            import matlab.unittest.internal.FunctionHandleHolder;
            holder = FunctionHandleHolder(serialized.function);
        end
    end
end

% LocalWords:  unittest
