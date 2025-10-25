function [p,x] = sortpartition(x,xstart,xend,cmp)
%MATLAB Code Generation Private Function

% Helper used in quicksort and introsort for the partition step. Performs a
% median-of-3 partitioning on x(xstart:xend). Performs partitioning as if there
% are at least 3 elements in the range without a check. If there are 1 or 2
% elements in the range, the behavior is safe, just inefficient.

%   Copyright 2017-2019 The MathWorks, Inc.
%#codegen
xmid = xstart + coder.internal.indexDivide(xend-xstart,2);
% Median of first, middle, last
if cmp(x(xmid),x(xstart))
    t = x(xstart);
    x(xstart) = x(xmid);
    x(xmid) = t;
end
if cmp(x(xend),x(xstart))
    t = x(xstart);
    x(xstart) = x(xend);
    x(xend) = t;
end
if cmp(x(xend),x(xmid))
    t = x(xmid);
    x(xmid) = x(xend);
    x(xend) = t;
end
pivot = x(xmid);
x(xmid) = x(xend-1);
x(xend-1) = pivot;
i = xstart;
j = xend-1;
% partition x(xstart+1:xend-2)
while true
    i = i+1;
    while cmp(x(i),pivot)
        i = i+1;
    end
    j = j-1;
    while cmp(pivot,x(j))
        j = j-1;
    end
    if i >= j
        p = i;
        x(xend-1) = x(i);
        x(i) = pivot;
        return
    else
        t = x(i);
        x(i) = x(j);
        x(j) = t;
    end
end

%--------------------------------------------------------------------------
