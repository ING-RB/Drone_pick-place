function variableEncoding = validateVariableEncoding(schema, variableEncoding)
%validateVariableEncodings   validates the VariableEncodings name-value
%argument.
%
% NOTE: The "dictionary" variable encoding cannot be applied to a
% arrow::BooleanArray column or a column containing an
% arrow::BooleanArray, e.g. list<boolean>, struct<fieldname: boolean>.
%
% By default, parquetwrite uses the encoding "dictonary" for all columns
% that are not arrow::BooleanArrays or do not contain arrow::BooleanArrays.
% For those columns, the encoding is set to "plain". However, if
% VariableEncoding is supplied as "dictionary" for an arrow::BooleanArray
% column or a column that contains an arrow::BooleanArray, parquetwrite
% errors.

% Copyright 2022, The MathWorks Inc.
    arguments
        schema(1, 1) matlab.io.internal.arrow.schema.TableSchema;
        variableEncoding
    end

    import matlab.io.parquet.internal.validatePerVariableOption;

    % Validates variableEncoding is a string array containing only these
    % values: "auto", "plain", "dictionary"
    variableEncoding = validatePerVariableOption(schema.ColumnNames,...
        "VariableEncoding", variableEncoding, @iValidateEncoding);


    visitor = matlab.io.internal.arrow.schema.HasTypeVisitor("logical");

    % Validate the variableEncoding value for Parquet boolean columns-or
    % columns containing Parquet boolean data-is not "dictionary".
    % The MATLAB logical datatype is the corresponding datatye for the
    % Parquet boolean type.
    for ii = 1:schema.NumColumns
        foundLogical = visitor.visit(schema.ColumnDataTypes(ii)); 
        if foundLogical && variableEncoding(ii) == "dictionary"
            errId = "MATLAB:parquetio:write:UnsupportedDictionaryEncoding";
            error(message(errId, schema.ColumnNames(ii)));
        end
    end

    % Resolve "auto" to "dictionary" as the default encoding strategy.
    % The native parquet library enforces that plain encoding is used for
    % any MATLAB logical variables.
    variableEncoding(variableEncoding == "auto") = "dictionary";
end

%--------------------------------------------------------------------------
function e = iValidateEncoding(e)
    allowedOpts = ["auto", "dictionary", "plain"];
    e = validatestring(e, allowedOpts, "parquetio:write", "VariableEncoding");
end