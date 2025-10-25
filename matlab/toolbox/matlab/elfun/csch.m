function x = csch(x)
%CSCH   Hyperbolic cosecant.
%   CSCH(X) is the hyperbolic cosecant of the elements of X.
%
%   Class support for input X:
%      float: double, single
%
%   See also ACSCH.

%   Copyright 1984-2024 The MathWorks, Inc.

x = sinh(x);
x = ones("like",x)./x;