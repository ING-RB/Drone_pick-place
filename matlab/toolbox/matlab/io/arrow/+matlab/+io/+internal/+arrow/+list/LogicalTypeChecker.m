classdef LogicalTypeChecker < matlab.io.internal.arrow.list.ClassTypeChecker
%LOGICALTYPECHECKER Validates cell arrays containing logical vectors
% can be exported as Parquet LIST columns of boolean arrays.

% Copyright 2022 The MathWorks, Inc.
     methods
        function obj = LogicalTypeChecker()
            obj = obj@matlab.io.internal.arrow.list.ClassTypeChecker("logical");
        end

        function checkType(obj, array)
        % Verify array is logical and non-sparse.

            % Invoke checkType@ClassTypeChecker to verify the array is
            % logical and has the appropriate size.
            checkType@matlab.io.internal.arrow.list.ClassTypeChecker(obj, array);

            % Verify the array is non-sparse.
            if issparse(array)
                exceptionType = matlab.io.internal.arrow.error.ExceptionType.SparseArray;
                matlab.io.internal.arrow.error.ExceptionFactory.throw(exceptionType, obj.ClassType);
            end
        end
    end
end