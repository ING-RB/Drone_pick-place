function Vqk = interpnCubicLoopBody(Xqk,VV, ND,...
    xmin, xmax, dx, EXTRAP, extrapval, varargin)

%#codegen
coder.inline('always');
coder.internal.prefer_const(EXTRAP);
realtype = zeros('like',real(VV));

if EXTRAP || coder.internal.interpolate.isInterpPoint(Xqk,ND,xmin,xmax)
    ix = coder.nullcopy(zeros(ND,1,coder.internal.indexIntClass));
    s = coder.nullcopy(zeros(ND,1,'like',realtype));
    for i = 1:ND
        ix(i) = coder.internal.bsearch(varargin{i},Xqk(i));
        s(i) = (cast(Xqk(i),'like',realtype) - cast(varargin{i}(ix(i)),'like',realtype))/dx(i);
    end

    Vqk = coder.internal.interpolate.cubic_eval(VV, ND, s, ix);
else
    Vqk = extrapval;
end