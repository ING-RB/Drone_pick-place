%AdaptorAssertionOperation
% An operation that checks the adaptor information for each element of
% data. This is an ElementwiseOperation with special treatment in the tall
% lazy evaluation framework for optimization.

% Copyright 2022 The MathWorks, Inc.

classdef AdaptorAssertionOperation < matlab.bigdata.internal.lazyeval.ElementwiseOperation
    methods
        % The main constructor.
        function obj = AdaptorAssertionOperation(options, fcnHandle, numInputs, numOutputs)
            obj = obj@matlab.bigdata.internal.lazyeval.ElementwiseOperation(...
                options, fcnHandle, numInputs, numOutputs);
        end
    end
end