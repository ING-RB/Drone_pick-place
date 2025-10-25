%PartitionwiseProcessor
% Data Processor that applies a partition-wise function handle to the input
% data.
%
% This will apply a function handle chunk-wise using the advanced
% partitionwise API. It will emit data continuously throughout a pass.
%
% See LazyTaskGraph for a general description of input and outputs.
% Specifically, each iteration will emit a 1 x NumOutputs cell array where
% each cell contains a chunk of output of the corresponding operation
% output.
%

%   Copyright 2015-2019 The MathWorks, Inc.

classdef (Sealed) PartitionwiseProcessor < matlab.bigdata.internal.executor.DataProcessor
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
        PartitionIndex = 1;
        
        % The number of partitions that this operation is partitioned into.
        NumPartitions
    end
    
    properties (SetAccess = private)
        % The relative index of the first slice in the next chunk to be
        % passed to the function handle.
        RelativeIndexInPartition = 1;
    end
    
    % Methods overridden in the DataProcessor interface.
    methods
        function data = process(obj, isLastOfInputsVector, varargin)
            assert(~obj.IsFinished, ...
                'Assertion Failed: Process invoked after processor finished.');
            
            numSlices = matlab.bigdata.internal.lazyeval.determineNumSlices(varargin{:});
            info = struct(...
                'PartitionId', obj.PartitionIndex, ...
                'NumPartitions', obj.NumPartitions, ...
                'RelativeIndexInPartition', obj.RelativeIndexInPartition, ...
                'IsLastChunk', all(isLastOfInputsVector));
            [isFinished, data{1:obj.NumOutputs}] = feval(obj.FunctionHandle, info, varargin{:});
            
            % UnknownEmptyArray blocks are propagated across partitionwise
            % operations. If any of the input blocks was an
            % UnknownEmptyArray, isFinished is also UnknownEmptyArray and
            % we need to update its value with the info structure.
            if matlab.bigdata.internal.UnknownEmptyArray.isUnknown(isFinished)
                obj.IsFinished = info.IsLastChunk;
            else
                obj.IsFinished = isFinished;
            end
            
            obj.RelativeIndexInPartition = obj.RelativeIndexInPartition + numSlices;
        end
        
        function throwFromFunctionHandle(obj, err)
            obj.FunctionHandle.throwAsFunction(err);
        end
    end
    
    methods
        function obj = PartitionwiseProcessor(functionHandle, partitionIndex, numPartitions, numInputs, numOutputs)
            % Build a processor. This is normally done on the worker by the
            % respective factory.
            obj.NumOutputs = numOutputs;
            obj.FunctionHandle = functionHandle;
            obj.PartitionIndex = partitionIndex;
            obj.IsMoreInputRequired = true(1, numInputs);
            obj.NumPartitions = numPartitions;
        end
    end
end
