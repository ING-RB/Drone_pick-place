function dimagree = isImplicitExpansionCompatible(x,y)
%MATLAB Code Generation Private Function
%
%   Checks that the sizes of x and y are compatible for implicit expansion
%   (i.e. in the bsxfun sense).

%   Copyright 2021 The MathWorks, Inc.
%#codegen

if coder.target('MATLAB')
    dimagree = true;
    for k = 1:min(ndims(x),ndims(y))
        sxk = size(x,k);
        syk = size(y,k);
        dimagree = dimagree && (sxk == 1 || syk == 1 || sxk == syk);
    end
else
    coder.internal.allowEnumInputs;
    coder.internal.allowHalfInputs;
    ndx = coder.internal.ndims(x);
    ndy = coder.internal.ndims(y);
    ND = coder.const(eml_min(ndx,ndy));
    dimagree = true;
    for k = coder.unroll(1:ND)
        sxk = coder.internal.indexInt(size(x,k));
        syk = coder.internal.indexInt(size(y,k));
        dimagree = dimagree && (sxk == 1 || syk == 1 || sxk == syk);
    end
end
