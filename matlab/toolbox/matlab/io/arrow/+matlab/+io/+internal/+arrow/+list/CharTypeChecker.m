classdef CharTypeChecker < matlab.io.internal.arrow.list.TypeChecker
%CHARTYPECHECKER Validates cell arrays containing char arrays
% can be converted to Parquet LIST<UTF8>.

% Copyright 2022 The MathWorks, Inc.

    properties(SetAccess = private, GetAccess = public)
        Width(1,1) double
    end

    methods
        function obj = CharTypeChecker(nvargs)
            arguments
                nvargs.Width = 0;
            end
            obj.Width = nvargs.Width;
        end

        function checkType(obj, array)
            if ~ischar(array)
                exceptionType = matlab.io.internal.arrow.error.ExceptionType.NonUniformCell;
                matlab.io.internal.arrow.error.ExceptionFactory.throw(...
                    exceptionType, class(array), "char");
            end

            if ~ismatrix(array)
                exceptionType = matlab.io.internal.arrow.error.ExceptionType.InvalidNDCharArray;
                matlab.io.internal.arrow.error.ExceptionFactory.throw(exceptionType);
            end

            if obj.Width ~= size(array, 2)
                exceptionType = matlab.io.internal.arrow.error.ExceptionType.NonUniformCharWidth;
                matlab.io.internal.arrow.error.ExceptionFactory.throw(...
                    exceptionType, size(array, 2), obj.Width);
            end
        end
    end
end
