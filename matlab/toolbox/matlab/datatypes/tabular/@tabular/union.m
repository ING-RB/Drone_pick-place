function [c,ia,ib] = union(a,b,varargin)
%

%   Copyright 2012-2024 The MathWorks, Inc.

if nargin < 3
    flag = 'sorted';
else
    narginchk(2,5); % high=5, to let setmembershipFlagChecks sort flags out
    flag = tabular.setmembershipFlagChecks(varargin{:});
end

[ainds,binds] = tabular.table2midx(a,b);

% Calling union with either 'sorted' or 'stable' gives occurrence='first'
[d,ia,ib] = unionLocal(ainds,binds,flag,'rows');
aa = a(ia,:);
bb = b(ib,:);

if flag == "sorted"
    ord(~d) = 1:length(ia);
    ord(d) = length(ia) + (1:length(ib));
    iord(ord) = 1:length(ord);
    
    % vertcat would create unique default row names for aa or bb if necessary, but
    % after reordering for 'sorted', they'd have the wrong row number suffixes.
    % Create the right ones in advance.
    if aa.rowDim.hasLabels
        if ~bb.rowDim.hasLabels
            rowLabels = bb.rowDim.defaultLabels(iord(length(ia) + (1:length(ib))));
            bb.rowDim = bb.rowDim.setLabels(rowLabels);
        end
    elseif bb.rowDim.hasLabels % && ~a.rowDim.hasLabels
        rowLabels = bb.rowDim.defaultLabels(iord(1:length(ia)));
        aa.rowDim = aa.rowDim.setLabels(rowLabels);
    end
end

c = [aa; bb]; % automatically merges the properties

if flag == "sorted"
    c = c(ord,:);
end

%-----------------------------------------------------------------------
function [d,ia,ib] = unionLocal(a,b,order,~)
% The main function doesn't actually need the rows themselves, since those
% are just dummy indices anyway.  It needs to know which of the two inputs
% each row of the union "came from", so rather than returning the rows,
% this local function returns a logical indicating rows of the result that
% came from the second input (true), or from the first (false).
[~,ndx] = unique([a;b],order,'rows');
n = size(a,1);
d = ndx > n;
ia = ndx(~d,1);
ib = ndx(d,1) - n;
