%LogicalElementwiseOperation
% An operation that performs a logical elementwise operation (and, or, not,
% xor). This is an ElementwiseOperation with special treatment in the tall
% lazy evaluation framework for optimization.

%   Copyright 2022 The MathWorks, Inc.

classdef LogicalElementwiseOperation < matlab.bigdata.internal.lazyeval.ElementwiseOperation
    properties (SetAccess = immutable)
        % The logical operator used in the function handle (and, or, not)
        LogicalOperator;
    end

    methods
        % The main constructor.
        function obj = LogicalElementwiseOperation(options, fcnHandle, numInputs, numOutputs)
            obj = obj@matlab.bigdata.internal.lazyeval.ElementwiseOperation(...
                options, fcnHandle, numInputs, numOutputs);
            % Extract the underlying binary operator from fcnHandle.
            obj.LogicalOperator = matlab.bigdata.internal.util.unwrapFunctionHandle(fcnHandle);
        end
    end
end