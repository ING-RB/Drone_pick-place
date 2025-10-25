function c = copper(m)
%

%   C. Moler, 8-17-88, 8-19-92.
%   Copyright 1984-2024 The MathWorks, Inc.

arguments
    m (1,1) double {mustBeInteger, mustBeNonnegative} = matlab.graphics.internal.colormapheight
end

c = min(1,gray(m)*diag([1.2500 0.7812 0.4975]));
end