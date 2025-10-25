function DimensionNames = mustBeValidDimensionNames(DimensionNames)
%mustBeValidDimensionNames   Property/arguments validation for DimensionNames.
%

%   Copyright 2022 The MathWorks, Inc.

    DimensionNames = convertCharsToStrings(DimensionNames);

    mustBeNonmissing(DimensionNames);

    attributes = {'2d', 'numel', 2};
    validateattributes(DimensionNames, "string", attributes, "TableBuilder", "DimensionNames");

    DimensionNames = reshape(DimensionNames, 1, 2);
end
