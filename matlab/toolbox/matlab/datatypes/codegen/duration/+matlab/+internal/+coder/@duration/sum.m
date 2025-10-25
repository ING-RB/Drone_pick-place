function b = sum(a,varargin) %#codegen
%SUM Sum of durations.

%   Copyright 2020 The MathWorks, Inc.

b = duration(matlab.internal.coder.datatypes.uninitialized);
b.fmt = a.fmt;
b.millis = sum(a.millis,varargin{:});

% Catch sum(a,'double') after built-in does error checking
for i = 1:nargin-1
    invalidFlag = strncmpi(varargin{i},'do',2);
    coder.internal.errorIf(invalidFlag,'MATLAB:duration:InvalidNumericConversion','double');
end
