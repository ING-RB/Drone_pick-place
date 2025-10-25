function sz = getCoefsSize(nd, vals)

%Try to get const size for the spline coefs

%#codegen

coder.inline('always');
% The dimension of the grid is fixed
sz = coder.nullcopy(zeros(1, nd+1, coder.internal.indexIntClass()));

for i = coder.unroll(1:nd)
    npts = coder.internal.indexInt(size(vals,i));
    if npts == coder.internal.indexInt(2)
        sz(i+1) = coder.internal.indexInt(2);
    elseif npts == coder.internal.indexInt(3)
        sz(i+1) = coder.internal.indexInt(3);
    else
        sz(i+1) = coder.internal.indexInt(4)*(npts - coder.internal.indexInt(1));
    end
end
sz(1) = coder.internal.prodsize(vals, 'above', nd);