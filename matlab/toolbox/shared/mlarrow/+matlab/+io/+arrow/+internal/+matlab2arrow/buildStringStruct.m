function [stringStruct, validStruct] = buildStringStruct(array)
%BUILDSTRINGSTRUCT 
%   Builds the struct array used to string arrays in the C++
%   layer.
%
% STRINGSTRUCT is a scalar struct.
%
% STRINGSTRUCT contains the following fields:
%
% Field Name    Class      Description
% ----------    ------     ----------------------------------------------
% Values        uint8      uint8 array representing the string data.
% StartOffsets  uint64     uint64 array whether the ith element represents
%                             the start position of the ith string in the
%                             array. StartOffsets lenght is 1 +
%                             strlenth(STRINGARRAY).
%
%
% VALIDSTRUCT is a scalar struct that represents STRINGARRAYS'S valid
% elements as a bit-packed logical array.
% 
% See matlab.io.arrow.internal.matlab2arrow.bitPackLogical for details
% about VALIDSTRUCT'S schema.

%   Copyright 2021-2022 The MathWorks, Inc.


    import matlab.io.arrow.internal.matlab2arrow.buildValidStruct
    import matlab.io.arrow.internal.convertUTF16ToUTF8

    array = normalizeZeroDimensionalChars(array);
   % stringArray = string(array); % normalize to string array.

    [values, startOffsets] = convertUTF16ToUTF8(array); 
    stringStruct = struct("Values", values, "StartOffsets", startOffsets);

    if isstring(array) || iscell(array)
        validStruct = buildValidStruct(array);
    else
        % char array cannot have null values. Use an empty double array to
        % generate the a validity bitmap that indicates there are zero 
        % null values.
        validStruct = buildValidStruct([]);
    end
end


% Handle edge-case with char to string conversion where
% a zero-by-zero char gets converted to a 1-by-1 string.
function stringArray = normalizeZeroDimensionalChars(stringArray)

    % Detect if the input is a char array with zero non-zero dimensions.
    if ischar(stringArray) && ~any(size(stringArray))
        % Replace 0-by-0 char with a 0-by-1 char, which gets converted to
        % a 0-by-1 string by the 'string' constructor.
        stringArray = char(zeros(0, 1));
    end
end
