function  Vq = interp1LinearLoopBody(y,nyrows,nycols,xi,Vq,nxi,k, ...
    extrapByMethod,nx,minx,penx,maxx,x)
% Loop body for linear interpolation. This is called in vectorized form:
%     Vq = interp1LinearLoopBody(...,nycols,xi,Vq,nxi,k,...)
% in the general case. When using PARFOR, however, it is called in a
% scalarized way:
%     Vq(k) = interp1LinearLoopBody(...,1,xi(k),Vq(k),1,1,...).

%   Copyright 2022 The MathWorks, Inc.

%#codegen
    
    coder.inline('always');
    coder.internal.prefer_const(nyrows,nycols,nxi,k,extrapByMethod);
    
    NAN = coder.const(coder.internal.interpolate.interpNaN(Vq));
    xNotSupplied = nargin < 13;
    xik = xi(k);
    if isnan(xik)
        for j = 0:nycols-1
            Vq(k + j*nxi) = NAN;
        end
    elseif xik > maxx
        if extrapByMethod && nx > 1
            % extrapolate past the top
            if xNotSupplied
                r = xik - maxx;
            else
                r = (xik - maxx)/(maxx - penx);
            end
            for j = 0:nycols-1
                Vq(k + j*nxi) = y(nx + j*nyrows) + ...
                    r*(y(nx + j*nyrows) - y(nx - 1 + j*nyrows));
            end
        end
    elseif xik < minx
        if extrapByMethod
            % extrapolate below the bottom
            if xNotSupplied
                r = xik - 1;
            else
                r = (xik - minx)/(x(2) - minx);
            end
            for j = 0:nycols-1
                Vq(k + j*nxi) = y(j*nyrows + 1) + ...
                    r*(y(j*nyrows + 2) - y(j*nyrows + 1));
            end
        end
    else
        if xNotSupplied
            xn = eml_min(floor(xik),cast(nx - 1,'like',xi));
            n = coder.internal.indexInt(xn);
            r = xik - xn;
        else
            n = coder.internal.bsearch(x,xik);
            xn = x(n);
            xnp1 = x(n + 1);
            r = (xik - xn)/(xnp1 - xn);
        end
        onemr = 1 - r;
        if r == 0
            % Tolerate adjacent NaNs when "interpolating" on the grid.
            for j = 0:nycols-1
                y1 = y(n + j*nyrows);
                Vq(k + j*nxi) = y1;
            end
        elseif r == 1
            % This case can happen on the right boundary.
            for j = 0:nycols-1
                y2 = y(n + j*nyrows + 1);
                Vq(k + j*nxi) = y2;
            end
        else
            for j = 0:nycols-1
                y1 = y(n + j*nyrows);
                y2 = y(n + j*nyrows + 1);
                % Testing floating point equality is a MISRA
                % violation. However, the two cases are
                % mathematically consistent, the first being an
                % optimization of the second, and we really
                % mean equality here. The *only* reason to have
                % the y1 == y2 case is to guarantee that the
                % output is exactly equal to y1 and y2 when y1
                % and y2 are exactly equal to each other.
                if y1 == y2
                    Vq(k + j*nxi) = y1;
                else
                    Vq(k + j*nxi) = onemr*y1 + r*y2;
                end
            end
        end
    end
end



