%ReduceProcessor
% Data Processor that performs a reduction of the current partition to a
% single chunk.
%
% This will apply a rolling reduction to all input. It will emit the final
% result of this rolling reduction once all input has been received.
%
% See LazyTaskGraph for a general description of input and outputs.
% Specifically, this will receive a N x NumVariables cell array and reduce
% it to a 1 x NumVariables cell array, where each cell contains the final
% reduced chunk of the corresponding operation output.
%

%   Copyright 2015-2024 The MathWorks, Inc.

classdef (Sealed) ReduceProcessor < matlab.bigdata.internal.executor.DataProcessor
    % Properties overridden in the DataProcessor interface.
    properties (SetAccess = immutable)
        NumOutputs;
    end
    properties (SetAccess = private)
        IsFinished = false;
        IsMoreInputRequired = true;
    end
    
    properties (GetAccess = private, SetAccess = immutable)
        % The Reducing function handle.
        FunctionHandle;
    end
    
    properties (Access = private)
        % A buffer for holding partially reduced data while this data
        % processor is still receiving input.
        IntermediateBuffer;
    end
    
    % Methods overridden in the DataProcessor interface.
    methods
        function out = process(obj, isLastOfInput, in)
            assert(~obj.IsFinished, ...
                'Assertion Failed: Process invoked after processor finished.');

            % This enforces pairwise reduction so that we do not get sporadic
            % differences in rounding of results if this processor so
            % happens to receive a different number of chunks in two
            % different passes of the underlying data. This must use cat
            % instead of vertcat as vertcat allows concateniation of empties
            % with incompatible sizes.
            in = cat(1, obj.IntermediateBuffer, in);
            if ~isempty(in)
                state = in(1, :);
                if isempty(obj.IntermediateBuffer)
                    % Call reducefun on the first chunk of the partition in-case
                    % it is the only chunk of the partition.
                    [state{:}] = feval(obj.FunctionHandle, state{:});
                end
                for ii = 2:size(in, 1)
                    state = cellfun(@vertcat, state, in(ii, :), 'UniformOutput', false);
                    [state{:}] = feval(obj.FunctionHandle, state{:});
                end
                obj.IntermediateBuffer = state;
            end
            
            if isLastOfInput
                out = obj.IntermediateBuffer;
                obj.IntermediateBuffer = [];
                obj.IsFinished = true;
                obj.IsMoreInputRequired = false;
                assert(~isempty(out), ...
                    'Assertion failed: ReduceProcessor received zero chunks of data');
            else
                out = cell(0, obj.NumOutputs);
            end
        end
    end
    
    methods
        function obj = ReduceProcessor(functionHandle, numVariables)
            % Build a processor. This is normally done on the worker by the
            % respective factory.
            obj.NumOutputs = numVariables;
            obj.FunctionHandle = functionHandle;
            obj.IntermediateBuffer = cell(0, numVariables);
        end
    end
end
