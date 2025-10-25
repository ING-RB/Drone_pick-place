classdef HasTypeVisitor
%HASTYPEVISITOR Algorithm for determining if one of the PrimitiveType
%objects has a specific type in a NestddType or PrimitiveType object
%hierarchy.

% Copyright 2022 The MathWorks, Inc.

    properties
        Type(1, 1) string
    end

    methods
        function obj = HasTypeVisitor(type)
            obj.Type = type;
        end

        function result = visit(obj, dataType)
            arguments
                obj(1, 1) matlab.io.internal.arrow.schema.HasTypeVisitor
                dataType(1, 1) matlab.io.internal.arrow.schema.DataType
            end

            import matlab.io.internal.arrow.schema.DataTypeEnum

            switch (dataType.DataTypeEnum)
              case DataTypeEnum.Primitive
                result = visitPrimitive(obj, dataType);
              case {DataTypeEnum.List, DataTypeEnum.Struct}
                result = visitNested(obj, dataType);
              otherwise
                % Should never be hit in production
                error(message("MATLAB:io:arrow:matlab2arrow:UnknownDataTypeEnum"));
            end
        end
    end

    methods(Access = private)
        function result = visitPrimitive(obj, primitiveType)
            arguments
                obj(1, 1) matlab.io.internal.arrow.schema.HasTypeVisitor
                primitiveType(1, 1) matlab.io.internal.arrow.schema.PrimitiveType
            end
            result = primitiveType.Type == obj.Type;
        end

        function result = visitNested(obj, nestedType)
            arguments
                obj(1, 1) matlab.io.internal.arrow.schema.HasTypeVisitor
                nestedType(1, 1) matlab.io.internal.arrow.schema.NestedType
            end
            result = false;
            for ii = 1:nestedType.NumChildren
                result = result || visit(obj, nestedType.ChildTypes(ii));
            end
        end
    end
end
