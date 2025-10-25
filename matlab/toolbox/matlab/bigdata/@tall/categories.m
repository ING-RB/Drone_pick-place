function ts = categories(ta, varargin)
%CATEGORIES Get a list of a tall categorical array's categories.
%   S = CATEGORIES(A)
%
%   Limitations:
%   'OutputType' name-value argument is not supported.
%
%   See also CATEGORICAL/CATEGORIES.

%   Copyright 2016-2023 The MathWorks, Inc.

narginchk(1, 3);
ta = tall.validateType(ta, upper(mfilename), {'categorical'}, 1);

if nargin > 1
    error(message("MATLAB:bigdata:array:CategoriesUnsupportedOutputType", "tall"));
end

% We can use the categories stored in the first non-empty chunk because
% tall/categorical enforces that all chunks have the same categories. But
% only if the array is non-empty. Empty categorical arrays get "{}" rather
% than "cell.empty(0,1)".
tEmptyA = head(ta, 1);
ts = clientfun(@iCategories, tEmptyA, size(ta));
% Always return a cell array. We can't set any size information though.
ts = setKnownType(ts, 'cell');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ts = iCategories(catArray, catSize)
ts = categories(catArray);
if isempty(ts) && isequal(catSize, [0 0])
    ts = {};
end
end
