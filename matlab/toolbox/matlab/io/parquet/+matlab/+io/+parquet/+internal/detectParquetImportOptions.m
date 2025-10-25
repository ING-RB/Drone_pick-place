function [opts, reader] = detectParquetImportOptions(filename, args)
%detectParquetImportOptions   Generates a ParquetImportOptions object from
%   an input filename.
%
%   The default import strategy is:
%    - Read all variables in the file (SelectedVariableNames is set to VariableNames).
%    - Read all the rows in the file (RowFilter is set to rowfilter(missing)).
%    - Read a table, not a timetable (OutputType is set to "table").
%    - Read using normalized variable names, not the original variable names (VariableNamingRule="modify").
%
%   You can change all these defaults by providing N-V pairs to
%   this function.

%   Copyright 2022 The MathWorks, Inc.

    arguments
        filename
        args.?matlab.io.parquet.internal.ParquetImportOptions
    end

    reader = matlab.io.parquet.internal.makeParquetReadCacher(filename);

    % Handle a VariableNames override if a user provided one.
    args = overrideVariableNames(args, reader.InternalReader);

    % Build a ParquetImportOptions using this info.
    import matlab.io.parquet.internal.ParquetImportOptions
    args = namedargs2cell(args);
    opts = ParquetImportOptions("ParquetFileVariableNames", reader.InternalReader.VariableNames, ...
                                "VariableTypes", reader.InternalReader.VariableTypes, args{:});

    % Also disable the type check if logical/integer promotion is enabled.
    opts = removeTypeCheck(opts);
end

function args = overrideVariableNames(args, reader)
    import matlab.io.parquet.internal.validators.validateNumVariableNames

    if isfield(args, "VariableNames")
        % Error if the number of VariableNames has changed.
        args.VariableNames = validateNumVariableNames(args.VariableNames, reader);
    else
        args.VariableNames = reader.VariableNames;
    end
end

function opts = removeTypeCheck(opts)
    % Integer promotion can cause a datatype change. So mlarrow could
    % decide to convert int32 to double during reading.

    % Look at the ArrowTypeConversionOptions and remove any VariableTypes
    % checks that include logical or integer if double promotion is
    % enabled.
    logicalPromotionEnabled = opts.ArrowTypeConversionOptions.LogicalTypeConversionOptions.CastToDouble;
    integerPromotionEnabled = opts.ArrowTypeConversionOptions.IntegerTypeConversionOptions.CastToDouble;

    if logicalPromotionEnabled
        logicalVariables = matches(opts.VariableTypes, "logical");
        opts.VariableTypes(logicalVariables) = missing;
    end

    if integerPromotionEnabled
        integerTypes = ["u" ""] + "int" + [8 16 32 64]';
        integerVariables = matches(opts.VariableTypes, integerTypes);
        opts.VariableTypes(integerVariables) = missing;
    end
end