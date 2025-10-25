% Convenience function to call formatDataBlockForMixedView with a single value.

% Copyright 2015-2023 The MathWorks, Inc.

function [renderedData, renderedDims, metaData] = formatSingleDataForMixedView(this, currentData, currentFormat)
    arguments
        this
        currentData
        currentFormat = internal.matlab.datatoolsservices.FormatDataUtils.getCurrentNumericFormat();
    end
    [renderedData, renderedDims, metaData] = ...
        this.formatDataBlockForMixedView(1, 1, 1, 1, {currentData}, currentFormat);
end
