function b = abs(a) %#codegen
%ABS Absolute value for durations.

%   Copyright 2014-2019 The MathWorks, Inc.

b = a;
b.millis = abs(a.millis);
