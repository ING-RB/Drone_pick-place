function partialDisp = getPartialDisplay(inputArr, availableWidth, isString, pad, stringArray, options)
%GETPARTIALDISPLAY Construct partial display of input array
%   Construct partial display of input array by iterating over each of the
%   elements in the array and concatenating them together with an ellipsis
%   at the end

%   Copyright 2021-2024 The MathWorks, Inc
arguments
    inputArr
    availableWidth (1,1) double
    isString (1,1) logical = false
    pad (1,1) string = "    ";
    stringArray (1, :) string = string(inputArr);
    options.includeRegex (1,1) logical = false;
    options.includeDimensionsAndClassNameAnnotation (1,1) logical = true;
end
doubleQuotes = """";
partialDisp = "";
partialDispWidth = 0;
stringArrWidth = computeStringArrayWidth(stringArray);
padWidth = strlength(pad);
% create the dimensions and class name annotation used in partial displays
dimsAndClassNameAnnotation = "";
if options.includeDimensionsAndClassNameAnnotation
    % dimsAndClassNameAnnotation will prepend the pad,
    % i.e, will look something like " (1x10 double)"
    dimsAndClassNameAnnotation = matlab.display.internal.getDimensionsAndClassNameAnnotation(inputArr, padding=" ", includeRegex=options.includeRegex);
end
% width added by brackets when performing a partial data display
openDataDelim = "[";
closeDataDelim = "]";
addedBracketWidth = strlength(openDataDelim) + strlength(closeDataDelim);

% Compute the width required to display the entire array
widthOfFullArray = sum(stringArrWidth) + padWidth*(numel(inputArr)-1) + addedBracketWidth;
% If the input array is a string, add the width string delimiters (i.e."")
% to the total width
if isString
    widthOfFullArray = widthOfFullArray + 2*numel(inputArr);
end
needsEllipsis = false;
if widthOfFullArray > availableWidth
    % If the entire array cannot be displayed in the available space,
    % ellipsis and padding needs to be considered
    % Subtract the width of (padding + ellipsis + padding + Annotation
    % + data delimiters) from the available width
    availableWidth = availableWidth - 2*padWidth - floor(matlab.internal.display.wrappedLength(matlab.display.internal.getEllipsisCharacter)) - matlab.internal.display.wrappedLength(dimsAndClassNameAnnotation) - addedBracketWidth;
    if options.includeRegex
        % add the space "removed" by the back-slashes
        availableWidth = availableWidth + 2;
    end
    needsEllipsis = true;
end
for i = 1:numel(inputArr)
    currentElemPartialDisp = "";
    if i > 1
        currentElemPartialDisp = currentElemPartialDisp + pad;
    end
    if isString
        currentElemPartialDisp = currentElemPartialDisp + doubleQuotes + stringArray(i) + doubleQuotes;
    else
        currentElemPartialDisp = currentElemPartialDisp + stringArray(i);
    end
    currentElemWidth = matlab.internal.display.wrappedLength(currentElemPartialDisp);
    if partialDispWidth + currentElemWidth <= availableWidth
        partialDisp = partialDisp + currentElemPartialDisp;
        partialDispWidth = partialDispWidth + currentElemWidth;
    else
        break;
    end
end
if options.includeRegex
        openDataDelim = "\[";
        closeDataDelim = "\]";
end
if needsEllipsis
    partialDisp = openDataDelim + partialDisp + pad + matlab.display.internal.getEllipsisCharacter + pad + closeDataDelim + dimsAndClassNameAnnotation;
else
    partialDisp = openDataDelim + partialDisp + closeDataDelim;
end
end

function widthArr = computeStringArrayWidth(stringArr)
widthArr = zeros(0, numel(stringArr));
for i=1:numel(stringArr)
    widthArr(i) = matlab.internal.display.wrappedLength(stringArr(i));
end
end