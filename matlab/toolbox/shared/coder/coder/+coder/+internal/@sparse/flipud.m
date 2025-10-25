function y = flipud(this)
%MATLAB Code Generation Private Method

%   Copyright 2024 The MathWorks, Inc.
%#codegen
ml = this.m;
nl = this.n;
y = coder.internal.sparse([],[],zeros(0,'like',this.d),ml,nl,nnzInt(this)); 

ctr = ONE;
for i = 1:nl
    for j = (this.colidx(i+1)-1):-1:this.colidx(i)
        y.d(ctr) = this.d(j);
        y.rowidx(ctr) = ml-this.rowidx(j)+1;
        ctr = ctr + ONE;
    end
end
y.colidx = this.colidx;
