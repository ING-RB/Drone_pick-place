classdef IndexOperation
%INDEXOPERATION Describes the indexing operation applied to an array.

% Copyright 2022 The MathWorks, Inc.
%   Detailed explanation goes here

    properties(SetAccess = private)
        %Type           A matlab.io.internal.arrow.error.IndexType
        %               enumeration value indicating whether this
        %               IndexOperation object uses dot, braces or parens
        %               notation.
        Type(1, 1) matlab.io.internal.arrow.error.IndexType
    end

    properties
        %IndexArgument  If Type is IndexType.Dot, IndexArgument is a string
        %               and contains the name of the field or property
        %               referenced in a dot indexing operation. Otherwise,
        %               IndexArgument is a positive integer double
        %               referenced in a braces or parens indexing
        %               operation.
        IndexArgument(1, 1)
    end

    properties(Dependent)
        %OPERATIONSTRING    A string representation of the indexing
        %                   operation.
        OperationString
    end

    properties(Constant, Access = private)
        %DOTNOTATION        Format string used to generate the
        %                   OperationString property when the Type is
        %                   IndexType.Dot  and IndexArgument is a valid
        %                   variable name.
        DotNotation(1, 1) string = ".%s"

        %DOTQUOTENOATION    Format string used to generate the
        %                   OperationString property when Type is
        %                   IndexType.Dot and IndexArgument is an invalid
        %                   variable name.
        DotQuoteNotation(1, 1) string = ".(""%s"")"

        %BRACESNOTATION     Format string used to generate the
        %                   OperationString property when Type is
        %                   IndexType.Braces.
        BracesNotation(1, 1) string = "{%u}"

        %PARENSNOATION      Format string used to generate the
        %                   OperationString property when Type is
        %                   IndexType.Parens.
        ParensNotation(1, 1) string = "(%u)"
    end

    methods
        function obj = IndexOperation(indexType, indexArgument)
            obj.Type = indexType;
            obj.IndexArgument = indexArgument;
        end

        function result = get.OperationString(obj)
            import matlab.io.internal.arrow.error.IndexType
            switch(obj.Type)
              case IndexType.Dot
                result = getDotOperationString(obj);
              case IndexType.Braces
                result = getBracesOperationString(obj);
              case IndexType.Parens
                result = getParensOperationString(obj);
            end
        end

        function obj = set.IndexArgument(obj, indexArgument)
            import matlab.io.internal.arrow.error.IndexType

            if obj.Type == IndexType.Dot %#ok<MCSUP>
                validateattributes(indexArgument, "string", "scalartext");
            else
                validateattributes(indexArgument, "double", ["scalar", "integer", "positive"]);
            end

            obj.IndexArgument = indexArgument;
        end
    end

    methods(Access = private)
        function result = getDotOperationString(obj)
            if isvarname(obj.IndexArgument)
                result = sprintf(obj.DotNotation, obj.IndexArgument);
            else
                % IndexArgument is not a valid variable name. Must wrap
                % IndexArgument with quotation marks and parentheses.
                result = sprintf(obj.DotQuoteNotation, obj.IndexArgument);
            end
        end

        function result = getBracesOperationString(obj)
            result = sprintf(obj.BracesNotation, obj.IndexArgument);
        end

        function result = getParensOperationString(obj)
            result = sprintf(obj.ParensNotation, obj.IndexArgument);
        end
    end
end
