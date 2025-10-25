function [matchings, unassignedRows, unassignedCols] = ...
    matchpairs(Cost, costUnmatched, goal)
%MATCHPAIRS Linear assignment problem.
%   matchings = MATCHPAIRS(Cost, costUnmatched) solves the linear
%   assignment problem for the rows and columns of the Cost matrix. Each
%   row is assigned to a column in such a way that the global cost is
%   minimized. The scalar costUnmatched specifies the cost of not assigning
%   a row to a column, or a column to a row, at all.
%
%   [matchings, unassignedRows, unassignedCols] = MATCHPAIRS(Cost, costUnmatched)
%   additionally returns all rows and columns that remain unmatched.
%   
%   [___] = MATCHPAIRS(Cost, costUnmatched, GOAL) specifies the goal of the optimization.
%   GOAL can be:
%       'min' - minimize the global cost (default)
%       'max' - maximize the global cost
%
%   The global cost is defined as
%   
%      p
%     sum Cost(matchings(i,1), matchings(i,2)) + costUnmatched * (m+n-2*p)
%     i=1
%
%   where:  * Cost is an m-by-n matrix
%           * matchings is a p-by-2 matrix, where matchings(i,1) and 
%             matchings(i,2) are the row and column of a matched pair
%           * c = cost of not matching (costUnmatched)
%
%   Example:
%   % Compute a matching between a set of 2 points and another set of 3
%   % points.
%   oldxy = [1,1; 2,2];
%   newxy = [2.1 1.9; 3 1.5; 1.1, 1.1];
%
%   % Calculate the distance between each pair of points.
%   for i=1:2
%       for j=1:3
%           dist(i, j) = norm(oldxy(i, :) - newxy(j, :));
%       end
%   end
%
%   % Compute the minimum-cost matching between the rows and columns in the distance matrix.
%   match = matchpairs(dist, 1)
%
%   See also EQUILIBRATE.

%   Copyright 2018-2020 The MathWorks, Inc.
%
%   Reference:
%   I.S. Duff and J. Koster. "On Algorithms For Permuting Large Entries
%   to the Diagonal of a Sparse Matrix."
%   SIAM J. Matrix Anal. & Appl., 22(4), 973-996, 2001.

if ~isfloat(Cost) || ~isreal(Cost) || ~ismatrix(Cost) || isobject(Cost)
    error(message('MATLAB:matchpairs:InvalidCost'));
elseif any(isnan(Cost), 'all')
    error(message('MATLAB:matchpairs:NonFiniteCost'));
end

if ~isfloat(costUnmatched) || ~isreal(costUnmatched) || ~isscalar(costUnmatched) || isobject(costUnmatched)
    error(message('MATLAB:matchpairs:InvalidCostUnmatched'));
elseif ~isfinite(costUnmatched)
    error(message('MATLAB:matchpairs:NonFiniteCostUnmatched'));
end

if nargin > 2
    if ~( (ischar(goal) && isrow(goal)) || (isstring(goal) && isscalar(goal)) )
        error(message('MATLAB:matchpairs:InvalidOption'));
    end
    ind = strncmpi(goal, {'min', 'max'}, max(strlength(goal), 1));
    if nnz(ind) ~= 1
        error(message('MATLAB:matchpairs:InvalidOption'));
    end
    minimize = ind(1);
else
    minimize = true;
end

if ~minimize
    Cost = -Cost;
    costUnmatched = -costUnmatched;
end

cls = 'double';
if isa(Cost, 'single') && isa(costUnmatched, 'single')
    cls = 'single';
end

% Create a larger cost matrix, with dummy rows and columns
% to account for the possibility of not matching.
[m, n] = size(Cost);

% If costUnmatched is less than or equal to zero, the zero elements
% in C can safely be treated as if they were Inf, because they will
% never be used in a matching. This allows us to construct a sparse
% padded matrix.
useSparse = issparse(Cost) & costUnmatched <= 0;

if ~useSparse
    paddedCost = Inf(m+n, m+n, cls);
    
    paddedCost(1:m, 1:n) = Cost;
    paddedCost(m+1:end, n+1:end) = Cost.';
    for ii=1:m
        paddedCost(ii, n+ii) = 2*costUnmatched;
    end
    for jj=1:n
        paddedCost(m+jj, jj) = 2*costUnmatched;
    end
    [colToRow, rowToCol] = matlab.internal.graph.perfectMatching(paddedCost);
else
    % Note: This treats structural zero as equivalent to Inf, which is okay if
    % costUnmatched is less than or equal to zero.
    [i, j, v] = find(Cost);
    nz = nnz(Cost);
    indC = sparse(i, j, 1:nnz(Cost), m, n);
    
    structPaddedCost = [indC, (nz+1)*speye(m, m); (nz+1)*speye(n, n), indC'];    
    vPadded = [v; 2*costUnmatched];
    nzPaddedCost = vPadded(nonzeros(structPaddedCost));
    
    [colToRow, rowToCol] = matlab.internal.graph.perfectMatching(structPaddedCost, nzPaddedCost);
end


if isempty(colToRow) && m+n > 0
    % No perfect matching found, must be because of an overflow inside 
    % perfectMatching. Rescale the matrix and try again.
    if ~useSparse
        maxVal = max(abs(paddedCost(isfinite(paddedCost))), [], 'all');
    else
        maxVal = max(abs(nzPaddedCost(isfinite(nzPaddedCost))));
    end
    
    scale = 2^-nextpow2(maxVal);
    
    if ~useSparse
        [colToRow, rowToCol] = matlab.internal.graph.perfectMatching(paddedCost * scale);
    else
        [colToRow, rowToCol] = matlab.internal.graph.perfectMatching(structPaddedCost, nzPaddedCost*scale);
    end
end
% r = colToRow(c) gives row r matched to column c.
% c = rowToCol(r) gives column c matched to row r.

% Check for ambiguous cases, where a pair can be matched or unmatched
% with no effect on the goal function. Set these cases to be unmatched:
for c=1:n
    r = colToRow(c);
    if r <= m && Cost(r, c) == 2*costUnmatched
        colToRow(c) = m+n+1;
        rowToCol(r) = m+n+1;
    end
end

% Real row matched to real column: a matched pair in matrix C.
matchedPairs = colToRow(1:n) <= m;
matchings = [colToRow(matchedPairs), find(matchedPairs)];
matchings = reshape(matchings, [], 2); % Correct size in empty case.

if nargout >= 2
    % Real row matched to dummy column: an unassigned row.
    unassignedRows = find(rowToCol(1:m) > n);
    unassignedRows = unassignedRows(:);
end

if nargout >= 3
    % Real column matched to dummy row: an unassigned column.
    unassignedCols = find(colToRow(1:n) > m);
    unassignedCols = unassignedCols(:);
end
