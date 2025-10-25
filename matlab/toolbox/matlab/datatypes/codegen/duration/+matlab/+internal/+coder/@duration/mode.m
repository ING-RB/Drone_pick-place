function [m,f,c] = mode(a,varargin) %#codegen
%MODE Most frequent duration value.

%   Copyright 2020 The MathWorks, Inc.

m = duration(matlab.internal.coder.datatypes.uninitialized);
m.fmt = a.fmt;
if nargout < 3
    [m.millis,f] = mode(a.millis,varargin{:});
else
    % this line always errors because the built-in doesn't support the third output
    [m.millis,f,c] = mode(a.millis,varargin{:});
end
