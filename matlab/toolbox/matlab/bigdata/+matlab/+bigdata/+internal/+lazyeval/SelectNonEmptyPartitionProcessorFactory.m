%SelectNonEmptyPartitionProcessorFactory
% Factory for building a SelectNonEmptyPartitionProcessor

%   Copyright 2018 The MathWorks, Inc.

classdef (Sealed) SelectNonEmptyPartitionProcessorFactory < matlab.bigdata.internal.executor.DataProcessorFactory
    properties (SetAccess = immutable)
        % Underlying function to be applied chunkwise to the data.
        Function (1,1)
        
        % Number of variables in the input
        NumVariables (1,1) double
    end
    
    methods
        function obj = SelectNonEmptyPartitionProcessorFactory(fcn, numVariables)
            % Build a SelectNonEmptyPartitionProcessorFactory whose
            % processors select and pass-through whichever input partition
            % is non-empty.
            obj.Function = fcn;
            obj.NumVariables = numVariables;
        end
        
        % Build the processor.
        function processor = feval(obj, ~, ~)
            import matlab.bigdata.internal.lazyeval.SelectNonEmptyPartitionProcessor
            processor = SelectNonEmptyPartitionProcessor(copy(obj.Function), obj.NumVariables);
        end
    end
end
