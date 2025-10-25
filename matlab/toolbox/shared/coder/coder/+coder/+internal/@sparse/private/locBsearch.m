function [n,found] = locBsearch(x,xi,xstart,xend)
%MATLAB Code Generation Private Function

% Helper wrapper for coder.internal.bsearch to handle the case when xstart >=
% xend

%   Copyright 2016-2018 The MathWorks, Inc.
%#codegen
if xstart < xend
    if xi < x(xstart)
        n = xstart-1;
        found = false;
    else
        n = coder.internal.bsearch(x,xi,xstart,xend);
        found = x(n) == xi;
    end
elseif xstart == xend
    n = xstart-1;
    found = false;
else
    n = zeros('like',x);
    found = false;
end

%--------------------------------------------------------------------------
