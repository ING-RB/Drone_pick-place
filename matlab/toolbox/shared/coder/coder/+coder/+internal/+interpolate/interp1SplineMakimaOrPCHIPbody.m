function yi = interp1SplineMakimaOrPCHIPbody(pp, nycols, xi, yi, nxi, k, extrapByMethod, x)

%   Copyright 2022 The MathWorks, Inc.

%#codegen
    

    coder.inline('always')
    NAN = coder.const(coder.internal.interpolate.interpNaN(yi));
    if isnan(xi(k))
        for j = 1:nycols
            yi((j - 1)*nxi + k) = NAN;
        end
    elseif extrapByMethod || (xi(k) >= x(1) && xi(k) <= x(end))
        yit = ppval(pp,xi(k));
        for j = 1:nycols
            yi((j - 1)*nxi + k) = yit(j);
        end
    end

end