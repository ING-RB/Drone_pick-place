function tf = isfinite(a) %#codegen
%ISFINITE True for durations that are finite.

%   Copyright 2014-2019 The MathWorks, Inc.

tf = isfinite(a.millis);
