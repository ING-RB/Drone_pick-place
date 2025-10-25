function b = diff(a,varargin)  %#codegen
%DIFF Duration differences.

%   Copyright 2014-2019 The MathWorks, Inc.

b = matlab.internal.coder.duration;
b.fmt = a.fmt;
b.millis = diff(a.millis,varargin{:});
