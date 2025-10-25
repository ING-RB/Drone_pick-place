function pp = interp1SplineMakimaOrPCHIPcoefs(METHOD,y,x)

%   Copyright 2022 The MathWorks, Inc.

%#codegen

coder.inline('always')

if coder.internal.isConstTrue(isvector(y))
        % No permutation is needed.
    if METHOD == 5
        pp = spline(x,y(:).');        
    elseif METHOD == 6
        pp = pchip(x,y(:).');
    else
        pp = makima(x,y(:).');
    end
else
    ndy = coder.internal.ndims(y);
    p = coder.const([2:ndy,1]);
    yp = permute(y,p);
    if METHOD == 5
        pp = spline(x,yp);
    elseif METHOD == 6
        pp = pchip(x,yp);
    else
        pp = makima(x,yp);
    end
end

