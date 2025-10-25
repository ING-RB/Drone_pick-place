function x = sec(x)
%SEC    Secant of argument in radians.
%   SEC(X) is the secant of the elements of X.
%
%   Class support for input X:
%      float: double, single
%
%   See also ASEC, SECD.

%   Copyright 1984-2024 The MathWorks, Inc.

x = cos(x);
x = ones("like",x)./x;