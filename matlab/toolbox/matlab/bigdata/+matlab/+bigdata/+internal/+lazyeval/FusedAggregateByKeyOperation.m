%FusedAggregateByKeyOperation
% An operation that reduces some transformation of the input data to a
% single chunk per key. This version allows multiple key variables to be
% passed in. Each key variable will have a number of value variables that
% must match slicewise similar to AggregateByKeyOperation. However,
% variables with different Key variables do not need to match, for input or
% for output.

% Copyright 2016-2018 The MathWorks, Inc.

classdef (Sealed) FusedAggregateByKeyOperation < matlab.bigdata.internal.lazyeval.Operation
    properties (SetAccess = immutable)
        % A cell array of function handles to be applied per input chunk of the data.
        PerChunkFunctionHandles;
        
        % A cell array of function handles to be applied to perform the reduction.
        ReduceFunctionHandles;
        
        % A numeric vector of the NumInputs per aggregate by key operation.
        NumInputsPerOperation;
        
        % A numeric vector of the NumOutputs per aggregate by key operation.
        NumOutputsPerOperation;
    end
    
    methods (Static)
        % Fuse a collection of AggregateByKeyOperation and
        % FusedAggregateByKeyOperation objects into a single
        % FusedAggregateByKeyOperation.
        %
        % The inputs of this operation is the concatenation of the inputs
        % of varargin. Similarly, the outputs of this operation is the
        % concatenation of the outputs of varargin.
        function obj = fuse(varargin)
            import matlab.bigdata.internal.lazyeval.FusedAggregateByKeyOperation;
            
            perChunkFunctionHandles = cell(1, numel(varargin));
            reduceFunctionHandles = cell(1, numel(varargin));
            numInputsPerOperation = cell(1, numel(varargin));
            numOutputsPerOperation = cell(1, numel(varargin));
            for ii = 1:numel(varargin)
                input = varargin{ii};
                
                if isa(input, 'matlab.bigdata.internal.lazyeval.AggregateByKeyOperation')
                    perChunkFunctionHandles{ii} = {input.PerChunkFunctionHandle};
                    reduceFunctionHandles{ii} = {input.ReduceFunctionHandle};
                    numInputsPerOperation{ii} = input.NumInputs;
                    numOutputsPerOperation{ii} = input.NumOutputs;
                elseif isa(input, 'matlab.bigdata.internal.lazyeval.FusedAggregateByKeyOperation')
                    perChunkFunctionHandles{ii} = input.PerChunkFunctionHandles;
                    reduceFunctionHandles{ii} = input.ReduceFunctionHandles;
                    numInputsPerOperation{ii} = input.NumInputsPerOperation;
                    numOutputsPerOperation{ii} = input.NumOutputsPerOperation;
                else
                    assert(false, 'FusedAggregateByKeyOperation passed unsupported type ''%s''.', class(input));
                end
            end
            obj = FusedAggregateByKeyOperation(...
                [perChunkFunctionHandles{:}], [reduceFunctionHandles{:}], ...
                [numInputsPerOperation{:}], [numOutputsPerOperation{:}]);
        end
    end
    
    % Methods overridden in the Operation interface.
    methods
        % Create a collection of ExecutionTask objects that represent this
        % operation given the provided inputs.
        function tasks = createExecutionTasks(obj, taskDependencies, inputFutureMap)
            import matlab.bigdata.internal.executor.ExecutionTask;
            import matlab.bigdata.internal.lazyeval.ChunkwiseProcessorFactory;
            import matlab.bigdata.internal.lazyeval.InputMapProcessorFactory;
            import matlab.bigdata.internal.lazyeval.FusedReduceByKeyProcessorFactory;
            
            isInputBroadcast = obj.isInputBroadcast(taskDependencies, inputFutureMap);
            if any(isInputBroadcast) && ~all(isInputBroadcast)
                obj.PerChunkFunctionHandle.throwAsFunction(MException(message('MATLAB:bigdata:array:IncompatibleTallStrictSize')));
            end
            
            % First, do the per chunk behaviour as a collection of
            % independent chunkfun.
            allowTallDimExpansion = false;
            inputsUsed = 0;
            tasks = cell(numel(obj.PerChunkFunctionHandles) + 2, 1);
            for ii = 1:numel(obj.PerChunkFunctionHandles)
                functionHandle = obj.createWrappedKeyedFunctionHandle(obj.PerChunkFunctionHandles{ii});
                inputIndices = inputsUsed + (1 : obj.NumInputsPerOperation(ii));
                perChunkProcessorFactory = ChunkwiseProcessorFactory(...
                    functionHandle, obj.NumOutputsPerOperation(ii), ...
                    isInputBroadcast(inputIndices), allowTallDimExpansion);
                perChunkProcessorFactory = InputMapProcessorFactory(perChunkProcessorFactory, ...
                    submap(inputFutureMap, inputIndices));
                
                tasks{ii} = ExecutionTask.createSimpleTask(taskDependencies, perChunkProcessorFactory, obj.NumOutputsPerOperation(ii));
                inputsUsed = inputsUsed + obj.NumInputsPerOperation(ii);
            end
            tasks = vertcat(tasks{:});
            
            % The inter-chunk part of the operation is done as a single
            % task so that this only schedules a single reduction.
            reduceFunctions = cellfun(@obj.createWrappedKeyedFunctionHandle, obj.ReduceFunctionHandles, 'UniformOutput', false);
            
            
            if all(isInputBroadcast)
                % If in broadcast state, no communication is necessary, so
                % just do the final reduction.
                reduceProcessorFactory = FusedReduceByKeyProcessorFactory(...
                    reduceFunctions, obj.NumOutputsPerOperation);
                finalTask = ExecutionTask.createSimpleTask(tasks, reduceProcessorFactory, obj.NumOutputs, 'IsPassBoundary', true);
                tasks = [tasks; finalTask];
            else
                % Otherwise, do communication.
                reduceProcessorFactory = FusedReduceByKeyProcessorFactory(...
                    reduceFunctions, obj.NumOutputsPerOperation, numel(reduceFunctions), true);
                communicationTask = ExecutionTask.createAnyToAnyTask(tasks, reduceProcessorFactory, obj.NumOutputs, ...
                    'IsPassBoundary', true, 'IsOutputLarge', false);
                % There is only one dependency at this point because the
                % output of the previous FusedReduceByKeyProcessor is fused.
                numDependencies = 1;
                finalProcessorFactory = FusedReduceByKeyProcessorFactory(...
                    reduceFunctions, obj.NumOutputsPerOperation, numDependencies);
                finalTask = ExecutionTask.createSimpleTask(communicationTask, finalProcessorFactory, obj.NumOutputs, 'IsPassBoundary', true);
                tasks = [tasks; communicationTask; finalTask];
            end
        end
    end
    
    methods (Access = private)
        % Private constructor for the fuse method.
        function obj = FusedAggregateByKeyOperation(...
                perChunkFunctionHandles, reduceFunctionHandles, ...
                numInputsPerOperation, numOutputsPerOperation)
            
            obj = obj@matlab.bigdata.internal.lazyeval.Operation(sum(numInputsPerOperation), sum(numOutputsPerOperation));
            obj.PerChunkFunctionHandles = perChunkFunctionHandles;
            obj.ReduceFunctionHandles = reduceFunctionHandles;
            obj.NumInputsPerOperation = numInputsPerOperation;
            obj.NumOutputsPerOperation = numOutputsPerOperation;
        end
        
        function fh = createWrappedKeyedFunctionHandle(obj, fh)
            % Wrap a function handle to both group by key and handle tagged
            % input types.
            import matlab.bigdata.internal.lazyeval.GroupedByKeyFunction;
            import matlab.bigdata.internal.lazyeval.TaggedArrayFunction;
            fh = TaggedArrayFunction.wrap(fh, obj.Options);
            fh = GroupedByKeyFunction.wrap(fh);
        end
    end
end
