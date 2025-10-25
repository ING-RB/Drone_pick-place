function tf = isinf(a) %#codegen
%ISINF True for durations that are +Inf or -Inf.

%   Copyright 2014-2019 The MathWorks, Inc.

tf = isinf(a.millis);
