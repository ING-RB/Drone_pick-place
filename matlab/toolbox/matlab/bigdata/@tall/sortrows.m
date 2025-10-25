function [tY, tI] = sortrows(tX, varargin)
%SORTROWS  Sort rows in ascending order.
%   Supported syntaxes for tall array X:
%   Y = SORTROWS(X)
%   Y = SORTROWS(X,COL)
%   Y = SORTROWS(X,DIRECTION)
%   Y = SORTROWS(X,COL,DIRECTION)
%   Y = SORTROWS(X,...,'ComparisonMethod',C)
%   Y = SORTROWS(X,...,'MissingPlacement',M)
%   [Y,I] = SORTROWS(...)
%
%   Supported syntaxes for tall table/timetable T:
%   Y = SORTROWS(T,VARS)
%   Y = SORTROWS(T,VARS,DIRECTION)
%   [Y,I] = SORTROWS(...)
%
%   Limitations:
%   Sorting by row names is not supported.
%
%   See also SORTROWS, TABLE/SORTROWS, TALL.

%   Copyright 2016-2023 The MathWorks, Inc.

nargoutchk(0, 2);

tall.checkIsTall(upper(mfilename), 1, tX);
tall.checkNotTall(upper(mfilename), 1, varargin{:});

validateSortrowsSyntax(@sortrows, ...
    'MATLAB:table:sortrows:EmptyRowNames', ...
    'MATLAB:bigdata:array:SortrowsUnsupportedRowNames', ...
    tX, varargin{:});

inputArgs = varargin;
sortFunctionHandle = @(x) sortrows(x, inputArgs{:});
if nargout > 1
    tIdx = getAbsoluteSliceIndices(tX);
    [tY, tI] = sortCommon(sortFunctionHandle, tX, tIdx);
else
    tY = sortCommon(sortFunctionHandle, tX);
end
