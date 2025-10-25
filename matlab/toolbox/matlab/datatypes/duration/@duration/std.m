function [b, m] = std(a,varargin)
%

%   Copyright 2015-2024 The MathWorks, Inc.

if isa(a,"duration")
    b = a;
    m = a;
    [b.millis, m.millis] = std(a.millis,varargin{:});
else
    [b, m] =matlab.internal.datatypes.fevalFunctionOnPath("std",a,varargin{:});
end
