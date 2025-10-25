function [c,ia,ib] = intersect(a,b,varargin) %#codegen
%INTERSECT Find durations common to two arrays.

%   Copyright 2020 The MathWorks, Inc.

[amillis,bmillis,c] = duration.compareUtil(a,b);

if nargout < 2
    c.millis = intersect(amillis,bmillis,varargin{:});
else
    [c.millis,ia,ib] = intersect(amillis,bmillis,varargin{:});
end
