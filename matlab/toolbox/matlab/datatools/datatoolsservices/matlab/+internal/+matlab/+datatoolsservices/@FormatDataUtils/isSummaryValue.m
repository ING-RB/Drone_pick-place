% if the cell contents consist of more than a pre-defined number of display
% elements, then the contents are rendered as a summary value 
% Ex : c{1} = [1;2;3;4;5;6;7;8;9;1;2;3] is displayed as 1x12 double
% in the variable editor

% Copyright 2015-2023 The MathWorks, Inc.

function isSummary = isSummaryValue(data)
    import internal.matlab.datatoolsservices.FormatDataUtils;
    isSummary = ~(numel(data) < FormatDataUtils.MAX_DISPLAY_ELEMENTS && ndims(data) <= FormatDataUtils.MAX_DISPLAY_DIMENSIONS);
end
