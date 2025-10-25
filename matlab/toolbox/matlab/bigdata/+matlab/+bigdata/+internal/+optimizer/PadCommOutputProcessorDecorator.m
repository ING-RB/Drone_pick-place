%PadCommOutputProcessorDecorator
% DataProcessor decorator that redirects the output of AllToOne or AnyToAny
% operation to match partition strategy after vertical concatenation. This
% itself is coupled to an AnyToAny operation, the first output of process
% is partition indices of where to send each chunk.

%   Copyright 2018-2019 The MathWorks, Inc.

classdef PadCommOutputProcessorDecorator < matlab.bigdata.internal.executor.DataProcessor
    % Properties overridden in the DataProcessor interface.
    properties (SetAccess = immutable)
        NumOutputs;
    end
    properties (SetAccess = private)
        IsFinished = false;
        IsMoreInputRequired;
    end
    
    properties (GetAccess = private, SetAccess = immutable)
        % The underlying processor that performs the actual processing.
        Processor (1,1)
        
        % Flag whether the underlying processor was from an AnyToAny task.
        % This is important as the first output of the underlying processor
        % will be partition indices for where to send each chunk.
        UnderlyingIsAnyToAny (1,1) logical
        
        % Number of partitions being prepend to the beginning of the
        % output. All partition indices will be adjusted to account for
        % this.
        NumPartitionsToPrepend (1,1) double
        
        % Number of partitions being appended to the end of the output.
        % This is used because AnyToAny currently expects every partition
        % after communication to have at least one chunk.
        NumPartitionsToAppend (1,1) double
        
        % Total number of partitions after communication.
        TotalNumPartitions (1,1) double
    end
    
    % Methods overridden in the DataProcessor interface.
    methods
        function data = process(obj, isLastOfInputsVector, varargin)
            assert(~obj.IsFinished, ...
                'Assertion Failed: Process invoked after processor finished.');
            
            data = obj.Processor.process(isLastOfInputsVector, varargin{:});
            obj.updateState();
            
            if obj.UnderlyingIsAnyToAny
                % For AnyToAny, we need to ensure the partition indices are
                % corrected to the new partitioning.
                data(:, 1) = cellfun(@(x) iIncreasePartitionIndices(x, obj.NumPartitionsToPrepend), ...
                    data(:, 1), "UniformOutput", false);
            else
                % Otherwise, we need to add the missing partition indices
                % for all output chunks to make it AnyToAny compatible.
                data(:, 2:end + 1) = data;
                data(:, 1) = {obj.NumPartitionsToPrepend + 1};
            end
        end
    end
    
    methods (Access = ?matlab.bigdata.internal.optimizer.PadCommOutputProcessorFactory)
        function obj = PadCommOutputProcessorDecorator(processor, underlyingIsAnyToAny, ...
                numPartitionsToPrepend, numPartitionsToAppend, totalNumPartitions)
            % Private constructor for PadCommOutputProcessorFactory.
            obj.Processor = processor;
            obj.NumOutputs = processor.NumOutputs;
            obj.UnderlyingIsAnyToAny = underlyingIsAnyToAny;
            obj.NumPartitionsToPrepend = numPartitionsToPrepend;
            obj.NumPartitionsToAppend = numPartitionsToAppend;
            obj.TotalNumPartitions = totalNumPartitions;
            obj.updateState();
        end
        
        function updateState(obj)
            % Update the DataProcessor public properties to correspond with
            % the equivalent of the underlying processor.
            obj.IsFinished = obj.Processor.IsFinished;
            obj.IsMoreInputRequired = obj.Processor.IsMoreInputRequired;
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function partitionIndices = iIncreasePartitionIndices(partitionIndices, offset)
% Increases partition indices to translate indices before vertcat to
% indices after vertcat.
if ~matlab.bigdata.internal.UnknownEmptyArray.isUnknown(partitionIndices)
    partitionIndices = partitionIndices + offset;
end
end

