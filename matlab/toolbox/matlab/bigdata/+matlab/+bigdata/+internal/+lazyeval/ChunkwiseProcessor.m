%ChunkwiseProcessor
% Data Processor that applies a chunk-wise function handle to the input
% data.
%
% This will apply a function handle chunk-wise to all of the data. It will
% emit data continuously throughout a pass.
%
% See LazyTaskGraph for a general description of input and outputs.
% Specifically, each iteration will emit a 1 x NumOutputs cell array where
% each cell contains a chunk of output of the corresponding operation
% output.
%

%   Copyright 2015-2018 The MathWorks, Inc.

classdef (Sealed) ChunkwiseProcessor < matlab.bigdata.internal.executor.DataProcessor
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
    end
    
    % Methods overridden in the DataProcessor interface.
    methods
        function data = process(obj, isLastOfInput, varargin)
            assert(~obj.IsFinished, ...
                'Assertion Failed: Process invoked after processor finished.');
            [data{1:obj.NumOutputs}] = feval(obj.FunctionHandle, varargin{:});
            obj.IsFinished = all(isLastOfInput);
        end
    end
    
    methods
        function obj = ChunkwiseProcessor(functionHandle, numInputs, numOutputs)
            % Build a processor. This is normally done on the worker by the
            % respective factory.
            obj.FunctionHandle = functionHandle;
            obj.NumOutputs = numOutputs;
            obj.IsMoreInputRequired = true(1, numInputs);
        end
    end
end
