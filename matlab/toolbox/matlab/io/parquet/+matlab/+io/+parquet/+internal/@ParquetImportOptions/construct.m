function obj = construct(args)
%construct   Construct a ParquetImportOptions from args.

%   Copyright 2022 The MathWorks, Inc.
    arguments
        args (1, 1) struct
    end

    obj = matlab.io.parquet.internal.ParquetImportOptions();

    [obj, args] = setOption(obj, args, "ArrowTypeConversionOptions");
    [obj, args, suppliedParquetFileVariableNames] = setOption(obj, args, "ParquetFileVariableNames");

    args = changeNormalizedNameFieldToOriginalName(args, "VariableNames");
    args = changeNormalizedNameFieldToOriginalName(args, "SelectedVariableNames");
    args = changeNormalizedNameFieldToOriginalName(args, "RowFilter");

    % Construct a TabularBuilder. Don't preserve variable names by default,
    % for compatibility.
    args = namedargs2cell(args);
    obj.TabularBuilder = matlab.io.internal.common.builder.TabularBuilder("PreserveVariableNames", false, args{:});

    if suppliedParquetFileVariableNames
        % Must match the length of VariableNames.
        Nactual = numel(obj.ParquetFileVariableNames);
        Nexpected = numel(obj.TabularBuilder.VariableNames);
        if Nactual ~= Nexpected
            error(message("MATLAB:io:common:builder:NumberOfVariablesMustBeConstant", Nactual));
        end
    else
        % If ParquetFileVariableNames were not supplied, set them equal to
        % VariableNames to avoid errors due to SelectedVariableIndices not
        % being able to index into ParquetFileVariableNames if its an empty array.
        obj.ParquetFileVariableNames = obj.TabularBuilder.VariableNames;
    end
end

% Change the names of args that need original variable names instead of
% normalized names.
function S = changeNormalizedNameFieldToOriginalName(S, name)
    if isfield(S, name)
        S.("Original" + name) = S.(name);
        S = rmfield(S, name);
    end
end

% Sets a property on the opts without any validation.
function [obj, args, supplied] = setOption(obj, args, name)
    supplied = isfield(args, name);
    if supplied
        obj.(name) = args.(name);
        args = rmfield(args, name);
    end
end
