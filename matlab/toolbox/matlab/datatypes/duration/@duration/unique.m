function [a,i,j] = unique(a,varargin)
%

%   Copyright 2014-2024 The MathWorks, Inc.

% Call unique with appropriate output args for optimal performance
if isa(a,"duration")
    if nargout == 1
        a.millis = unique(a.millis,varargin{:});
    elseif nargout == 2
        [a.millis, i] = unique(a.millis,varargin{:});
    else
        [a.millis, i, j] = unique(a.millis,varargin{:});
    end
else
    [a,i,j] = matlab.internal.datatypes.fevalFunctionOnPath("unique",a,varargin{:});
end