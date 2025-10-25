function output = inHexRange(testChar, hexStartVal, hexEndVal)
%

% Copyright 2020 The MathWorks, Inc.
    decFirstNameChar = uint32(testChar);
    output = decFirstNameChar >= hexStartVal && decFirstNameChar <= hexEndVal;
end