function c = linspace(a,b,n) %#codegen
%LINSPACE Create equally-spaced sequence of durations.

%   Copyright 2020 The MathWorks, Inc.

if nargin < 3, n = 100; end
[amillis,bmillis,c] = duration.compareUtil(a,b);
coder.internal.assert(isscalar(amillis) && isscalar(bmillis) && isscalar(n),'MATLAB:duration:linspace:NonScalarInputs');
c.millis = linspace(amillis,bmillis,n);
