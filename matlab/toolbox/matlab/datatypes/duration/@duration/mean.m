function b = mean(a,varargin)
%

%   Copyright 2014-2024 The MathWorks, Inc.

if isa(a,"duration")
    b = a;
    b.millis = mean(a.millis,varargin{:});
    if nargin > 1
        % Catch mean(a,'double') after built-in does error checking
        invalidFlags = strncmpi(varargin,'do',2);
        if any(invalidFlags)
            error(message('MATLAB:duration:InvalidNumericConversion',varargin{find(invalidFlags,1)}));
        end
    end
else
    b = matlab.internal.datatypes.fevalFunctionOnPath("mean",a,varargin{:});
end
