function x = sech(x)
%SECH   Hyperbolic secant.
%   SECH(X) is the hyperbolic secant of the elements of X.
%
%   Class support for input X:
%      float: double, single
%
%   See also ASECH.

%   Copyright 1984-2024 The MathWorks, Inc.

x = cosh(x);
x = ones("like",x)./x;