function yi = interp1LinearGpu(y,nyrows,nycols,xi,yi,extrapByMethod,varargin)
% GPU specific implementation for 'linear' method.
% Perform 'linear' interpolation on (x,y).
% The algorithm follows MATLAB coder implementation. Some loops are
% rewritten to generate optimized GPU code.

%   Copyright 2022 The MathWorks, Inc.

%#codegen

coder.gpu.kernelfun;
coder.inline('always');
coder.internal.prefer_const(nyrows,nycols,extrapByMethod);
NAN = coder.const(coder.internal.interpolate.interpNaN(yi));
xNotSupplied = nargin < 7;
nx = nyrows;
if xNotSupplied
    minx = 1;
    penx = double(nx - 1);
    maxx = double(nx);
else
    minx = varargin{1}(1);
    penx = varargin{1}(end - 1);
    maxx = varargin{1}(end);
end
nxi = coder.internal.indexInt(numel(xi));

% Slope calculation for 'linear' method
r = zeros(1,nxi,'like',xi);
m = coder.internal.indexInt(zeros(1,nxi));
for k = 1:nxi
    xik = xi(k);
    if ~isnan(xik)
        if xik > maxx
            if extrapByMethod && nx > 1
                % extrapolate past the top
                if xNotSupplied
                    r(k) = xik - maxx;
                else
                    r(k) = (xik - maxx)/(maxx - penx);
                end
            end
        elseif xik < minx
            if extrapByMethod
                % extrapolate below the bottom
                if xNotSupplied
                    r(k) = xik - 1;
                else
                    r(k) = (xik - minx)/(varargin{1}(2) - minx);
                end
            end
        else
            if xNotSupplied
                xn = eml_min(floor(xik),cast(nx - 1,'like',xi));
                n = coder.internal.indexInt(xn);
                m(k)= n;
                r(k) = xik - xn;
            else
                n = coder.internal.bsearch(varargin{1},xik);
                m(k)= n;
                xn = varargin{1}(n);
                xnp1 = varargin{1}(n + 1);
                r(k) = (xik - xn)/(xnp1 - xn);
            end
        end
    end
end
% Interpolation main operation for 'linear' method
for j = 0:nycols-1
    for k = 1:nxi
        xik = xi(k);
        if isnan(xik)
            yi(k + j*nxi) = NAN;
        elseif xik > maxx
            if extrapByMethod && nx > 1
                % extrapolate past the top
                yi(k + j*nxi) = y(nx + j*nyrows) + ...
                    r(k)*(y(nx + j*nyrows) - y(nx - 1 + j*nyrows));
            end
        elseif xik < minx
            if extrapByMethod
                % extrapolate below the bottom
                yi(k + j*nxi) = y(j*nyrows + 1) + ...
                    r(k)*(y(j*nyrows + 2) - y(j*nyrows + 1));
            end
        else
            n = m(k);
            if r(k) == 0
                % Tolerate adjacent NaNs when "interpolating" on the grid.
                y1 = y(n + j*nyrows);
                yi(k + j*nxi) = y1;
            elseif r(k) == 1
                % This case can happen on the right boundary.
                y2 = y(n + j*nyrows + 1);
                yi(k + j*nxi) = y2;
            else
                onemr = 1 - r(k);
                y1 = y(n + j*nyrows);
                y2 = y(n + j*nyrows + 1);
                if y1 == y2
                    yi(k + j*nxi) = y1;
                else
                    yi(k + j*nxi) = onemr*y1 + r(k)*y2;
                end
            end
        end
    end
end