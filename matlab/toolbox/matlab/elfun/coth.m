function x = coth(x)
%COTH   Hyperbolic cotangent.
%   COTH(X) is the hyperbolic cotangent of the elements of X.
%
%   Class support for input X:
%      float: double, single
%
%   See also ACOTH.

%   Copyright 1984-2024 The MathWorks, Inc.

x = tanh(x);
x = ones("like",x)./x;