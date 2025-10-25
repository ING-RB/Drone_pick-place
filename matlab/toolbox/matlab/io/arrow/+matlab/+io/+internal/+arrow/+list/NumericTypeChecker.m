classdef NumericTypeChecker < matlab.io.internal.arrow.list.ClassTypeChecker
%NUMERICTYPECHECKER Validates cell arrays containing numeric vectors
% can be exported as Parquet LIST columns of numeric arrays.

% Copyright 2022 The MathWorks, Inc.
    methods
        function obj = NumericTypeChecker(classType)
            obj = obj@matlab.io.internal.arrow.list.ClassTypeChecker(classType);
        end

        function checkType(obj, array)
        % Verify array is numeric with the expected class name
            checkType@matlab.io.internal.arrow.list.ClassTypeChecker(obj, array);

            % Verify the array is real.
            if ~isreal(array)
                exceptionType = matlab.io.internal.arrow.error.ExceptionType.ComplexNumber;
                matlab.io.internal.arrow.error.ExceptionFactory.throw(exceptionType);
            end

            % Verify the array is non-sparse.
            if issparse(array)
                exceptionType = matlab.io.internal.arrow.error.ExceptionType.SparseArray;
                matlab.io.internal.arrow.error.ExceptionFactory.throw(exceptionType, obj.ClassType);
            end
        end
    end
end
