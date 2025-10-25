function tf = sparseHermitianSymmetricKernel(this, isSkew, symmetricCheck)
%MATLAB Code Generation Private Method

%   Copyright 2024 The MathWorks, Inc.
%#codegen

coder.internal.prefer_const(isSkew, symmetricCheck);
% Comparator switch
if islogical(this)
    if isSkew
        cmp = @(x,y)skewCmpLogical(x,y);
    else
        cmp = @(x,y)nonSkewCmp(x,y);
    end
else
    if isreal(this) || symmetricCheck % If it's a symmetric check, don't conjugate
        if isSkew
            cmp = @(x,y)skewCmp(x,y);
        else
            cmp = @(x,y)nonSkewCmp(x,y);
        end
    else
        if isSkew
            cmp = @(x,y)conjSkewCmp(x,y);
        else
            cmp = @(x,y)conjNonSkewCmp(x,y);
        end
    end
end

n = this.n;
ridx = this.rowidx;
coffset = this.colidx;

for j = 1:n
    for i = coffset(j):this.colidx(j+1)-1
        rowOfElem = ridx(i);
        % In a hermitian matrix a(i,j) = conj(a(j,i)). Get the offset
        % to the column with index = 'rowOfElem'.
        offsetForConjElem = coffset(rowOfElem);
        % Column expected to contain the conjugate, should contain
        % atleast one element

        % The row index of the conjugate element should be equal to the
        % column of the current element.
        if( offsetForConjElem >= this.colidx(rowOfElem+ONE) ...
                || ridx(offsetForConjElem) ~= j ...
                || cmp(this.d(offsetForConjElem), this.d(i)))
            tf = false;
            return
        end
        coffset(rowOfElem) = coffset(rowOfElem) + ONE;
    end
end
tf = true;
end

%--------------------------------------------------------------------------
function tf = nonSkewCmp(x,y)
coder.inline('always')
tf = (x ~= y);
end

function tf = skewCmp(x,y)
coder.inline('always')
tf = (x ~= (-y));
end

function tf = skewCmpLogical(x,y)
coder.inline('always')
tf = (x | y);
end

function tf = conjNonSkewCmp(x,y)
coder.inline('always')
tf = (x ~= conj(y));
end

function tf = conjSkewCmp(x,y)
coder.inline('always')
tf = (x ~= (-1*conj(y)));
end