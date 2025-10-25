function [tf,step] = isregular(dt,unit)
%

%   Copyright 2020-2024 The MathWorks, Inc.

if nargin < 2
    [tf,step] = matlab.internal.datetime.isRegularTimeVector(dt);
else
    [tf,step] = matlab.internal.datetime.isRegularTimeVector(dt,unit);
end
