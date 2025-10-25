function [c,ia] = setdiff(a,b,varargin) %#codegen
%SETDIFF Find durations that occur in one array but not in another.

%   Copyright 2020 The MathWorks, Inc.

[amillis,bmillis,c] = duration.compareUtil(a,b);

if nargout < 2
    c.millis = setdiff(amillis,bmillis,varargin{:});
else
    [c.millis,ia] = setdiff(amillis,bmillis,varargin{:});
end
