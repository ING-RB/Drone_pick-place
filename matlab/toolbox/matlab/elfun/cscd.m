function x = cscd(x)
%CSCD   Cosecant of argument in degrees.
%   CSCD(X) is the cosecant of the elements of X, expressed in degrees.
%   For integers n, cscd(n*180) is infinite, whereas csc(n*pi) is large
%   but finite, reflecting the accuracy of the floating point value for pi.
%
%   Class support for input X:
%      float: double, single
%
%   See also ACSCD, CSC.

%   Copyright 1984-2024 The MathWorks, Inc.

x = sind(x);
x = ones("like",x)./x;