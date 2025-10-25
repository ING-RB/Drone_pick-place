function tf = isnan(a) %#codegen
%ISNAN True for durations that are Not-A-Number

%   Copyright 2014-2019 The MathWorks, Inc.

tf = isnan(a.millis);
