function [c,ia,ib] = union(a,b,varargin)
%

%   Copyright 2014-2024 The MathWorks, Inc.

[amillis,bmillis,c] = duration.compareUtil(a,b);

if nargout < 2
    c.millis = union(amillis,bmillis,varargin{:});
else
    [c.millis,ia,ib] = union(amillis,bmillis,varargin{:});
end

