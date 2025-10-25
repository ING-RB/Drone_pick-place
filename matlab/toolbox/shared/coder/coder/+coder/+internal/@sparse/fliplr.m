function y = fliplr(this)
%MATLAB Code Generation Private Method

%   Copyright 2024 The MathWorks, Inc.
%#codegen
ml = this.m;
nl = this.n;
y = coder.internal.sparse([],[],zeros(0,'like',this.d),ml,nl,nnzInt(this)); 

prefixSum = coder.internal.indexInt(0);
ctr = ONE;
for i = nl:-1:1
    y.colidx(nl-i+1) = prefixSum + 1;
    nc = (this.colidx(i+1) - this.colidx(i));
    prefixSum = prefixSum + nc;

    for j = this.colidx(i):(this.colidx(i+1)-1)
        y.d(ctr) = this.d(j);
        y.rowidx(ctr) = this.rowidx(j);
        ctr = ctr + ONE;
    end
end
y.colidx(nl+1) = this.maxnz + 1;
