function out = erase(in,matchStr)
%ERASE Delete substrings within strings.
%   S = ERASE(STR,MATCH)
%
%   STR must be a tall string array or tall cell array of char vectors.
%
%   See also ERASE, TALL/STRING.

%   Copyright 2016-2024 The MathWorks, Inc.

narginchk(2,2);

% First input must be tall string. Second must be local.
tall.checkIsTall(upper(mfilename), 1, in);
tall.checkNotTall(upper(mfilename), 1, matchStr);

in = tall.validateType(in, mfilename, {'string','cellstr'}, 1);

% Element-wise in the first input
out = elementfun(@(x) erase(x,matchStr), in);

% Output is same size and type as first input (can be cellstr or string)
out.Adaptor = in.Adaptor;
end
