function this = applyScalarFunctionInPlace(fname,scalarfun,this)
%MATLAB Code Generation Private Method

%   Copyright 2017-2018 The MathWorks, Inc.
%#codegen
ZEROX = zeros('like',this.d);

ZEROX_RES = scalarfun(ZEROX);
if ZEROX_RES == ZEROX
    this.d = coder.internal.applyScalarFunctionInPlace(fname,scalarfun,this.d);
else
    % We're basically returning full
    [~,overflow] = coder.internal.bigProduct(this.m, this.n, true);
    coder.internal.assert(overflow == 0, 'Coder:toolbox:SparseFuncAlmostFull', fname);
    numalloc = max2(this.m*this.n,ONE);
    resd = coder.nullcopy(zeros(numalloc,1,'like',this.d));
    outIdx = ONE;
    for c = 1:this.n
        outRow = ONE;
        ridx = this.colidx(c);
        % Fill out f(0) and f(d(k)) until we hit the last nonzero in this column
        while ridx < this.colidx(c+1) && outRow <= this.m
            if outRow == this.rowidx(ridx)
                resd(outIdx) = scalarfun(this.d(ridx));
                ridx = ridx+1;
            else
                resd(outIdx) = ZEROX_RES;
            end
            outIdx = outIdx+1;
            outRow = outRow+1;
        end
        % Fill out f(0) for the rest of this column
        while outRow <= this.m
            resd(outIdx) = ZEROX_RES;
            outIdx = outIdx+1;
            outRow = outRow+1;
        end
    end
    this.d = resd;
    this.rowidx = coder.nullcopy(zeros(coder.ignoreConst(numalloc),1,'like',this.rowidx));
    this.maxnz = numalloc;
    outIdx = ONE;
    colIdx = ONE;
    for c = 1:this.n
        this.colidx(c) = colIdx;
        colIdx = colIdx + this.m;
        for r = 1:this.m
            this.rowidx(outIdx) = r;
            outIdx = outIdx+1;
        end
    end
    this.colidx(end) = this.m*this.n+1;
end
this.matlabCodegenUserReadableName = makeUserReadableName(this);
this = fillIn(this);
coder.internal.sparse.sanityCheck(this);

%--------------------------------------------------------------------------
