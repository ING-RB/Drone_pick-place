function w = width(x)
%WIDTH Number of columns/variables in a tall array, tall table or timetable.
%   W = WIDTH(X)
%
%   See also TALL/HEIGHT, TALL/SIZE, TALL/NUMEL.

% Copyright 2015-2024 The MathWorks, Inc.

if istabular(x)
    w = x.Adaptor.Size(2);
else
    w = size(x, 2);
end
