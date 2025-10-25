classdef ClassTypeChecker < matlab.io.internal.arrow.list.TypeChecker
%CLASSTYPECHECKER Used to verify arrays in a cell array have the same class
% type. Also verifies the arrays are either vectors or empty.
%
% Example:
%
%       import matlab.io.internal.arrow.list.*
%
%       classTypeChecker = ClassTypeChecker("string");
%
%       % data1 is a double instead of a string, so checkType errors.
%       data1 = 5;
%       checkType(classTypeChecker, data1);
%
%       % data2 is a string, so checkType does NOT error.
%       data2 = "B";
%       checkType(classTypeChecker, data2);

% Copyright 2022 The MathWorks, Inc.

    properties(SetAccess = private, GetAccess = public)
        ClassType(1, 1) string
    end

    methods
        function obj = ClassTypeChecker(classType)
            obj.ClassType = classType;
        end

        function checkType(obj, array)

            differentTypes = class(array) ~= obj.ClassType;

            if differentTypes
                % array's class type is not equal to the expected class
                % type. Throw a NonUniformCellError, including the variable
                % name if array is a variable in a table.
                exceptionType = matlab.io.internal.arrow.error.ExceptionType.NonUniformCell;
                matlab.io.internal.arrow.error.ExceptionFactory.throw(...
                    exceptionType, class(array), obj.ClassType);
            end

            % Validate array is a vector or empty
            if ~isvector(array) && ~isempty(array)
                exceptionType = matlab.io.internal.arrow.error.ExceptionType.InvalidCellElementDims;
                matlab.io.internal.arrow.error.ExceptionFactory.throw(exceptionType);
            end
        end
    end
end
