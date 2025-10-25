function c = cool(m)
%

%   C. Moler, 8-19-92.
%   Copyright 1984-2024 The MathWorks, Inc.

arguments
    m (1,1) double {mustBeInteger, mustBeNonnegative} = matlab.graphics.internal.colormapheight
end

r = (0:m-1)'/max(m-1,1);
c = [r 1-r ones(m,1)];
end