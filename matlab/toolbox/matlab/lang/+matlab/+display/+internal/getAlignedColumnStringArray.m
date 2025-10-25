function alignedArray = getAlignedColumnStringArray(stringArray, stringArrayWidths, maxWidthPerColumn, displayConfiguration, numColumns)
% Build a padded display string by iterating over each of
% the elements of the input stringArray and adding the appropriate
% inter-element padding in between each of the elements. For columnar
% layouts, additional inter-element padding may be required in order to
% align each of the columns in stringArray

% Copyright 2020-2021 The MathWorks, Inc.
arguments
    stringArray string
    stringArrayWidths double
    maxWidthPerColumn double
    displayConfiguration (1,1) matlab.display.DisplayConfiguration
    numColumns (1,1) double = size(stringArray,2)
end

numOfRows = size(stringArray,1);
alignedArray = strings(numOfRows, 1);
cumulativeError = zeros(numOfRows, 1);
pad = displayConfiguration.InterElementDelimiter;
for column = 1:numColumns
    % Determine the widest element in the column
    currentMaxWidth = maxWidthPerColumn(column);
    for row = 1:numOfRows
        currentWidth = stringArrayWidths(row, column);
        diffMaxAndCurrentWidth = currentMaxWidth - currentWidth;
        % Keep track of the fractional part of the character width to
        % account for misalignment due to the presence of full-width
        % characters (i.e. characters that have non-integer character
        % width)
        cumulativeError(row) = cumulativeError(row) + mod(diffMaxAndCurrentWidth,1);
        % Compute the padding that needs to be added to the current
        % element with respect to the widest element of the column
        padding = floor(diffMaxAndCurrentWidth);
        if cumulativeError(row) >= 1
            % If the cumuluative error due to full-width characters is
            % more than one, add this to the padding to compensate for
            % missalignment due to the fractional part of the widest
            % element in the column
            padding = padding + floor(cumulativeError(row));
            cumulativeError(row) = mod(cumulativeError(row),1);
        end
        if(column ~= numColumns)
            % All columns except for the last one, require the inter
            % element delimiter to be added in between each of the
            % elements of the array
            
            % Add additional spaces into the row, as specified by the
            % variable padding, to align each of the columns
            alignedArray(row) = alignedArray(row) + stringArray(row, column) + ...
                pad + repmat(' ', 1, padding);
        else
            % The last column doesn't require any inter-element
            % delimiter to be added
            alignedArray(row) = alignedArray(row) + stringArray(row, column) + ...
                repmat(' ', 1, padding);
        end
    end
end

if numColumns < size(stringArray, 2)
    % If the input number of columns is less than the number of columns
    % in the array, it means that partial data is being printed. Thus,
    % an ellipsis needs to be appended at the end
    alignedArray = alignedArray + pad + displayConfiguration.Ellipsis + pad;
end
end