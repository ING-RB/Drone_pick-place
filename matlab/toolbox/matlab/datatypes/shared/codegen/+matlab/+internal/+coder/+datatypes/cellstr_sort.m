function [sorted,idx] = cellstr_sort(c,direction)
%CELLSTR_SORT Sort a cellstr in ascending or descending order.
%   CELLSTR_SORT implements sort for cellstr inputs in codegen. Assumes
%   C is a homogeneous cell column vector containing char row vectors.
%   Uses coder.internal.introsort to sort. This sort is not stable.

%   Copyright 2018-2020 The MathWorks, Inc.

%#codegen

if nargin < 2 || strncmpi('ascend',direction,max(length(direction),1))
    cmpFun = @lt;
else
    % Ensure that the direction is either ascend or descend
    coder.internal.assert(strncmpi('descend',direction,max(length(direction),1)),...
        'MATLAB:sortrows:DIRnotRecognized');
    cmpFun = @gt;
end
    
ONE = coder.internal.indexInt(1);
nc = coder.internal.indexInt(numel(c));
idx = (1:nc)';
idx = coder.internal.introsort(idx,ONE,nc,@(i,j)sortidxCmp(i,j,c,cmpFun));
%x = x{idx};
sorted = coder.nullcopy(cell(size(c)));
for i = 1:numel(sorted)
    sorted{i} = c{idx(i)};
end

%--------------------------------------------------------------------------

function p = sortidxCmp(i,j,x,cmpFun)
% this implements LT/GT comparison for char arrays
coder.inline('always');
xi = x{i};
xj = x{j};
n = min(numel(xi),numel(xj));
p = cmpFun(numel(xi),numel(xj));
for k = 1:n
    xiChar = xi(k);
    xjChar = xj(k);
    if xiChar ~= xjChar
        p = cmpFun(xiChar,xjChar);
        return;
    end
end
% force the sort order to be stable
if numel(xi) == numel(xj)
    p = cmpFun(i,j);
end

%--------------------------------------------------------------------------