function I = eyeLike(ndiag,m,n,egone)
%MATLAB Code Generation Private Method

%   Copyright 2017-2018 The MathWorks, Inc.
%#codegen
coder.internal.prefer_const(m,n);
ndiagInt = coder.internal.indexInt(ndiag);
I = coder.internal.sparse.nullcopyLike(m,n,ndiagInt,egone);
if issparse(egone)
    one = ones(1, 'like', egone.d(1));
else
    one = ones(1, 'like', egone);
end
for i=1:ndiagInt
    I.d(i) = one;
    I.rowidx(i) = i;
end

I.colidx(1) = ONE;
for c = 2:ndiagInt
    I.colidx(c) = c;
end
for c = ndiagInt+1:coder.internal.indexInt(n)+1
    I.colidx(c) = ndiagInt+1;
end
coder.internal.sparse.sanityCheck(I);