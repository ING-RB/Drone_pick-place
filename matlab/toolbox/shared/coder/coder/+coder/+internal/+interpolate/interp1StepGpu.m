function yi = interp1StepGpu(y,nyrows,nycols,xi,...
        yi,extrapByMethod,dir,varargin)

% GPU specific implementation for 'nearest', 'next' and 'previous' methods
% Perform 'nearest' or 'next' or 'previous' interpolation on (x,y). 
% The algorithm follows MATLAB coder implementation. Some loops are 
% rewritten to generate optimized GPU code.

%   Copyright 2022 The MathWorks, Inc.

%#codegen

coder.gpu.kernelfun;
coder.inline('always');
coder.internal.prefer_const(nyrows,nycols,extrapByMethod);
NAN = coder.const(coder.internal.interpolate.interpNaN(yi));
xNotSupplied = nargin < 8;
nx = nyrows;
if xNotSupplied
    minx = 1;
    maxx = double(nx);
else
    minx = varargin{1}(1);
    maxx = varargin{1}(end);
end
isnearest = coder.const(dir == 1);
isnext = coder.const(dir == 3);
isprevious = coder.const(dir == 2);
nxi = coder.internal.indexInt(numel(xi));

% Slope calculation for 'nearest', 'next' and 'previous' methods
iy0 = coder.internal.indexInt(zeros(1,nxi));
for k = 1:nxi
    xik = xi(k);
    if ~isnan(xik) && ~(isprevious && xik == maxx)...
            && ~(xik > maxx) && ~(xik < minx)
        if xNotSupplied
            xn = eml_min(floor(xik),maxx - 1);
            xnp1 = xn + 1;
            n = coder.internal.indexInt(xn);
        else
            n = coder.internal.bsearch(varargin{1},xik);
            xn = varargin{1}(n);
            xnp1 = varargin{1}(n + 1);
        end
        if (isnearest && (xnp1 - xik <= xik - xn)) || (isnext && xik > xn)
            iy0(k) = n + 1;
        else
            iy0(k) = n;
        end
    end
end
% Interpolation main operation for 'nearest', 'next' and 'previous' methods
for j = 0:nycols-1
    for k = 1:nxi
        xik = xi(k);
        if isnan(xik)
            yi(k + j*nxi) = NAN;
        elseif isprevious && xik == maxx
            yi(k + j*nxi) = y(j*nyrows + nyrows);
        elseif xik > maxx
            if extrapByMethod
                if isnext
                    yi(k + j*nxi) = NAN;
                else
                    yi(k + j*nxi) = y(j*nyrows + nyrows);
                end
            end
        elseif xik < minx
            if extrapByMethod
                if isprevious
                    yi(k + j*nxi) = NAN;
                else
                    yi(k + j*nxi) = y(j*nyrows + 1);
                end
            end
        else
            if iy0(k) > 0
                    yi(k + j*nxi) = y(iy0(k) + j*nyrows);
            end
        end
    end
end