function [tf,dt] = isregular(dur,unit) %#codegen
%ISREGULAR TRUE if a duration vector is regular with respect to time.

%   Copyright 2020 The MathWorks, Inc.

if nargin < 2
    [tf,dt] = matlab.internal.coder.datetime.isRegularTimeVector(dur);
else
    [tf,dt] = matlab.internal.coder.datetime.isRegularTimeVector(dur,unit);
end
