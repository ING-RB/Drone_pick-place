function b = median(a,varargin) %#codegen
%MEDIAN Median of durations.

%   Copyright 2020 The MathWorks, Inc.

b = duration(matlab.internal.coder.datatypes.uninitialized);
b.fmt = a.fmt;
b.millis = median(a.millis,varargin{:});
