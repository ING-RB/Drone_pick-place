function [tf,step] = isregular(dur,unit)
%

%   Copyright 2020-2024 The MathWorks, Inc.

if nargin < 2
    [tf,step] = matlab.internal.datetime.isRegularTimeVector(dur);
else
    [tf,step] = matlab.internal.datetime.isRegularTimeVector(dur,unit);
end
