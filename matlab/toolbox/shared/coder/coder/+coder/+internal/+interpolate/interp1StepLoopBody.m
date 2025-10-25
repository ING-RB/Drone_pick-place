function  yi = interp1StepLoopBody(y,nyrows,nycols,xi,yi,nxi,k, ...
    dir,extrapByMethod,minx,maxx,x)
    % Loop body for nearest, next, and previous interpolation. This is called in
    % vectorized form:
    %     yi = interp1StepLoopBody(...,nycols,xi,yi,nxi,k,...)
    % in the general case. When using PARFOR, however, it is called in a
    % scalarized way:
    %     yi(k) = interp1StepLoopBody(...,1,xi(k),yi(k),1,1,...).

%   Copyright 2022 The MathWorks, Inc.

%#codegen

    coder.inline('always');
    coder.internal.prefer_const(nyrows,nycols,nxi,k,dir,extrapByMethod);
    isnearest = (dir == 1);
    isnext = (dir == 3);
    isprevious = (dir == 2);
    NAN = coder.const(coder.internal.interpolate.interpNaN(yi));
    xik = xi(k);
    if isnan(xik)
        for j = 0:nycols-1
            yi(k + j*nxi) = NAN;
        end
    elseif isprevious && xik == maxx
        for j = 0:nycols-1
            yi(k + j*nxi) = y(j*nyrows + nyrows);
        end
    elseif xik > maxx
        if extrapByMethod
            if isnext
                for j = 0:nycols-1
                    yi(k + j*nxi) = NAN;
                end
            else
                for j = 0:nycols-1
                    yi(k + j*nxi) = y(j*nyrows + nyrows);
                end
            end
        end
    elseif xik < minx
        if extrapByMethod
            if isprevious
                for j = 0:nycols-1
                    yi(k + j*nxi) = NAN;
                end
            else
                for j = 0:nycols-1
                    yi(k + j*nxi) = y(j*nyrows + 1);
                end
            end
        end
    else
        if nargin < 12
            xn = eml_min(floor(xik),maxx - 1);
            xnp1 = xn + 1;
            n = coder.internal.indexInt(xn);
        else
            n = coder.internal.bsearch(x,xik);
            xn = x(n);
            xnp1 = x(n + 1);
        end
        if (isnearest && (xnp1 - xik <= xik - xn)) || (isnext && xik > xn)
            iy0 = n + 1;
        else
            iy0 = n;
        end
        if iy0 > 0
            for j = 0:nycols-1
                yi(k + j*nxi) = y(iy0 + j*nyrows);
            end
        end
    end
end
