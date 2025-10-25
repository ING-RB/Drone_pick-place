function b = diff(a,varargin)
%

%   Copyright 2014-2024 The MathWorks, Inc.

b = a;
b.millis = diff(a.millis,varargin{:});
