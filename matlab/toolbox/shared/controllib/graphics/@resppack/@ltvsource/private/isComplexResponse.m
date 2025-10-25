function b = isComplexResponse(YData)
% Check if data is complex within rounding errors

%   Copyright 2017-2020 The MathWorks, Inc.

YData = YData(isfinite(YData));
Scale = max(abs(YData));
b = any(abs(imag(YData)) > sqrt(eps)*Scale);
