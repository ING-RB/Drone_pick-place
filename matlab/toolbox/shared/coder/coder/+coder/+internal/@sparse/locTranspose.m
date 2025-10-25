function y = locTranspose(this,doConj,y)
%MATLAB Code Generation Private Method

%   Copyright 2017-2018 The MathWorks, Inc.
%#codegen
coder.inline('always');
if nargin == 1 || islogical(this.d)
    doConj = false;
else
    coder.internal.prefer_const(doConj);
end

ml = this.m;
nl = this.n;

if nargin < 3
    % Allocate output
    y = coder.internal.sparse([],[],zeros(0,'like',this.d),nl,ml,nnzInt(this)); 
end
if(isempty(this))
    return;
end
y.colidx(:) = ZERO;

% cumulative sum to compute column offsets
for k = 1:nnzInt(this)
    idx = this.rowidx(k)+ONE;
    y.colidx(idx) = y.colidx(idx)+ONE;
end
y.colidx(1) = 1;
for k = 2:ml+1
    y.colidx(k) = y.colidx(k) + y.colidx(k-1);
end
counts = zeros(ml,1,'like',ONE);
for c = 1:nl
    idx = this.colidx(c);
    while (idx < this.colidx(c+1))
        r = this.rowidx(idx);
        outridx = counts(r) + y.colidx(r);
        if doConj
            y.d(outridx) = conj(this.d(idx));
        else
            y.d(outridx) = this.d(idx);
        end
        y.rowidx(outridx) = c;
        counts(r) = counts(r)+1;
        idx = idx+1;
    end
end

%--------------------------------------------------------------------------
