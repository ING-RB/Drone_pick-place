function this = parenAssignAllSpan(this,rhs,scalarRhs,nAssign,nIndices)
%MATLAB Code Generation Private Function

% Helper to compute s(:) = x and s(:,:) = x

%   Copyright 2016-2018 The MathWorks, Inc.

%#codegen
coder.inline('always');
coder.internal.prefer_const(nIndices);
if scalarRhs
    rhsScalar = full(rhsSubsref(rhs,1,1));
    if rhsScalar == 0
        % All zero sparse
        for k = 1:this.n+1
            this.colidx(k) = ONE;
        end
    else
        % All non-zero sparse
        numalloc = max2(ONE,nAssign);
        this.rowidx = coder.nullcopy(zeros(numalloc,1,'like',this.rowidx));
        this.d = coder.nullcopy(zeros(numalloc,1,'like',this.d));
        this.d(:) = rhsScalar;
        this.maxnz = numalloc;
        ridx = ONE;
        cidx = ONE;
        for c = 1:this.n
            cidx = cidx+this.m;
            this.colidx(c+1) = cidx;
            for r = 1:this.m
                this.rowidx(ridx) = r;
                ridx = ridx+1;
            end
        end
    end
else
    % Just convert rhs to sparse
    if issparse(rhs)
        if nIndices == 1
            % TODO: Use reshape
            if isrow(this)
                this = rhs(:).';
            elseif iscolumn(this)
                this = rhs(:);
            else
                idx = find(rhs);
                [ii,jj] = ind2sub(size(this),idx);
                this = sparse(ii,jj,cast(nonzeros(rhs),'like',this.d),this.m,this.n);
            end
        else
            this = rhs;
        end
    else
        this = sparse(coder.internal.matrixReshapeValExpr(cast(rhs,'like',this.d),size(this,1),size(this,2)));
    end
end

%--------------------------------------------------------------------------
