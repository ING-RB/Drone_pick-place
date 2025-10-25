function x = cot(x)
%COT    Cotangent of argument in radians.
%   COT(X) is the cotangent of the elements of X.
%
%   Class support for input X:
%      float: double, single
%
%   See also ACOT, COTD.

%   Copyright 1984-2024 The MathWorks, Inc.

x = tan(x);
x = ones("like",x)./x;