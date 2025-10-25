function truncatedStringArr = getTruncatedStringArray(strArray, width, displayConfiguration)
% Construct the truncated version of the input string array based on the
% input width. This function takes an array of strings and truncates each
% string so that its display width does not exceed the specified width. The
% truncation is done considering the display configuration provided.

% Copyright 2020-2025 The MathWorks, Inc.

arguments
    strArray string {mustBeColumn(strArray)}
    width (1,1) double
    displayConfiguration (1,1) matlab.display.DisplayConfiguration
end
    % Preallocate the output truncated string array
    truncatedStringArr = createArray(size(strArray,1),1,"string",FillValue="");

    for i = 1:size(strArray,1)
        % Truncate each string from the string array based on the specified
        % width
        truncatedStringArr(i,1) = getTruncatedStringBasedOnWidth(strArray(i),width, displayConfiguration);
    end
end

function widthOfWideUnicodeChar = getWidthOfWideChar()
    % Helper function to get the width of a wide Unicode character
    widthOfWideUnicodeChar = (1.0 + sqrt(5.0)) / 2.0;
end

function truncatedString = getTruncatedStringBasedOnWidth(str,availableWidth, displayConfiguration)
    % Helper function to truncate a string based on available width
    widthOfWideUnicodeChar = getWidthOfWideChar();
    lastIdx = str.strlength;
    if (lastIdx > availableWidth)
        % If the character width exceeds the specified width, update the last
        % index to truncate the string to fit within the specified width
        lastIdx = availableWidth;
    end
    
    widthOfSubString = characterWidthForStringArray(displayConfiguration, extractBetween(str,1,lastIdx));
    if widthOfSubString <= availableWidth
        % If the width of the substring is same as the specied width, we
        % can return early.
        % Note: This happens if the input string contains only non-wide
        % unicode characters which is a more common occurence.
        truncatedString = extractBetween(str,1,lastIdx);
        return;
    end
    
    % If we reach here, it indicates that the width of the substring from
    % 1:availableWidth is greater than the specified width, indicating the
    % presence of wide Unicode characters in the input string.
    % We need further processing in this scenario.
    
    % The number of wide characters that can fit in the specified width.
    % This is the maximum number of wide characters that can be accomodated
    % in the specified width.
    numWideCharsThatCanFitInWidth = floor(availableWidth/widthOfWideUnicodeChar);
    
    for i = numWideCharsThatCanFitInWidth : availableWidth
        % If the string has a combination of wide and non-wide Unicode
        % characters, this for-loop will ensure we fit maximum number of
        % characters in the specified width.
        widthOfStringWithWideChars = characterWidthForStringArray(displayConfiguration, extractBetween(str,1,i));
        if widthOfStringWithWideChars > availableWidth
            lastIdx = i - 1;
            break;
        end
    end
    % Formulate the truncated string using the lastIdx
    truncatedString = extractBetween(str,1,lastIdx);
end