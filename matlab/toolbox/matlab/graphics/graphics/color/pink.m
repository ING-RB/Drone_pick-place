function p = pink(m)
%

%   C. Moler, 5-11-91, 8-19-92.
%   Copyright 1984-2024 The MathWorks, Inc.

arguments
    m (1,1) double {mustBeInteger, mustBeNonnegative} = matlab.graphics.internal.colormapheight
end

p = sqrt((2*gray(m) + hot(m))/3);
end