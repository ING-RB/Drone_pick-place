function c = autumn(m)
%

%   Copyright 1984-2024 The MathWorks, Inc.

arguments
    m (1,1) double {mustBeInteger, mustBeNonnegative} = matlab.graphics.internal.colormapheight
end

r = (0:m-1)'/max(m-1,1);
c = [ones(m,1) r zeros(m,1)];
end