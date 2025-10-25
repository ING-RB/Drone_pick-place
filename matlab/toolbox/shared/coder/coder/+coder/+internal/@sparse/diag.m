function y = diag(this,aK)
%MATLAB Code Generation Private Method

%   Copyright 2017-2018 The MathWorks, Inc.
%#codegen

if nargin < 2
    k = ZERO;
    forceMToZero = false;
else
    if ~issparse(this)
        y = diag(this, full(aK));
        return
    end
    coder.internal.prefer_const(aK);
    coder.internal.assert(coder.internal.isConst(aK) ||...
        coder.const(~coder.internal.eml_option_eq('VariableSizing','DisableInInference')), ...
        'Coder:toolbox:diag_4', ...
        'IfNotConst','Fail');
    coder.internal.assert((coder.internal.isBuiltInNumeric(aK) || islogical(aK)) &&...
        isscalar(aK) && isreal(aK), ...
        'Coder:toolbox:diag_KmustBeRealIntScalar');
    if islogical(aK)
        fk = coder.internal.indexInt(full(aK));
    else
        fk = full(aK);
    end
    %TODO: fold the following assert into the previous one
    % this will be possible when coder recogonizes sparse logicals as
    % logicals
    coder.internal.assert(fk==floor(fk), 'Coder:toolbox:diag_KmustBeRealIntScalar');
    
    %check for very large k
    forceMToZero = fk >= this.n || fk <= -1*this.m;
    coder.internal.errorIf(coder.internal.isConst(isvector(this)) &&...
        isvector(this)&& ...
        ~isfinite(fk),...
        'MATLAB:diag:kthDiagInputNotFinite');
    
    
    k = coder.internal.indexInt(fk);
    
end

if coder.internal.isConst(isvector(this)) && isvector(this)
    y = vectorDiag(this, k);
elseif coder.internal.isConst(size(this)) && isequal(size(this),[0,0])
    y = this;
else
    coder.internal.errorIf((isvector(this)&& ~isscalar(this))...
        || (isscalar(this)&& k~=0),...
        'Coder:toolbox:diag_varsizedMatrixVector');
    y = matrixDiag(this, k, forceMToZero);
end
coder.internal.sparse.sanityCheck(y);
end




function D = vectorDiag(v,k)
coder.internal.prefer_const(k);
posk = max(ZERO,k);      % positive part of k
negk = abs(min(ZERO, k));% negative part of k
len = coder.internal.indexInt(length(v));
N = len+abs(k);
D = coder.internal.sparse.nullcopyLike(N,N,nnzInt(v), v);
D.d(1:nnzInt(v)) = v.d(1:nnzInt(v));


if(v.m == ONE)% row vector
    D.colidx = [ones(posk,1,'like',ONE);...         % pad on the left for positive k,
        v.colidx;...
        repmat(v.colidx(end), negk, 1)]; % and on the right for negative
    toFill = ONE;
    for col = 1:v.n
        if v.colidx(col)~= v.colidx(col + 1)%there is an element in this col
            D.rowidx(toFill) = col + negk; % adjust down for negative k
            toFill = toFill+1;
        end
    end
else% col vector
    if v.rowidx(ONE) == 0 %v contains only zero entries
        D.colidx(:) = ONE;
        D.rowidx(ONE) = ZERO;
        return;
    end
    if k >0
        % first nonzeros will be to the right
        D.colidx(1:k) = ONE;
    end
    D.rowidx(1:nnzInt(v)) = v.rowidx(1:nnzInt(v), 1) + negk;
    toFill = ONE;
    for i = ONE:nnzInt(v)
        for col = toFill:v.rowidx(i)
            D.colidx(col+posk)  = i;
        end
        toFill = v.rowidx(i)+1;
    end
    for col = (toFill+posk):(D.n+1)
        D.colidx(col) = nnzInt(v) + ONE;
    end
end
end

function x = matrixDiag(A,k, forceMToZero)
coder.internal.prefer_const(k);
coder.internal.prefer_const(forceMToZero);

% Determine length of diagonal
if A.m == A.n %square
    mTemp = A.n - abs(k);
elseif A.n > A.m %wide
    if k<0
        mTemp = A.m + k;
    elseif k > (A.n-A.m)
        mTemp = A.n - k;
    else
        mTemp = A.m;
    end
else %tall
    if k > 0
        mTemp = A.n - k;
    elseif k < (A.n - A.m)
        mTemp = A.m + k;
    else
        mTemp =  A.n;
    end
end
M = max(ZERO, mTemp);
if(forceMToZero)
    M = ZERO;
end
%always a column
N = ONE;
x = coder.internal.sparse.spallocLike(M,N,min(M,nnzInt(A)), A);


%find elements along desired diagonal
toFill = ONE;
for col = ONE:coder.internal.indexInt(A.n)
    [j, found] = locBsearch(A.rowidx, col-k, A.colidx(col), A.colidx(col+1));
    if found
        x.rowidx(toFill) = col - max(ZERO, k);
        x.d(toFill) = A.d(j);
        toFill = toFill +ONE;
    end
end

x.colidx = [ONE;toFill];

end
