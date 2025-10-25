function [c,ia] = setdiff(a,b,varargin)
%

%   Copyright 2014-2024 The MathWorks, Inc.

[amillis,bmillis,c] = duration.compareUtil(a,b);

if nargout < 2
    c.millis = setdiff(amillis,bmillis,varargin{:});
else
    [c.millis,ia] = setdiff(amillis,bmillis,varargin{:});
end

