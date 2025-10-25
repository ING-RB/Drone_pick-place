%NonPartitionedProcessor
% Data Processor that applies a function handle to the vertical
% concatenation of all input.
%
% This will buffer all input until upstream data processors have completed,
% then apply a function handle to the vertical concatenation of the data.
%
% See LazyTaskGraph for a general description of input and outputs.
% Specifically, this will emit a single 1 x NumOutputs cell array, where
% each cell contains the full output of the corresponding operation output.
%

%   Copyright 2015-2019 The MathWorks, Inc.

classdef (Sealed) NonPartitionedProcessor < matlab.bigdata.internal.executor.DataProcessor
    % Properties overridden in the DataProcessor interface.
    properties (SetAccess = immutable)
        NumOutputs;
    end
    properties (SetAccess = private)
        IsFinished = false;
        IsMoreInputRequired;
    end
    
    properties (SetAccess = immutable)
        % The slice-wise function handle.
        FunctionHandle;
        
        % The input buffer.
        InputBuffer;
    end
    
    % Methods overridden in the DataProcessor interface.
    methods
        function data = process(obj, isLastOfInputs, varargin)
            assert(~obj.IsFinished, ...
                'Assertion Failed: Process invoked after processor finished.');
            
            % Inputs can be an UnknownEmptyArray, InputBuffer will remove
            % UnknownEmptyArrays as they are vertically concatenated with
            % data blocks.
            inputBuffer = obj.InputBuffer;
            inputBuffer.add(isLastOfInputs, varargin{:});
            
            obj.IsFinished = all(isLastOfInputs);
            if obj.IsFinished
                functionInputs = inputBuffer.getAll();
                % At this point we have the entire array, assert that it is
                % not an UnknownEmptyArray.
                isAnyUnknown = any(cellfun(@matlab.bigdata.internal.UnknownEmptyArray.isUnknown, functionInputs));
                assert(~isAnyUnknown, ...
                    'Assertion Failed: UnknownEmptyArray blocks are not allowed in the output array of NonPartitionedProcessor.');
                [data{1:obj.NumOutputs}] = feval(obj.FunctionHandle, functionInputs{:});
            else
                data = cell(0, obj.NumOutputs);
            end
            obj.IsMoreInputRequired = ~isLastOfInputs;
        end
    end
    
    methods
        function obj = NonPartitionedProcessor(functionHandle, numInputs, numOutputs)
            % Build a processor. This is normally done on the worker by the
            % respective factory.
            import matlab.bigdata.internal.lazyeval.InputBuffer;
            obj.FunctionHandle = functionHandle;
            obj.NumOutputs = numOutputs;
            
            isInputSinglePartition = true(1, numInputs);
            obj.InputBuffer = InputBuffer(numInputs, isInputSinglePartition);
            
            obj.IsMoreInputRequired = true(1, numInputs);
        end
    end
end
