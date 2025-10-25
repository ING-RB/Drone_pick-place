%FusedReduceByKeyProcessor
% Data Processor that performs a reduction of the current partition to a
% single chunk per key. This differs from the ordinary
% ReduceByKeyProcessor in the respect that different groups of
% input/output variables can have different lengths per key.
%
% This will apply a rolling reduction to all input. It will emit the final
% result of this rolling reduction once all input has been received.
%

%   Copyright 2016-2023 The MathWorks, Inc.

classdef (Sealed) FusedReduceByKeyProcessor < matlab.bigdata.internal.executor.DataProcessor
    % Properties overridden in the DataProcessor interface.
    properties (SetAccess = immutable)
        NumOutputs;
    end
    properties (SetAccess = private)
        IsFinished = false;
        IsMoreInputRequired = true;
    end
    
    properties (GetAccess = private, SetAccess = immutable)
        % A vector of ReduceByKeyProcessor objects that will do the actual
        % work.
        UnderlyingProcessors;
        
        % The number of variables that will be reduced for each
        % ReduceByKeyProcessor.
        NumVariablesVector;
        
        % The number of partitions in the output.
        NumPartitions;
        
        % Whether this processor is required to emit a destination partition
        % index for each output chunk.
        RequiresPartitionIndices (1,1) logical = false;
    end
    
    % Methods overridden in the DataProcessor interface.
    methods
        function data = process(obj, isLastOfInput, varargin)
            assert(~obj.IsFinished, ...
                'Assertion Failed: Process invoked after processor finished.');
            
            isLastOfAllInput = all(isLastOfInput);
            if isscalar(varargin) && ~isscalar(obj.UnderlyingProcessors)
                % In this case, the input originated from a previous
                % FusedReduceByKeyProcessor. We need to separate out the
                % input into one per ReduceByKeyOperation.
                numInputsUsed = 0;
                numInputsVector = obj.NumVariablesVector;
                inputs = cell(1, numel(numInputsVector));
                for ii = 1:numel(numInputsVector)
                    inputs{ii} = varargin{1}(:, numInputsUsed + (1 : numInputsVector(ii)));
                    numInputsUsed = numInputsUsed + numInputsVector(ii);
                end
            else
                inputs = varargin;
            end
            
            % For the actual reduction, delegate to ReduceByKeyProcessor.
            % Up-to this point, all data is packed into cells and so
            % mismatches of sizes in the tall dimension does not matter.
            % Each ReduceByKeyProcessor will unpack its respective input
            % and perform size mismatch checking on its group of variables.
            processors = obj.UnderlyingProcessors;
            data = cell(1, numel(processors));
            for ii = 1:numel(processors)
                data{ii} = processors(ii).process(isLastOfAllInput, inputs{ii});
            end
            obj.IsMoreInputRequired = ~isLastOfInput;
            
            % Stop here if we have not finished the reduction.
            if ~isLastOfAllInput
                data = cell(0, obj.NumOutputs);
                return;
            end
            
            % All ReduceByKeyProcessors should generate the same number of
            % packed cells of output (one for each partition). Mismatch of
            % size in the output is handled because at this point, the
            % output data is already packed into cells by each
            % ReduceByKeyProcessor.
            if obj.RequiresPartitionIndices
                for ii = 2:numel(data)
                    % ReduceByKeyProcessors will return an empty cell with
                    % the expected number of outputs when the keys are
                    % UnknownEmptyArrays. If this is the case, check that
                    % all cells of output are empty.
                    % If the keys are known but any of the data inputs is
                    % UnknownEmptyArray, ReduceByKeyProcessor returns
                    % non-empty cells. Check that all the
                    % ReduceByKeyProcessors returned the same key.
                    if isempty(data{1})
                        assert(isempty(data{ii}), ...
                            'Assertion failed: Two fused ReduceByKeyProcessor produced different output in the presence of UnknownEmptyArray keys');
                    else
                        assert(isequal(data{1}(1), data{ii}(1)), ...
                            'Assertion failed: Two fused ReduceByKeyProcessor produced different keys');
                    end
                    data{ii}(:, 1) = [];
                end
            end
            data = [data{:}];
            obj.IsFinished = true;
        end
    end
    
    methods
        function obj = FusedReduceByKeyProcessor(processors, numVariablesVector, numPartitions, numDependencies, requiresPartitionIndices)
            % Build a processor. This is normally done on the worker by the
            % respective factory.
            import matlab.bigdata.internal.lazyeval.ReduceByKeyProcessor
            
            obj.NumOutputs = sum(numVariablesVector) + requiresPartitionIndices;
            obj.UnderlyingProcessors = vertcat(processors{:});
            obj.NumVariablesVector = numVariablesVector;
            obj.NumPartitions = numPartitions;
            obj.RequiresPartitionIndices = requiresPartitionIndices;
            
            obj.IsMoreInputRequired = true(1, numDependencies);
        end
    end
end
