function [c,ia,ib] = setxor(a,b,varargin) %#codegen
%SETXOR Find durations that occur in one or the other of two arrays, but not both.

%   Copyright 2020 The MathWorks, Inc.

[amillis,bmillis,c] = duration.compareUtil(a,b);

if nargout < 2
    c.millis = setxor(amillis,bmillis,varargin{:});
else
    [c.millis,ia,ib] = setxor(amillis,bmillis,varargin{:});
end
