%RepartitionProcessor
% An implementation of the DataProcessor interface that used in combination
% with an AnyToAny ExecutionTask to repartition a partitioned array to any
% chosen partitioning.

%   Copyright 2016-2018 The MathWorks, Inc.

classdef (Sealed) RepartitionProcessor < matlab.bigdata.internal.executor.DataProcessor
    % Properties overridden in the DataProcessor interface.
    properties (SetAccess = immutable)
        NumOutputs;
    end
    properties (SetAccess = private)
        IsFinished = false;
        IsMoreInputRequired = true;
    end
    
    properties (GetAccess = private, SetAccess = immutable)
        % The number of partitions after the communication.
        NumOutputPartitions;
    end
    
    % Methods overridden in the DataProcessor interface.
    methods
        function data = process(obj, isLastOfInput, partitionIndices, varargin)
            assert(~obj.IsFinished, ...
                'Assertion Failed: Process invoked after processor finished.');
            if (size(varargin{1}, 1) == 0) && ~all(isLastOfInput)
                data = cell(0, obj.NumOutputs);
                return;
            end
            
            data = iPartitionData(obj.NumOutputPartitions, partitionIndices, varargin{:});
            obj.IsFinished = all(isLastOfInput);
            obj.IsMoreInputRequired = ~isLastOfInput;
        end
    end
    
    methods
        function obj = RepartitionProcessor(numVariables, numOutputPartitions)
            % Build a processor. This is normally done on the worker by the
            % respective factory.
            obj.NumOutputs = numVariables + 1;
            obj.NumOutputPartitions = numOutputPartitions;
        end
    end
end

% Bin the input slices based on a column vector of target partition indices.
function data = iPartitionData(numPartitions, indices, varargin)
import matlab.bigdata.internal.util.indexSlices;

data = cell(numPartitions, numel(varargin) + 1);
isUnknown = matlab.bigdata.internal.UnknownEmptyArray.isUnknown(indices);
for partitionIdx = 1:numPartitions
    data{partitionIdx, 1} = partitionIdx;
    for inputIdx = 1:numel(varargin)
        if isUnknown
            data{partitionIdx, inputIdx + 1} = varargin{inputIdx};
        else
            data{partitionIdx, inputIdx + 1} = indexSlices(varargin{inputIdx}, indices == partitionIdx);
        end
    end
end
end
