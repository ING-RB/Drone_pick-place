function obj = loadobj(S)
%loadobj

%   Copyright 2022 The MathWorks, Inc.

    if isfield(S, "EarliestSupportedVersion")
        % Error if we are sure that a version incompatibility is about to occur.
        if S.EarliestSupportedVersion > matlab.io.parquet.internal.ParquetImportOptions.ClassVersion
            error(message("MATLAB:io:common:validation:UnsupportedClassVersion"));
        end
    end

    obj = matlab.io.parquet.internal.ParquetImportOptions();

    % Override with the actual options.
    obj.TabularBuilder = S.TabularBuilder;
    obj.ParquetFileVariableNames = S.ParquetFileVariableNames;
    obj.ArrowTypeConversionOptions = S.ArrowTypeConversionOptions;
end
