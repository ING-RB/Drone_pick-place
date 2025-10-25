function x = introsort(x,xstart,xend,cmp)
%MATLAB Code Generation Private Function

% Perform introsort on x(xstart:xend) in place. Manually manages a stack to
% avoid runtime recursion. xstart and xend must be supplied as
% coder.internal.indexInt values and must be in range for x. This is not
% checked.
%
% The optional argument cmp provides the comparison function that should return
% true for the desired sort order. cmp should be strict so that it returns false
% for equal elements.
%
% Algorithm:
%
% Performs quicksort using a median-of-3 pivoting strategy. Falls back to
% insertion sort for small sizes. Falls back to heap sort if the recursion depth
% is too large. The current recursion limit is 2*floor(log2(n)).
%
% This approach guarantees O(n*log(n)) worst-case runtime and O(log(n)) space.

%   Copyright 2017-2019 The MathWorks, Inc.
%#codegen
coder.inline('never');
if xstart >= xend
    % Done
    return
end
if nargin < 4
    cmp = @lt;
end
BND = 32;
nsort = xend - xstart + 1;
if nsort <= BND
    x = coder.internal.insertionsort(x,xstart,xend,cmp);
    return
end
MAXDEPTH = 2*(nextpow2(nsort)-1);
depth = coder.internal.indexInt(0);
frame = struct('xstart',xstart,'xend',xend,'depth',depth);
fixedSize = true;
st = coder.internal.stack(frame,2*MAXDEPTH,fixedSize);
st = st.push(frame);
while st.stackSize() > 0
    [s,st] = st.pop();
    xstart = s.xstart; xend = s.xend; depth = s.depth;
    if xend - xstart + 1 <= BND
        x = coder.internal.insertionsort(x,xstart,xend,cmp);
    elseif depth == MAXDEPTH
        x = coder.internal.heapsort(x,xstart,xend,cmp);
    else
        [p,x] = sortpartition(x,xstart,xend,cmp);
        % Push right then left partition to match the customary implementation's
        % recursion order
        if p+1 < xend
            st = st.push(struct('xstart',p+1,'xend',xend,'depth',depth+1));
        end
        if xstart < p
            st = st.push(struct('xstart',xstart,'xend',p,'depth',depth+1));
        end
    end
end

%--------------------------------------------------------------------------
