function [c,ia,ib] = setxor(a,b,varargin)
%

%   Copyright 2012-2024 The MathWorks, Inc.

if nargin < 3
    flag = 'sorted';
else
    narginchk(2,5); % high=5, to let setmembershipFlagChecks sort flags out
    flag = tabular.setmembershipFlagChecks(varargin{:});
end

[ainds,binds] = tabular.table2midx(a,b);

% Calling setxor with either 'sorted' or 'stable' gives occurrence='first'
[d,ia,ib] = setxorLocal(ainds,binds,flag,'rows');
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
function [d,ia,ib] = setxorLocal(a,b,order,~)
% The main function doesn't actually need the rows themselves, since those
% are just dummy indices anyway.  It needs to know which of the two inputs
% each row of the xor "came from", so rather than returning the rows, this
% local function returns a logical indicating rows of the result that came
% from the second input (true), or from the first (false).

% Make sure a and b contain unique elements.
[uA,ia] = unique(a,'rows',order);
[uB,ib] = unique(b,'rows',order);

catuAuB = [uA;uB];                    % Sort [uA;uB] in order to find matching entries
[sortuAuB,indSortuAuB] = sortrows(catuAuB);
d = find(all(sortuAuB(1:end-1,:)==sortuAuB(2:end,:),2));    % d indicates the location of matching entries
indSortuAuB([d;d+1]) = [];                                  % Remove all matching entries - indSortuAuB only contains elements not in intersect
if order == "stable"
    indSortuAuB = sort(indSortuAuB);  % Sort the indices to get 'stable' order
end

n = size(uA,1);
d = indSortuAuB > n;           
ia = ia(indSortuAuB(~d,1),1);      % Find indices in indSortuAuB that belong to A 
ib = ib(indSortuAuB(d,1)-n,1);     % Find indices in indSortuAuB that belong to B

