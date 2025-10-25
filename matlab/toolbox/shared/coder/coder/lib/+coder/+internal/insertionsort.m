function x = insertionsort(x,xstart,xend,cmp)
%MATLAB Code Generation Private Function

% Perform insertion sort on x(xstart:xend) in place. xstart and xend must be
% supplied as coder.internal.indexInt values and must be in range for x. This is
% not checked.
%
% The optional argument cmp provides the comparison function that should return
% true for the desired sort order. cmp should be strict so that it returns false
% for equal elements.

%   Copyright 2017-2019 The MathWorks, Inc.
%#codegen
coder.inline('never');
if nargin <4
    cmp = @lt;
end
for k = xstart+1:xend
    xc = x(k);
    idx = k-1;
    while idx >= xstart && cmp(xc,x(idx))
        x(idx+1) = x(idx);
        idx = idx-1;
    end
    x(idx+1) = xc;
end

%--------------------------------------------------------------------------
