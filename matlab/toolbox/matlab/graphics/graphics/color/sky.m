function map = sky(m)
%

%   Copyright 2023-2024 The MathWorks, Inc.

arguments
    m (1,1) double {mustBeInteger, mustBeNonnegative} = matlab.graphics.internal.colormapheight
end

map = matlab.graphics.internal.blueColormapValues(true,m);
end