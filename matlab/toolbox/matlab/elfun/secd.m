function x = secd(x)
%SECD   Secant of argument in degrees.
%   SECD(X) is the secant of the elements of X, expressed in degrees.
%   For odd integers n, secd(n*90) is infinite, whereas sec(n*pi/2) is large
%   but finite, reflecting the accuracy of the floating point value for pi.
%
%   Class support for input X:
%      float: double, single
%
%   See also ASECD, SEC.

%   Copyright 1984-2024 The MathWorks, Inc. 

x = cosd(x);
x = ones("like",x)./x;