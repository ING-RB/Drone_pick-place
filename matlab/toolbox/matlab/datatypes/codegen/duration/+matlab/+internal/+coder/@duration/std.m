function b = std(a,varargin) %#codegen
%STD Standard deviation of durations.

%   Copyright 2020 The MathWorks, Inc.

b = duration(matlab.internal.coder.datatypes.uninitialized);
b.fmt = a.fmt;
b.millis = std(a.millis,varargin{:});
