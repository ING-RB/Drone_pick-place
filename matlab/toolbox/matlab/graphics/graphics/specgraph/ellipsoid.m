function [xx,yy,zz]=ellipsoid(varargin)
%

%   Copyright 1984-2024 The MathWorks, Inc.

import matlab.graphics.chart.internal.inputparsingutils.peelFirstArgParent
import matlab.graphics.chart.internal.inputparsingutils.getParent
narginchk(6,inf);
[parent, args] = peelFirstArgParent(varargin, true);
[args, pvpairs] = matlab.graphics.chart.internal.inputparsingutils.splitPositionalFromPV(args, 6, true);


if ~isempty(pvpairs) && nargout > 0
    warning(message('MATLAB:graphics:chart:NameValueWithArguemnt','ellipsoid'))
end

[xc,yc,zc,xr,yr,zr] = deal(args{1:6});
coordinateCheck(xc,'xc')
coordinateCheck(yc,'yc')
coordinateCheck(zc,'zc')
semiaxesCheck(xr,'xr')
semiaxesCheck(yr,'yr')
semiaxesCheck(zr,'zr')

n = 20;
if numel(args) > 6
    n = args{7};
end
validateattributes(n, {'single','double'},{'scalar','integer','positive','finite'},mfilename,'n')

[x,y,z] = sphere(n);

x = xr*x+xc;
y = yr*y+yc;
z = zr*z+zc;
if(nargout == 0)
    [parent, ~, pvpairs] = getParent(parent, pvpairs);
    parent = newplot(parent);
    surf(x, y, z, 'Parent', parent, pvpairs{:})
else
    xx=x;
    yy=y;
    zz=z;
end
end

function coordinateCheck(val,name)
    validateattributes(val, {'single','double','duration','datetime'},{'scalar','real'},mfilename,name)
end

function semiaxesCheck(val,name)
    validateattributes(val, {'single','double'},{'scalar','real'},mfilename,name)
end