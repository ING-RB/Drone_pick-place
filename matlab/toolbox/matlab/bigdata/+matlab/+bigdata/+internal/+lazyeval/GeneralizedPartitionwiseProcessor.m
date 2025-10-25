%GeneralizedPartitionwiseProcessor
% Data Processor that applies a partition-wise function handle to the input
% data without any restriction to input size.
%
% This will apply a function handle chunk-wise using the advanced
% partitionwise API. It will emit data continuously throughout a pass.
%
% See LazyTaskGraph for a general description of input and outputs.
% Specifically, each iteration will emit a 1 x NumOutputs cell array where
% each cell contains a chunk of output of the corresponding operation
% output.
%

%   Copyright 2017-2019 The MathWorks, Inc.

classdef (Sealed) GeneralizedPartitionwiseProcessor < matlab.bigdata.internal.executor.DataProcessor
    % Properties overridden in the DataProcessor interface.
    properties (SetAccess = immutable)
        NumOutputs;
    end
    properties (SetAccess = private)
        IsFinished = false;
        IsMoreInputRequired;
    end
    
    properties (GetAccess = private, SetAccess = immutable)
        % The chunk-wise function handle.
        FunctionHandle;
        
        % The index of the current partition into the number of partitions
        % for the task.
        PartitionIndex;
        
        % The number of partitions that this operation is partitioned into.
        NumPartitions
    end
    
    properties (SetAccess = private)
        % A buffer to hold both unused inputs as well as inputs prior to
        % having received at least one chunk per input.
        InputBuffer;
        
        % The relative input in each partition.
        RelativeIndexInPartition;
    end
    
    % Methods overridden in the DataProcessor interface.
    methods
        %PROCESS Process the next chunk of data.
        function output = process(obj, isLastOfInputsVector, varargin)
            assert(~obj.IsFinished, ...
                'Assertion Failed: Process invoked after processor finished.');
            
            obj.InputBuffer.add(isLastOfInputsVector, varargin{:});
            
            % We require at least one chunk per input to get size, type and
            % broadcast information.
            if any(~obj.InputBuffer.IsBufferInitialized)
                output = cell(0, obj.NumOutputs);
                return;
            end
            
            % Store numSlices to increment RelativeIndexInPartition later.
            % Broadcasts do not increment.
            numSlices = obj.InputBuffer.NumBufferedSlices;
            numSlices(obj.InputBuffer.IsInputSingleSlice) = 0;
            
            varargin = obj.InputBuffer.getAll();
            info = struct(...
                'PartitionId', obj.PartitionIndex, ...
                'NumPartitions', obj.NumPartitions, ...
                'IsBroadcast', obj.InputBuffer.IsInputSingleSlice, ...
                'IsLastChunk', isLastOfInputsVector, ...
                'RelativeIndexInPartition', obj.RelativeIndexInPartition);
            [isFinished, unusedInputs, output{1 : obj.NumOutputs}] = ...
                feval(obj.FunctionHandle, info, varargin{:});
            
            % UnknownEmptyArray blocks are propagated across partitionwise
            % operations. InputBuffer is responsible for handling
            % UnknownEmptyArray blocks by vertically concatenating them
            % with data blocks. Or, in the case of an entire partition
            % formed by UnknownEmptyArray blocks, InputBuffer will not be
            % initialized until we get to the last block of the partition.
            % At that point, which is the only time when we get here, we
            % have not invoked the function in TaggedArrayFunction and
            % isFinished is also UnknownEmptyArray. We need to update its
            % value with the info structure and we can do an early exit.
            if matlab.bigdata.internal.UnknownEmptyArray.isUnknown(isFinished)
                obj.IsFinished = all(info.IsLastChunk);
                isMoreInputRequiredVector = ~isLastOfInputsVector;
                obj.IsMoreInputRequired = ~obj.IsFinished & isMoreInputRequiredVector;
                return;
            else
                obj.IsFinished = isFinished;
            end
            
            isOutputEmpty = all(cellfun(@isempty, output));
            
            % Deal with unused inputs.
            if isempty(unusedInputs)
                isMoreInputRequiredVector = ~isLastOfInputsVector;
                
            elseif iscell(unusedInputs)
                % Deal with unused inputs. In particular, we do not add
                % broadcasts back to the buffer.
                unusedInputs = num2cell(unusedInputs);
                unusedInputs(obj.InputBuffer.IsInputSingleSlice) = {cell(0, 1)};
                obj.InputBuffer.add(isLastOfInputsVector, unusedInputs{:});
                
                numBufferedSlices = obj.InputBuffer.NumBufferedSlices;
                if isOutputEmpty
                    % If no output, we assume the calculation cannot
                    % continue only because there wasn't enough input. So
                    % we choose to request more input based on which
                    % has the fewest slices in the buffer.
                    bufferTooShortThreshold = max(max(numBufferedSlices), 1);
                    isBufferTooShortVector = numBufferedSlices < bufferTooShortThreshold;
                    isMoreInputRequiredVector = ~isLastOfInputsVector & isBufferTooShortVector;
                    if all(~isMoreInputRequiredVector)
                        isMoreInputRequiredVector(~isLastOfInputsVector) = true;
                    end
                else
                    % If output, we have to be careful because the function
                    % handle might expand data. If inputs are unused, it
                    % might be because there is no room in the output. So
                    % we choose to request more input only if that input is
                    % empty.
                    bufferTooShortThreshold = 1;
                    isBufferTooShortVector = numBufferedSlices < bufferTooShortThreshold;
                    isMoreInputRequiredVector = ~isLastOfInputsVector & isBufferTooShortVector;
                end
            elseif islogical(unusedInputs)
                isMoreInputRequiredVector = ~unusedInputs;
                
            else
                assert(false, 'Function handle returned unused inputs of type ''%s''.', class(unusedInputs));
            end
            
            obj.RelativeIndexInPartition = obj.RelativeIndexInPartition + numSlices - obj.InputBuffer.NumBufferedSlices;
            obj.IsMoreInputRequired = ~obj.IsFinished & isMoreInputRequiredVector;
            
            isNotDeadlocked = obj.IsFinished ...
                || any(obj.IsMoreInputRequired) ...
                || ~isOutputEmpty;
            assert(isNotDeadlocked, 'A generalized partitionfun processor is in deadlock.');
        end
    end
    
    methods
        function obj = GeneralizedPartitionwiseProcessor(functionHandle, partitionIndex, numPartitions, numOutputs, isInputBroadcast)
            % Build a processor. This is normally done on the worker by the
            % respective factory.
            import matlab.bigdata.internal.lazyeval.InputBuffer;
            obj.NumOutputs = numOutputs;
            obj.FunctionHandle = functionHandle;
            obj.PartitionIndex = partitionIndex;
            obj.NumPartitions = numPartitions;
            obj.IsMoreInputRequired = true(size(isInputBroadcast));
            obj.InputBuffer = InputBuffer(numel(isInputBroadcast), isInputBroadcast);
            obj.RelativeIndexInPartition = ones(1, numel(isInputBroadcast));
        end
    end
end
