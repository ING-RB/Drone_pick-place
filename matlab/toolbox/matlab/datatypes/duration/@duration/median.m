function b = median(a,varargin)
%

%   Copyright 2014-2024 The MathWorks, Inc.

if isa(a,"duration")
    b = a;
    b.millis = median(a.millis,varargin{:});    
else
	b = matlab.internal.datatypes.fevalFunctionOnPath("median",a,varargin{:});
end