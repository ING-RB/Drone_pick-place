function g = gray(m)
%

%   Copyright 1984-2024 The MathWorks, Inc.

arguments
    m (1,1) double {mustBeInteger, mustBeNonnegative} = matlab.graphics.internal.colormapheight
end

g = (0:m-1)'/max(m-1,1);
g = [g g g];
end