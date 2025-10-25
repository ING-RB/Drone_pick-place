classdef CategoricalTypeChecker < matlab.io.internal.arrow.list.ClassTypeChecker
%CATEGORICALTYPECHECKER Validates cell arrays containing categorical
% vectors can be converted to Parquet LIST columns of dictionary arrays.
%
% Example:
%
%       import matlab.io.internal.arrow.list.*
%
%       categoricalChecker = CategoricalTypeChecker(IsOrdinal=true);
%
%       % cat1 is not ordinal, so checkType errors.
%       cat1 = categorical(["A", "B", "C"], Ordinal=false);
%       checkType(categoricalChecker, cat1);
%
%       % cat2 is ordinal, so checkType does NOT error.
%       cat2 = categorical(["A", "B", "C"], Ordinal=true);
%       checkType(categoricalChecker, cat2);

% Copyright 2022 The MathWorks, Inc.

    properties(SetAccess = private, GetAccess = public)
        % IsOrdinal     Logical value indicating if every categorical
        %               vector must be ordinal. False by default.
        IsOrdinal(1, 1) logical = false

        %Categories     String array containing the expected categories in
        %               each categorical array if IsOrdinal is true.
        %               Ordinal arrays must have the same categories,
        %               including their order. If IsOrdinal is false,
        %               checkType does not check does not check that the
        %               input categorical array's categories
        %               are equal to the Categories property.
        Categories(:, 1) string
    end

    methods
        function obj = CategoricalTypeChecker(nvargs)
            arguments
                nvargs.IsOrdinal = false;
                nvargs.Categories = strings(1, 0);
            end
            obj = obj@matlab.io.internal.arrow.list.ClassTypeChecker("categorical");
            obj.IsOrdinal = nvargs.IsOrdinal;
            obj.Categories = nvargs.Categories;
        end

        function checkType(obj, array)
        % Verify the class of array is "categorical"
            checkType@matlab.io.internal.arrow.list.ClassTypeChecker(obj, array);

            % Verify the array is ordinal if obj.IsOrdinal is true.
            % Otherwise verify the array is not ordinal.
            if obj.IsOrdinal ~= isordinal(array)
                exceptionType = matlab.io.internal.arrow.error.ExceptionType.OrdinalMismatch;
                matlab.io.internal.arrow.error.ExceptionFactory.throw(...
                    exceptionType, obj.IsOrdinal);
            end

            % Verify array's categories are equal to the obj.Categories
            % array if obj.IsOrdinal is true. Two ordinal arrays are
            % "vertcatable" only if they have the same categories
            % and the categories are in the same order.
            if obj.IsOrdinal && ~isequal(obj.Categories, categories(array))
                exceptionType = matlab.io.internal.arrow.error.ExceptionType.OrdinalCategoriesMismatch;
                matlab.io.internal.arrow.error.ExceptionFactory.throw(...
                    exceptionType, categories(array), obj.Categories);
            end
        end
    end
end
