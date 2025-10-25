function stringArrayWidths = getStringArrayWidth(stringArray, displayConfiguration, isWidthConstrainedDataRepresentation)
% Compute the widths of each of the elements in stringArray if: 1) the
% input string array is not a row vector or this function is called from
% widthConstrainedDataRepresentation. Otherwise, avoid making unecessary
% calls to the ICU library which can be expensive in terms of performance

% Copyright 2020-2021 The MathWorks, Inc.
arguments
    stringArray string
    displayConfiguration (1,1) matlab.display.DisplayConfiguration
    isWidthConstrainedDataRepresentation (1,1) logical = false;
end
if isrow(stringArray) && ~isWidthConstrainedDataRepresentation
    % If the input stringArray is a row vector and this function is
    % not called from widthConstrainedDataRepresentation, alignment
    % rules  or width considerations don't apply. It is ok to populate
    % width vectors with zeros. No need to call into the ICU libraries
    % to compute the width of each element in the array. Calling into
    % the ICU libraries is expensive in terms of performance. We should
    % avoid calling into them if it is not necessary
    stringArrayWidths = zeros(size(stringArray));
else
    % If the input stringArray has more than one row or this function is
    % called from widthConstrainedDataRepresentation, alignment rules
    % need and width considerations apply. Alignment rules need to
    % identify the widest elements in each column to be able to align
    % columns properly. Thus, it is necessary to call into the ICU
    % libraries here to get the width of each of the elements in
    % stringArray
    stringArrayWidths = characterWidthForStringArray(displayConfiguration, stringArray);
end
end