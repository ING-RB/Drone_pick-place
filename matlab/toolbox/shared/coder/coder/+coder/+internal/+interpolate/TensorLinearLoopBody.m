function  Vq = TensorLinearLoopBody(y,xi,Vq,x)

%   Copyright 2022 The MathWorks, Inc.

%#codegen
    
    coder.inline('always');

    minx = x(1);
    penx = x(end-1);
    maxx = x(end);
    nx = coder.internal.indexInt(numel(x));
    ONE = coder.const(coder.internal.indexInt(1));
    nyrows = coder.internal.indexInt(size(y,1));
    nycols = coder.internal.indexInt(coder.internal.prodsize(y,'above',ONE));

    coder.internal.assert(nyrows==nx, '');

    NAN = coder.const(coder.internal.interpolate.interpNaN(Vq));
    
    for k = 1:coder.internal.indexInt(numel(xi))
        xik = xi(k);
        if isnan(xik)
            for j = 0:nycols-1
                Vq((k-1)*nycols + j + 1) = NAN;
            end
        elseif xik > maxx
            % extrapolate past the top
            
            r = (xik - maxx)/(maxx - penx);
            
            for j = 0:nycols-1
                Vq((k-1)*nycols + j + 1) = y(nx + j*nyrows) + ...
                    r*(y(nx + j*nyrows) - y(nx - 1 + j*nyrows));
            end
        elseif xik < minx
            % extrapolate below the bottom
            
            r = (xik - minx)/(x(2) - minx);
            for j = 0:nycols-1
                Vq((k-1)*nycols + j + 1) = y(j*nyrows + 1) + ...
                    r*(y(j*nyrows + 2) - y(j*nyrows + 1));
            end
        else
    
            n = coder.internal.bsearch(x,xik);
            xn = x(n);
            xnp1 = x(n + 1);
            r = (xik - xn)/(xnp1 - xn);
            
            onemr = 1 - r;
            if r == 0
                % Tolerate adjacent NaNs when "interpolating" on the grid.
                for j = 0:nycols-1
                    y1 = y(n + j*nyrows);
                    Vq((k-1)*nycols + j + 1) = y1;
                end
            elseif r == 1
                % This case can happen on the right boundary.
                for j = 0:nycols-1
                    y2 = y(n + j*nyrows + 1);
                    Vq((k-1)*nycols + j + 1) = y2;
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
                        Vq((k-1)*nycols + j + 1) = y1;
                    else
                        Vq((k-1)*nycols + j + 1) = onemr*y1 + r*y2;
                    end
                end
            end
        end
    end
end



