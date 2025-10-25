function x = heapsort(x,xstart,xend,cmp)
%MATLAB Code Generation Private Function

% Perform heapsort on x(xstart:xend) in place. Requires no extra storage. xstart
% and xend must be supplied as coder.internal.indexInt values and must be in
% range for x. This is not checked.
%
% The optional argument cmp provides the comparison function that should return
% true for the desired sort order. cmp should be strict so that it returns false
% for equal elements.

%   Copyright 2017-2019 The MathWorks, Inc.
%#codegen
coder.inline('never');
n = xend-xstart+1;
if nargin < 4
    cmp = @lt;
end
x = makeHeap(x,xstart,xend,n,cmp);
for k = 1:n-1
    % Move max to end then re-heapify
    t = x(xend);
    x(xend) = x(xstart);
    x(xstart) = t;
    xend = xend-1;
    x = heapify(x,coder.internal.indexInt(1),xstart,xend,cmp);
end

%--------------------------------------------------------------------------

function x = makeHeap(x,xstart,xend,n,cmp)
% Bottom-up heapify routine. Provide startIdx to start at a level higher than
% the bottom.
for idx = n:-1:1
    x = heapify(x,idx,xstart,xend,cmp);
end

%--------------------------------------------------------------------------

function x = heapify(x,idx,xstart,xend,cmp)
% Bottom-up heapify routine. Provide startIdx to start at a level higher than
% the bottom.
changed = true;
xoff = xstart-1;
extremumIdx = idx+xoff;
leftIdx = 2*idx+xoff;
% Peeling off the last possible iteration of this loop allows us to assume that
% rightIdx <= xend for the entire while loop saving 1 comparison per iteration.
while changed && leftIdx < xend
    changed = false;
    rightIdx = leftIdx+1;
    extremum = x(extremumIdx);
    cmpIdx = leftIdx;
    xcmp = x(leftIdx);
    xr = x(rightIdx);
    if cmp(xcmp,xr)
        cmpIdx = cmpIdx+1;
        xcmp = xr;
    end
    if cmp(extremum,xcmp)
        x(extremumIdx) = xcmp;
        x(cmpIdx) = extremum;
        extremumIdx = cmpIdx;
        leftIdx = 2*(extremumIdx-xoff)+xoff;
        changed = true;
    end
end
if changed && leftIdx <= xend
    extremum = x(extremumIdx);
    cmpIdx = leftIdx;
    xcmp = x(leftIdx);
    if cmp(extremum,xcmp)
        x(extremumIdx) = xcmp;
        x(cmpIdx) = extremum;
    end
end

%--------------------------------------------------------------------------
