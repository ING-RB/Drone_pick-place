classdef GeneratePathVisitor < matlab.mixin.Scalar
%GENERATEPATHVISITOR Generates Parquet leaf column paths based
% on the arrow DataType.

% Copyright 2022 The MathWorks, Inc.

    properties(SetAccess = private)
        ListSuffix(1, 1) string
    end

    properties(Constant)
        Separator(1, 1) string = "."

        % parquetwrite's UseCompliantNestedTypes nv-pair argument is
        % true by default. This means LIST columns are annotated via
        % a 3-level structure which has the following rules:
        %       - The name of the second level must be "list"
        %       - The name of the third level must be "element".
        CompliantListSuffix(1, 1) string = ".list.element"

        % If the UseCompliantNestedTypes nv-pair argument is false,
        % then LIST columns are annotated witha a 3-level structure, but
        % the name of the third level is "item".
        NoncompliantListSuffix(1, 1) string = ".list.item"
    end

    methods
        function obj = GeneratePathVisitor(nvargs)
            arguments
                nvargs.UseCompliantListSuffix(1, 1) logical = true
            end

            if nvargs.UseCompliantListSuffix
                obj.ListSuffix = obj.CompliantListSuffix;
            else
                obj.ListSuffix = obj.NoncompliantListSuffix;
            end
        end

        function result = visit(obj, prefix, dataType)
            arguments
                obj(1, 1) matlab.io.internal.arrow.schema.GeneratePathVisitor
                prefix(1, 1) string
                dataType(1, 1) matlab.io.internal.arrow.schema.DataType
            end

            import matlab.io.internal.arrow.schema.DataTypeEnum

            switch (dataType.DataTypeEnum)
              case DataTypeEnum.Primitive
                result = prefix;
              case DataTypeEnum.List
                result = visitList(obj, prefix, dataType);
              case DataTypeEnum.Struct
                result = visitStruct(obj, prefix, dataType);
              otherwise
                % Should never be hit in production
                error(message("MATLAB:io:arrow:matlab2arrow:UnknownDataTypeEnum"));
            end
        end
    end

    methods(Access = private)
        function result = visitList(obj, prefix, listType)
            arguments
                obj(1, 1) matlab.io.internal.arrow.schema.GeneratePathVisitor
                prefix(1, 1) string
                listType(1, 1) matlab.io.internal.arrow.schema.ListType
            end

            result = prefix + obj.ListSuffix;

            % ChildTypes must be scalar.
            result = visit(obj, result, listType.ChildTypes);
        end

        function result = visitStruct(obj, prefix, structType)
            arguments
                obj(1, 1) matlab.io.internal.arrow.schema.GeneratePathVisitor
                prefix(1, 1) string
                structType(1, 1) matlab.io.internal.arrow.schema.StructType
            end
            fieldPaths = cell([1 structType.NumChildren]);
            for ii = 1:structType.NumChildren
                temp = prefix + obj.Separator + structType.FieldNames(ii);
                fieldPaths{ii} = visit(obj, temp, structType.ChildTypes(ii));
            end
            result = [fieldPaths{:}];
        end
    end
end
