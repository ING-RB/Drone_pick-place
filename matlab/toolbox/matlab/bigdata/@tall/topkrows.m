function [tY, tI] = topkrows(tX, k, varargin)
%TOPKROWS  Top k sorted rows of a matrix, table, or timetable.
%    Supported syntaxes for tall array X:
%    Y = topkrows(X,K)
%    Y = topkrows(X,K,COL)
%    Y = topkrows(X,K,COL,DIRECTION)
%    [Y,I] = topkrows(X,...)
% 
%    Supported syntaxes for tall table/timetable T:
%    Y = topkrows(T,K)
%    Y = topkrows(T,K,VARS)
%    Y = topkrows(T,K,VARS,DIRECTION)
%    [Y,I] = topkrows(T,...)
% 
%    Limitations:
%    1) The 'ComparisonMethod' name-value pair is not supported.
%    2) The 'RowNames' option for tables is not supported.
%
%   See also: SORTROWS, TALL.

% Copyright 2016-2023 The MathWorks, Inc.

narginchk(2,4);
nargoutchk(0,2);

% Check that k is a non-negative integer-valued scalar
validateattributes(k, ...
    {'numeric'}, {'real','scalar','nonnegative','integer'}, ...
    'topkrows', 'k')

isTallTable = istall(tX) && ismember(tall.getClass(tX), {'table', 'timetable'});

% Col list must be an integer-valued vector
colflag = false;
if nargin < 3
    if isTallTable
        col = getDefaultTableCols(tX);
    else
        col = [];
        colflag = true; % setting flag for all columns to true 
    end
else
    col = varargin{1};
    if isTallTable
        if ischar(col) && isrow(col)
            col = {col}; % Ensure abitrary table variable names are supported 
        elseif islogical(col) || isstring(col) || iscellstr(col)
            % Nothing to do
        elseif isa(col, "pattern")
            % Convert pattern into numeric
            [~, col] = matlab.bigdata.internal.util.resolveTableVarSubscript( ...
                tX.Adaptor.getVariableNames(), col);
        elseif ~isempty(col)
            iValidateCols(col, true); % Only support positive integers
        end
    else
        [tX, col] = iResolveMatrixCols(tX, col);
    end
end

if nargin < 4 || isempty(varargin{2}) % allow empty strings to work as default
    % Default to descending order
    sortDirn = {'descend'};
else
    sortDirn = varargin{2};
end

% Validate direction has valid options
iValidateSortDirection(sortDirn, isTallTable);

validateSortrowsSyntax(@(x, varargin) topkrows(x, k, varargin{:}) , ...
    'MATLAB:table:topkrows:EmptyRowNames', ...
    'MATLAB:bigdata:array:SortrowsUnsupportedRowNames', ...
    tX, col, sortDirn);

% Call reducefun with correct function based on type
if k > matlab.bigdata.internal.lazyeval.maxSlicesForReduction()
    % Too much data for a block based reduction. Use SORTROWS and HEAD
    % instead.
    if colflag
        % All columns
        sortArgs = {sortDirn};
    else
        sortArgs = {col, sortDirn};
    end
    if nargout>1
        [tY, tI] = sortrows(tX, sortArgs{:});
        tY = head(tY, k);
        tI = head(tI, k);
    else
        tY = sortrows(tX, sortArgs{:});
        tY = head(tY, k);
    end
else
    % Small result - use an efficient reduction
    if nargout > 1
        sliceIds = getAbsoluteSliceIndices(tX);
        [tY,tI] = reducefun(@(x,idx) iSelectTopKRowsWithIds(x, idx, k, col, sortDirn, colflag), tX, sliceIds);
    else
        tY = reducefun(@(x) iSelectTopKRows(x, k, col, sortDirn, colflag), tX);
    end
end

% Output adaptor is always same type and small size as input. Try and
% deduce tall size (probably k).
TALL_DIM = 1;
tY.Adaptor = topkReductionAdaptor(tX, k, TALL_DIM);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function col = getDefaultTableCols(tx)
if strcmp(tall.getClass(tx), 'table')
    col = getVariableNames(tx.Adaptor);
else
    % For tall timetable, default is sort-by-time
    actualDimNames = getDimensionNames(tx.Adaptor);
    col = actualDimNames(1);
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function iValidateCols(col, istabular)
% Check that col is either [] or a valid index vector
if ~isequal(col,[]) && ...
        (~isnumeric(col) || ~isvector(col) || ~isreal(col) ...
        || any(floor(col)~=col) || any(col<1))
    if istabular
        error(message('MATLAB:table:topkrows:BadNumericVarIndices'));
    else
        error(message('MATLAB:topkrows:ColNotIndexVec'));
    end
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [tx, col] = iResolveMatrixCols(tx, col)
iValidateCols(col, false);
% Also, lazily check that none is out of range (need size of TX)
tx = lazyValidate(tx, {@(x) all(abs(col)<=size(x,2)), 'MATLAB:topkrows:ColNotIndexVec'});
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function sortDirn = iValidateSortDirection(sortDirn, istabular)
sortDirnStrs = {'descend','ascend'};
if istabular
    errID = 'MATLAB:table:topkrows:UnrecognizedMode';
else
    errID = 'MATLAB:topkrows:NumDirectionsFourth';
end

if ~isempty(sortDirn)
    if ischar(sortDirn)
        sortDirn = cellstr(sortDirn);
    elseif ~(iscellstr(sortDirn) || isstring(sortDirn))
        error(message(errID));
    end
    tf = any(startsWith(sortDirnStrs, sortDirn(:), 'IgnoreCase', true));
    if ~tf
        error(message(errID));
    end
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function out = iSelectTopKRows(x, k, col, sortDirn, colflag)
% Function to run on each chunk, keeping at most k rows

if colflag
    col = 1:size(x,2);
end

out = topkrows(x,k,col,sortDirn);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [out, idx] = iSelectTopKRowsWithIds(x, sliceIds, k, col, sortDirn, colflag)
% Function to run on each chunk, keeping at most k rows

if colflag
    col = 1:size(x,2);
end

[out, idx] = topkrows(x,k,col,sortDirn);

% Map absolute indices in sliceIds according to the order in idx.
idx = sliceIds(idx);
end