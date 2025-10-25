function Vqk = interpnLocalLoopBody(ND,interpf,EXTRAPp,extrapval, ...
    vbbidx,stride,xmin,xmax,V,Xq,varargin)
% For AUTOGRID, varargin is not supplied, otherwise varargin is N elements
% long: X1,X2,...,XN. XK is a vector of grid points in the K-th dimension.

%#codegen
coder.inline('always');
coder.internal.prefer_const(ND,interpf,EXTRAPp,vbbidx,stride);
AUTOGRID = coder.const(isempty(varargin));

if ~EXTRAPp && ~coder.internal.interpolate.isInterpPoint(Xq,ND,xmin,xmax)
    Vqk = extrapval;
else
    voffset = coder.internal.indexInt(0);
    % Construct the bounding box of the interpolation point.
    if AUTOGRID
        xbox = coder.nullcopy(zeros(2,ND));
        for d = 1:ND
            k = coder.internal.interpolate.autogridLookup(Xq(d),xmax(d) - 1);
            voffset = voffset + (k - 1)*stride(d);
            xbox(1,d) = k;
            xbox(2,d) = k + 1;
        end
    else
        xbox = coder.nullcopy(zeros(2,ND,'like',varargin{1}));
        for d = coder.unroll(1:ND)
            k = coder.internal.bsearch(varargin{d},Xq(d));
            voffset = voffset + (k - 1)*stride(d);
            xbox(1,d) = varargin{d}(k);
            xbox(2,d) = varargin{d}(k + 1);
        end
    end
    % Evaluate the "local" interpolation rule over the bounding box, with the
    % reduced array of values V at each vertex.
    vbox = V(vbbidx + voffset);
    if interpf == coder.internal.interpolate.interpMethodsEnum.LINEAR
        Vqk = scalarMultilinearInterp(ND,AUTOGRID,xbox,vbox,Xq);
    else
        Vqk = scalarNearestInterp(ND,AUTOGRID,xbox,vbox,Xq);
    end
end

%--------------------------------------------------------------------------

function vq = scalarMultilinearInterp(ND,AUTOGRID,x,v,xq)
% Let N be coder.internal.ndims(v) and suppose that 1-D interpolation is excluded. x
% is an 2-by-N matrix of nearest grid neighbors bracketing the point xq,
% i.e. x defines an N-D bounding box for xq. v is an array with pow2(N)
% elements, laid out like a 2-by-2-by-2-... array, values at the grid
% points defined by x. To illustrate, if N = 4, v(1) is the value at x(1,:)
% and v(11) = v(1,2,1,2) is the value at (x(1,1),x(2,2),x(1,3),x(2,4)).
% xq is the point to interpolate, where, unless extrapolating,
% x(1,k) <= xq(k) <= x(2,k).  If AUTOGRID is true, x(1,k) == k and x(2,k)
% == k + 1.
coder.inline('always');
coder.internal.prefer_const(ND,AUTOGRID);
ONE = coder.internal.indexInt(1);
if isa(x,'single') && isa(v,'single') && isa(xq,'single')
    % Use single precision only.
    % Note that AUTOGRID effectively implies a double precision grid since
    % x belongs to coder.internal.indexIntClass in that case.
    RATIOCLASS = 'single';
else
    RATIOCLASS = 'double';
end
for d = 1:ND
    m = eml_lshift(ONE,ND - d);
    if xq(d) == x(1,d)
        for k = 1:m
            v(k) = v(2*k - 1);
        end
    elseif xq(d) == x(2,d)
        for k = 1:m
            v(k) = v(2*k);
        end
    else
        xqd = cast(xq(d),RATIOCLASS);
        x1d = cast(x(1,d),RATIOCLASS);
        if AUTOGRID
            r = xqd - x1d;
        else
            x2d = cast(x(2,d),RATIOCLASS);
            r = (xqd - x1d)/(x2d - x1d);
        end
        onemr = 1 - r;
        for k = 1:m
            v(k) = onemr*v(2*k - 1) + r*v(2*k);
        end
    end
end
vq = v(1);

%--------------------------------------------------------------------------

function vq = scalarNearestInterp(ND,AUTOGRID,x,v,xq)
% Let N be coder.internal.ndims(v) and suppose that 1-D interpolation is excluded. x
% is an 2-by-N matrix of nearest grid neighbors bracketing the point xq,
% i.e. x defines an N-D bounding box for xq. v is an array with pow2(N)
% elements, laid out like a 2-by-2-by-2-... array, values at the grid
% points defined by x. To illustrate, if N = 4, v(1) is the value at x(1,:)
% and v(11) = v(1,2,1,2) is the value at (x(1,1),x(2,2),x(1,3),x(2,4)).
% xq is the point to interpolate, where, unless extrapolating,
% x(1,k) <= xq(k) <= x(2,k).
coder.inline('always');
coder.internal.prefer_const(ND,AUTOGRID);
ONE = coder.internal.indexInt(1);
% Construct the linear index. For example, if we settled on v(1,2,1,2)
% being the correct value to return, we will have arrived at it by
% constructing the linear index into v as follows:
% idx = 1 + (1 - 1)*0 + (2 - 1)*2 + (1 - 1)*4 + (2 - 1)*8 = 11.
% Consequently, we return v(11).
idx = ONE;
for d = 1:ND
    if abs(xq(d) - x(2,d)) <= abs(xq(d) - x(1,d))
        idx = idx + eml_lshift(ONE,d - ONE);
    end
end
vq = v(idx);