function [tf,dt] = isregular(dt,unit) %#codegen
%ISREGULAR TRUE if a datetime vector is regular with respect to time.

%   Copyright 2020 The MathWorks, Inc.

if nargin < 2
    [tf,dt] = matlab.internal.coder.datetime.isRegularTimeVector(dt);
else
    [tf,dt] = matlab.internal.coder.datetime.isRegularTimeVector(dt,unit);
end
