function [xx,yy,zz] = cylinder(varargin)
%

%   Copyright 1984-2024 The MathWorks, Inc.

import matlab.graphics.chart.internal.inputparsingutils.peelFirstArgParent
import matlab.graphics.chart.internal.inputparsingutils.getParent
[parent, args] = peelFirstArgParent(varargin, true);
nargs = numel(args);

r = [1;1];
n = 20;

nposargs = 0;
if nargs > 0 && ~matlab.graphics.internal.isCharOrString(args{1})
    r = args{1}(:);
    validateattributes(r, {'single','double','duration'},{'real','nonempty'},mfilename,'r')
    if isscalar(r)
        r = [r;r];
    end
    nposargs = 1;
    if nargs > 1 && ~matlab.graphics.internal.isCharOrString(args{2})
        n = args{2};
        validateattributes(n, {'single','double'},{'scalar','integer','positive'},mfilename,'n')
        nposargs = 2;
    end
end
m = numel(r);
theta = (0:n)/n*2*pi;
sintheta = sin(theta);
sintheta(n+1) = 0;
x = r * cos(theta);
y = r * sintheta;
z = (0:m-1)'/(m-1) * ones(1,n+1);

if nargout == 0
    pvpairs = args(nposargs+1:end);
    % Use splitPositionalFromPV for validation that even inputs are text
    matlab.graphics.chart.internal.inputparsingutils.splitPositionalFromPV(...
        pvpairs, 0, false);
    [parent, ~, pvpairs] = getParent(parent, pvpairs);
    parent = newplot(parent);
    surf(x, y, z, 'Parent', parent, pvpairs{:})
else
    if nposargs ~= numel(args)
        warning(message('MATLAB:graphics:chart:NameValueWithArguemnt','cylinder'))
    end
    xx = x;
    yy = y;
    zz = z;
end
end
