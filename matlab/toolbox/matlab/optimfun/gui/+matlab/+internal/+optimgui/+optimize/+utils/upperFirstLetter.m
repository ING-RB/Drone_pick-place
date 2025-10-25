function upperFirstLetterChar = upperFirstLetter(originalChar)

% This function accepts a char and returns it with the first letter capitalized
%
% INPUTS:
%   originalChar (1, :) char - Original char
%
% OUTPUTS:
%   upperFirstLetterChar (1, :) char - First letter of original char capitalized

% Copyright 2020 The MathWorks, Inc.

upperFirstLetterChar = replaceBetween(originalChar, 1, 1, upper(originalChar(1)));
end
