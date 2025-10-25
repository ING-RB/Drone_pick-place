function map = hsv(m)
%

%   See Alvy Ray Smith, Color Gamut Transform Pairs, SIGGRAPH '78.
%   C. B. Moler, 8-17-86, 5-10-91, 8-19-92, 2-19-93.
%   Copyright 1984-2024 The MathWorks, Inc.

arguments
    m (1,1) double {mustBeInteger, mustBeNonnegative} = matlab.graphics.internal.colormapheight
end

h = (0:m-1)'/max(m,1);
if isempty(h)
    map = zeros(0,3);
else
    map = hsv2rgb([h ones(m,2)]);
end
end