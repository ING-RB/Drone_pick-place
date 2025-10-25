function [c,ia,ib] = setxor(a,b,varargin)
%

%   Copyright 2014-2024 The MathWorks, Inc.

[amillis,bmillis,c] = duration.compareUtil(a,b);

if nargout < 2
    c.millis = setxor(amillis,bmillis,varargin{:});
else
    [c.millis,ia,ib] = setxor(amillis,bmillis,varargin{:});
end
