function [xx,yy,zz] = sphere(varargin)
%

%   Copyright 1984-2024 The MathWorks, Inc.

import matlab.graphics.chart.internal.inputparsingutils.peelFirstArgParent
import matlab.graphics.chart.internal.inputparsingutils.getParent
[parent, args] = peelFirstArgParent(varargin, true);
[args, nvpairs] = matlab.graphics.chart.internal.inputparsingutils.splitPositionalFromPV(...
    args, 0, true);

if ~isempty(nvpairs) && nargout > 0
    warning(message('MATLAB:graphics:chart:NameValueWithArguemnt','sphere'))
end

n = 20;
if ~isempty(args)
    n = args{1};
    validateattributes(n, {'single','double'},{'scalar','integer','positive'},mfilename,'n')
end

% -1 <= theta <= 1 is a row vector.
% -1/2 <= phi <= 1/2 is a column vector.
theta = (-n:2:n)/n;
phi = theta'./2;
cosphi = cospi(phi);

x = cosphi.*cospi(theta);
y = cosphi.*sinpi(theta);
z = sinpi(phi).*ones(1,n+1);

if nargout == 0
    [parent, ~, nvpairs] = getParent(parent, nvpairs);
    parent = newplot(parent);
    surf(x,y,z,'Parent',parent,nvpairs{:})
else
    xx = x; yy = y; zz = z;
end
end
