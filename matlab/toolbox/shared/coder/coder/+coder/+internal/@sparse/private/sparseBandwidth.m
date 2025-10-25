function [lw, uw] = sparseBandwidth(this)
%MATLAB Code Generation Private Method

% Kernel to get the bandwidth of sparse matrix in indexInt class

%   Copyright 2024 The MathWorks, Inc.
%#codegen
coder.inline('always');
n = this.n;
uw = ZERO;
lw = ZERO;
for j = 1:n
    if this.colidx(j) ~= this.colidx(j+1)
        if j > this.rowidx(this.colidx(j))
            uw = max(uw, j - this.rowidx(this.colidx(j)) );
        end
        if this.rowidx(this.colidx(j+1)-1) > j
            lw = max(lw, this.rowidx(this.colidx(j+1)-1) - j );
        end
    end
end
end