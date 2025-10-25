function map = parula(m)
%

%   Copyright 2013-2024 The MatWorks, Inc.

arguments
    m (1,1) double {mustBeInteger, mustBeNonnegative} = matlab.graphics.internal.colormapheight
end

values = matlab.graphics.internal.parulaColormapValues;
P = height(values);
map = interp1(1:P, values, linspace(1,P,m), 'linear');
end