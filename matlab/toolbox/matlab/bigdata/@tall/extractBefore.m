function s = extractBefore(str,endStr)
%EXTRACTBEFORE Create a string from part of a larger string.
%   S = EXTRACTBEFORE(STR, END)
%
%   Limitations:
%   If END is an array of pattern objects, the size of the first dimension
%   of the array must be 1.
%
%   See also TALL/STRING.

%   Copyright 2016-2023 The MathWorks, Inc.

narginchk(2,2);

% First input must be tall string.
tall.checkIsTall(upper(mfilename), 1, str);
str = tall.validateType(str, mfilename, {'string'}, 1);

% Treat all inputs element-wise, wrapping char arrays if used
endStr = wrapPositionInput(endStr, 2);
s = elementfun(@extractBefore, str, endStr);

% Output is always the same size and type as the first input.
s.Adaptor = str.Adaptor;
end
