function [m,f,c] = mode(a,varargin)
%

%   Copyright 2014-2024 The MathWorks, Inc.

if isa(a,"duration")
    m = a;
    if nargout < 3
        [m.millis,f] = mode(a.millis,varargin{:});
    else
        [m.millis,f,c] = mode(a.millis,varargin{:});
        for i = 1:numel(c)
            c_i = a;
            c_i.millis = c{i};
            c{i} = c_i;
        end
    end
else
    [m,f,c] = matlab.internal.datatypes.fevalFunctionOnPath("mode",a,varargin{:});
end
