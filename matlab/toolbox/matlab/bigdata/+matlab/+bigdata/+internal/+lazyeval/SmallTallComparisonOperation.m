%SmallTallComparisonOperation
% An operation that performs a binary comparison with an in-memory scalar.
% This is an ElementwiseOperation with special treatment in the tall lazy
% evaluation framework for optimization.

%   Copyright 2022 The MathWorks, Inc.

classdef SmallTallComparisonOperation < matlab.bigdata.internal.lazyeval.ElementwiseOperation
    properties (SetAccess = immutable)
        % The binary operator used in the function handle
        BinaryOperator;

        % The small operand used in the function handle, in-memory scalar
        % or char vector.
        SmallOperand;

        % Flag that indicates if the tall array is the first argument of
        % the binary comparison.
        IsTallFirstArg;
    end

    methods
        % The main constructor.
        function obj = SmallTallComparisonOperation(options, fcnHandle, smallOperand, isTallFirst, numInputs, numOutputs)
            obj = obj@matlab.bigdata.internal.lazyeval.ElementwiseOperation(...
                options, fcnHandle, numInputs, numOutputs);
            % Extract the underlying binary operator from fcnHandle.
            obj.BinaryOperator = matlab.bigdata.internal.util.unwrapFunctionHandle(fcnHandle);
            obj.SmallOperand = smallOperand;
            obj.IsTallFirstArg = isTallFirst;
        end
    end
end