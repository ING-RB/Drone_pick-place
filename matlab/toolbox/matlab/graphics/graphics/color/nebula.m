function map = nebula(m)
%

%   Copyright 2024 The MathWorks, Inc.

arguments
    m (1,1) double {mustBeInteger, mustBeNonnegative} = matlab.graphics.internal.colormapheight
end

values = matlab.graphics.internal.nebulaColormapData;
P = height(values);
map = interp1(1:P, values, linspace(1,P,m),'linear');
end