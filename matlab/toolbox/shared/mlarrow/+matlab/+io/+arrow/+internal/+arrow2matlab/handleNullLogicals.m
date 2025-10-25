function logicalArray = handleNullLogicals(logicalArray, nullIndices, opts)
%HANDLENULLLOGICALS Handles replacing elements that correspond to null
% slots in an arrow::BooleanArray with the appropriate MATLAB type speciifc
% missing value depending on the LogicalTypeConversionOptions provided.

% Copyright 2022 The MathWorks, Inc.

arguments
        logicalArray % arrow2matlab validates the struct's fields
        nullIndices logical
        opts.LogicalTypeConversionOptions (1, 1) matlab.io.internal.arrow.conversion.LogicalTypeConversionOptions = ...
            matlab.io.internal.arrow.conversion.LogicalTypeConversionOptions();
    end

    if any(nullIndices)
        if opts.LogicalTypeConversionOptions.CastToDouble
            logicalArray = double(logicalArray);
        end
        logicalArray(nullIndices) = opts.LogicalTypeConversionOptions.NullFillValue;
    end
end

