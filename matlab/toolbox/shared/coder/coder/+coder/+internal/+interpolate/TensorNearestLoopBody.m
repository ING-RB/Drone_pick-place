function  yi = TensorNearestLoopBody(y,xi,yi,x)

%   Copyright 2022 The MathWorks, Inc.

%#codegen
    
    minx = x(1);
    maxx = x(end);
    NAN = coder.const(coder.internal.interpolate.interpNaN(yi));
    ONE = coder.const(coder.internal.indexInt(1));
    nyrows = coder.internal.indexInt(size(y,1));
    nycols = coder.internal.indexInt(coder.internal.prodsize(y,'above',ONE));

    for k = 1:coder.internal.indexInt(numel(xi))
        xik = xi(k);
        if isnan(xik)
            for j = 0:nycols-1
                yi((k-1)*nycols + j + 1) = NAN;
            end
        elseif xik > maxx
            for j = 0:nycols-1
                yi((k-1)*nycols + j + 1) = y(j*nyrows + nyrows);
            end
        elseif xik < minx
            
            for j = 0:nycols-1
                yi((k-1)*nycols + j + 1) = y(j*nyrows + 1);
            end
            
        else
            n = coder.internal.bsearch(x,xik);
            xn = x(n);
            xnp1 = x(n + 1);
            
            if (xnp1 - xik <= xik - xn)
                iy0 = n + 1;
            else
                iy0 = n;
            end
            if iy0 > 0
                for j = 0:nycols-1
                    yi((k-1)*nycols + j + 1) = y(iy0 + j*nyrows);
                end
            end
        end
    end

end
