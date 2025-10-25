function b = mean(a,varargin) %#codegen
%MEAN Mean of durations.

%   Copyright 2020 The MathWorks, Inc.

b = duration(matlab.internal.coder.datatypes.uninitialized);
b.fmt = a.fmt;
b.millis = mean(a.millis,varargin{:});

% Catch mean(a,'double') after built-in does error checking
for i = 1:nargin-1
    invalidFlag = strncmpi(varargin{i},'do',2);
    coder.internal.errorIf(invalidFlag,'MATLAB:duration:InvalidNumericConversion','double');
end
