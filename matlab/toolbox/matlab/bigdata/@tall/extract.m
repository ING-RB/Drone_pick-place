function s = extract(str,pat)
%EXTRACT Extract substrings from tall string arrays.
%   S = EXTRACT(STR, PAT)
%
%   Limitations:
%   If PAT is an array of pattern objects, the size of the first dimension
%   of the array must be 1.
%
%   See also TALL/STRING.

%   Copyright 2016-2023 The MathWorks, Inc.

narginchk(2,2);

% First input must be tall string.
tall.checkIsTall(upper(mfilename), 1, str);
str = tall.validateType(str, mfilename, {'string'}, 1);

% Treat all inputs element-wise, wrapping char arrays if used
pat = wrapPositionInput(pat, 2);
s = elementfun(@extract, str, pat);

% Output is always the same size and type as the first input.
s.Adaptor = str.Adaptor;
end
