%FilterOperation
% An operation that filters slices based on a partitioned logical array.

% Copyright 2015-2022 The MathWorks, Inc.

classdef FilterOperation < matlab.bigdata.internal.lazyeval.Operation
    
    properties (SetAccess = immutable)
        % A FunctionHandle pointing to the internal filterFunction method.
        % We hold this so that submission stack information is captured.
        FunctionHandle;
    end
    
    methods
        % The main constructor.
        %
        % Here, numFilteredInputs is the number of inputs excluding the
        % filter itself.
        function obj = FilterOperation(numFilteredInputs)
            numInputs = numFilteredInputs + 1;
            numOutputs = numFilteredInputs;
            supportsPreview = true;
            obj = obj@matlab.bigdata.internal.lazyeval.Operation(numInputs, numOutputs, supportsPreview);
            obj.FunctionHandle = matlab.bigdata.internal.FunctionHandle(@filterFunction);
        end
    end
    
    % Methods overridden in the Operation interface.
    methods
        function task = createExecutionTasks(obj, taskDependencies, inputFutureMap)
            import matlab.bigdata.internal.executor.ExecutionTask;
            import matlab.bigdata.internal.lazyeval.ChunkwiseProcessorFactory;
            import matlab.bigdata.internal.lazyeval.InputMapProcessorFactory;
            import matlab.bigdata.internal.lazyeval.TaggedArrayFunction;
            
            isBroadcast = arrayfun(@(x)x.OutputPartitionStrategy.IsBroadcast, taskDependencies);
            if any(isBroadcast) && ~all(isBroadcast)
                obj.FunctionHandle.throwAsFunction(MException(message('MATLAB:bigdata:array:IncompatibleTallStrictSize')));
            end
            
            fh = TaggedArrayFunction.wrap(obj.FunctionHandle, obj.Options);
            allowTallDimExpansion = false;
            processorFactory = ChunkwiseProcessorFactory(...
                fh, obj.NumOutputs, ...
                obj.isInputBroadcast(taskDependencies, inputFutureMap), ...
                allowTallDimExpansion);
            processorFactory = InputMapProcessorFactory(processorFactory, inputFutureMap);
            
            task = ExecutionTask.createSimpleTask(taskDependencies, processorFactory, obj.NumOutputs);
        end
    end
end

function varargout = filterFunction(subs, varargin)
varargout = cell(size(varargin));

for ii = 1:numel(varargin)
    trailingColons = repmat({':'}, 1, ndims(varargin{ii}) - 1);
    varargout{ii} = subsref(varargin{ii}, substruct('()', [{subs}, trailingColons]));
end
end
