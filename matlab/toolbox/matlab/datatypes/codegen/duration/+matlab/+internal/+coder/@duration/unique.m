function [c,ia,ic] = unique(a,varargin) %#codegen
%UNIQUE Find unique durations in an array.

%   Copyright 2020 The MathWorks, Inc.

% Call unique with appropriate output args for optimal performance
c = duration(matlab.internal.coder.datatypes.uninitialized);
c.fmt = a.fmt;
if nargout == 1
    c.millis = unique(a.millis,varargin{:});
elseif nargout == 2
    [c.millis,ia] = unique(a.millis,varargin{:});
else
    [c.millis,ia,ic] = unique(a.millis,varargin{:});
end
