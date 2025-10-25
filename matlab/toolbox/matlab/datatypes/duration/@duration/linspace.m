function c = linspace(a,b,n)
%

%   Copyright 2014-2024 The MathWorks, Inc.

if nargin < 3, n = 100; end
[amillis,bmillis,c] = duration.compareUtil(a,b);

if ~isscalar(amillis) || ~isscalar(bmillis) || ~isscalar(n)
    error(message('MATLAB:duration:linspace:NonScalarInputs'));
end

c.millis = linspace(amillis,bmillis,n);
