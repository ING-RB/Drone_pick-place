function [h,m,s] = hms(d)
%

%   Copyright 2014-2024 The MathWorks, Inc.

s = d.millis / 1000; % ms -> s
h = fix(s / 3600);
s = s - 3600*h;
m = fix(s / 60);
s = s - 60*m;

% Return the same non-finite in all fields.
nonfiniteElems = ~isfinite(h);
nonfiniteVals = h(nonfiniteElems);
if ~isempty(nonfiniteVals)
    m(nonfiniteElems) = nonfiniteVals;
    s(nonfiniteElems) = nonfiniteVals;
end
