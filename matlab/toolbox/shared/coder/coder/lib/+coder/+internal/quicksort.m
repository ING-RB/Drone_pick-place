function x = quicksort(x,xstart,xend,cmp)
%MATLAB Code Generation Private Function

% Perform quicksort on x(xstart:xend) in place. Manually manages a stack to
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
% insertion sort for small sizes.

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
if xend - xstart + 1 <= BND
    x = coder.internal.insertionsort(x,xstart,xend,cmp);
    return
end
frame = struct('xstart',xstart,'xend',xend);
st = coder.internal.stack(frame);
st = st.push(frame);
while st.stackSize() > 0
    [s,st] = st.pop();
    xstart = s.xstart; xend = s.xend;
    if xend - xstart + 1 <= BND
        x = coder.internal.insertionsort(x,xstart,xend,cmp);
    else
        [p,x] = sortpartition(x,xstart,xend,cmp);
        % Push right then left partition to match the customary implementation's
        % recursion order
        if p+1 < xend
            st = st.push(struct('xstart',p+1,'xend',xend));
        end
        if xstart < p
            st = st.push(struct('xstart',xstart,'xend',p));
        end
    end
end

%--------------------------------------------------------------------------
