function map = lines(m)
%

%   Copyright 1984-2024 The MathWorks, Inc.

arguments
    m (1,1) double {mustBeInteger, mustBeNonnegative} = matlab.graphics.internal.colormapheight
end

c = get(groot,'DefaultAxesColorOrder');
map = c(rem(0:m-1,size(c,1))+1,:);
end