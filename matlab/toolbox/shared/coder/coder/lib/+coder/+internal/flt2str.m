function str = flt2str(x,D)
%MATLAB Code Generation Private Function
%
%   This function is for formatting numbers to appear in errors and
%   warnings. Returns a fixed-length string. If the target is 'mex' and
%   extrinsic calls are enabled (or if x is a constant), returns a string
%   represenation of scalar x formatted to '%M.De' where M = D+8. D must be
%   a constant. If D is not supplied, it defaults to 15 for double
%   precision x and 7 for single precision x. Returns 'NaN' for other
%   targets or if extrinsic calls are not enabled.

%   Copyright 2010-2017 The MathWorks, Inc.
%#codegen

coder.extrinsic('sprintf');
coder.internal.prefer_const(x);
if nargin < 2
    if isa(x,'single')
        D = 7;
    else
        D = 15;
    end
else
    coder.internal.prefer_const(D);
end
if isfloat(x) && (coder.target('MATLAB') || ...
        coder.internal.isConst(x) || ...
        (coder.internal.get_eml_option('MXArrayCodeGen') && ...
        (coder.target('MEX') || ...
        coder.target('SFUN'))))
    n = coder.const(D+8);
    rfmt = coder.const(sprintf('%%%d.%de',n,D));
    cfmt = coder.const(sprintf('%%%d.%de %%c%%%d.%dei',n,D,n,D));
    if imag(x) < 0
        sgn = '-';
        xr = real(x);
        xi = -imag(x);
    else
        sgn = '+';
        xr = real(x);
        xi = imag(x);
    end
    if coder.internal.isConst(x)
        if isreal(x)
            str = coder.const(sprintf(rfmt,x));
        else
            str = coder.const(sprintf(cfmt,xr,sgn,xi));
        end
    else
        CZERO = char(0);
        if isreal(x)
            str = eml_expand(CZERO,[1,n]);
            str = sprintf(rfmt,x);
        else
            str = eml_expand(CZERO,[1,coder.const(2*n+3)]);
            str = sprintf(cfmt,xr,sgn,xi);
        end
    end
else
    str = 'NaN';
end
