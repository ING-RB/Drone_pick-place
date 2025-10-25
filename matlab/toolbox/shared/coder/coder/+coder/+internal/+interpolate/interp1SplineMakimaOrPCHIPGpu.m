function yi = interp1SplineMakimaOrPCHIPGpu(y,nyrows,nycols,xi,...
    yi,extrapByMethod,METHOD,x)

% GPU specific implementation for makima, pchip and spline methods.
% Perform 'makima', 'pchip' or 'spline' interpolation on (x,y).
% The algorithm follows MATLAB coder implementation. Some loops are
% rewritten to generate optimized GPU code.

%#codegen
 
coder.gpu.kernelfun;
coder.inline('always');
coder.internal.prefer_const(nyrows,nycols,extrapByMethod);
NAN = coder.const(coder.internal.interpolate.interpNaN(yi));
xNotSupplied = nargin < 8;
if xNotSupplied
    x = 1:cast(nyrows,'like',real(y));
end
nxi = coder.internal.indexInt(numel(xi));
ndy = coder.internal.indexInt(coder.internal.ndims(y));
if eml_is_const(isvector(y)) && isvector(y)
    % No permutation is needed.
    if METHOD == coder.internal.interpolate.interpMethodsEnum.SPLINE
        pp = spline(x,y(:).');
	elseif METHOD == coder.internal.interpolate.interpMethodsEnum.MAKIMA
		pp = makima(x,y(:).');
    else
        pp = pchip(x,y(:).');
    end
else
    p = coder.const([2:ndy,1]);
    yp = permute(y,p);
    if METHOD == coder.internal.interpolate.interpMethodsEnum.SPLINE
        pp = spline(x,yp);
	elseif METHOD == coder.internal.interpolate.interpMethodsEnum.MAKIMA
		pp = makima(x,yp);
    else
        pp = pchip(x,yp);
    end
end
if coder.const(eml_is_const(isscalar(xi)) && isscalar(xi))
    yi(:) = ppval(pp,xi(1));
    return
end
for j = 1:nycols
    for k = 1:nxi
        if isnan(xi(k))
            yi((j - 1)*nxi + k) = NAN;
        end
    end
end
for k = 1:nxi
    if extrapByMethod || (xi(k) >= x(1) && xi(k) <= x(end))
        yit = ppval(pp,xi(k));
        for j = 1:nycols
            yi((j - 1)*nxi + k) = yit(j);
        end
    end
end