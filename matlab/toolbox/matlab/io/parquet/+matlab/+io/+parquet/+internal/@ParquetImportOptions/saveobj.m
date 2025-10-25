function S = saveobj(obj)
%saveobj
%

%   Copyright 2022 The MathWorks, Inc.

    % Store save-load metadata.
    S = struct("EarliestSupportedVersion", 1);
    S.ClassVersion = obj.ClassVersion;

    % State properties
    S.TabularBuilder = obj.TabularBuilder;
    S.ParquetFileVariableNames = obj.ParquetFileVariableNames;
    S.ArrowTypeConversionOptions = obj.ArrowTypeConversionOptions;
end
