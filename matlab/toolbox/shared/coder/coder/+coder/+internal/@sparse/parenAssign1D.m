function this = parenAssign1D(this, rhs, linidx, sorted)
%MATLAB Code Generation Private Method

% 1D indexing for coder.internal.sparse
% sorted is a boolean indicating whether linidx is sorted


%   Copyright 2016-2023 The MathWorks, Inc.
%#codegen
if nargin < 4
    sorted = false;
else
    coder.internal.prefer_const(sorted);
end
validateIndexType(linidx);
[lowOrderSize, highOrderSize] = coder.internal.bigProduct(this.m,this.n,false);
scalarRhs = coder.internal.isConst(isscalar(rhs)) && isscalar(rhs);
coder.internal.assert(goodNAssign(lowOrderSize,highOrderSize,rhs,linidx) || scalarRhs, ...
                      'MATLAB:subsassignnumelmismatch');
coder.internal.errorIf(isreal(this) && ~isreal(rhs), 'Coder:builtins:LhsRhsComplexMismatch');

if issparse(linidx)
    this = parenAssign1D(this,rhs,nonzeros(linidx), sorted);
elseif ischar(linidx)
    % s(:) = x is just a copy
    coder.inline('always');
    this = parenAssign1DSpan(this,rhs,scalarRhs, highOrderSize);
else
    this = parenAssign1DNumeric(this,rhs,linidx, highOrderSize, sorted);
end

%--------------------------------------------------------------------------

function this = parenAssign1DSpan(this,rhs,scalarRhs,overflow)
coder.inline('always');
coder.internal.assert(overflow == 0, 'Coder:toolbox:SparseColonOverflow');
this = parenAssignAllSpan(this,rhs,scalarRhs,this.m*this.n,1);

%--------------------------------------------------------------------------

function this = parenAssign1DNumeric(this,rhs,linidx,overflow,sorted)
% In this function, we look for row indices from the same column and assign
% them altogether
if overflow == 0
    validateNumericIndex(ONE,this.m*this.n,linidx);
else
    validateNumericIndex(ONE,intmax(coder.internal.indexIntClass),linidx);
end
coder.internal.prefer_const(sorted);
scalarRhs = coder.internal.isConst(isscalar(rhs)) && isscalar(rhs);
[rhs,linidx,~] = coder.internal.sortSparseParenAssignInputs(rhs,linidx,1,sorted);
nidx = numel(linidx);
lb = ZERO; % lower bound of a segment of row indices
cnt = ZERO; % count the total number of row indices from the same col
rowsToAssign = zeros(nidx,1,'like',ZERO); % preallocating space for row indices
prevcol = ZERO;
for k = 1:nidx+1
    if k <= nidx
        idx = linidx(k);
        [row,col] = ind2sub(size(this),idx);
        rowsToAssign(k) = row;
    else
        col = -1;
    end
    if col == prevcol
        % if same col do nothing
        cnt = cnt + 1;
        continue
    else
        % if get to a new col, assign rows from previous col
        if cnt > 0
            if scalarRhs
                rhsv = rhs(1,1);
            else
                rhsv = zeros(cnt,1,'like',this.d);
                for i = 1:cnt
                    rhsv(i) = rhs(lb+i-1);
                end
            end
            isSqueezed = false;
            sorted = true;
            this = parenAssign2D(this,rhsv,rowsToAssign(lb:lb+cnt-1),prevcol,isSqueezed,sorted);
        end
        lb = coder.internal.indexInt(k);
        cnt = ONE;
        prevcol = coder.internal.indexInt(col);
    end
end

%--------------------------------------------------------------------------

function out = goodNAssign(sizeLOW,sizeHIGH,rhs,linidx)
if issparse(rhs)
    sr = coder.internal.indexInt(size(rhs));
    [lowOrderRHS, highOrderRHS] = coder.internal.bigProduct(sr(1),sr(2),false); 
    if ischar(linidx)
        lowOrderLHS = sizeLOW;
        highOrderLHS = sizeHIGH;
    else
        sl = coder.internal.indexInt(size(linidx));
        [lowOrderLHS, highOrderLHS] = coder.internal.bigProduct(sl(1),sl(2),false);
    end
    out = lowOrderLHS==lowOrderRHS && highOrderLHS == highOrderRHS;
else
    if ischar(linidx)
        out = numel(rhs) == sizeLOW;
    else
        out = numel(rhs) == numel(linidx);
    end
end


%--------------------------------------------------------------------------

function y = ZERO
y = coder.internal.indexInt(0);

%--------------------------------------------------------------------------
function y = ONE

y = coder.internal.indexInt(1);

%--------------------------------------------------------------------------
