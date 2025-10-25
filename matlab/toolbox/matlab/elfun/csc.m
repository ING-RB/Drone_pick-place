function x = csc(x)
%CSC    Cosecant of argument in radians.
%   CSC(X) is the cosecant of the elements of X.
%
%   Class support for input X:
%      float: double, single
%
%   See also ACSC, CSCD.

%   Copyright 1984-2024 The MathWorks, Inc.

x = sin(x);
x = ones("like",x)./x;