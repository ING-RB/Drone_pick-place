function r = extractFiniteRanges(s)
%This function is for internal use only. It may be removed in the future.

%EXTRACTFINITERANGES extract finite range values from input lidarScan s

% Copyright 2022 The MathWorks, Inc.

r = s.Ranges(isfinite(s.Ranges));
% if all the ranges are invalid fill a dummy range
if isempty(r)
    r = 0;
end
end