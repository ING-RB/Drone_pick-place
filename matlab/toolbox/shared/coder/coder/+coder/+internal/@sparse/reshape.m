function B = reshape(A, varargin)
%#codegen

%   Copyright 2017-2023 The MathWorks, Inc.
coder.internal.prefer_const(varargin);
narginchk(2,Inf);
if ~issparse(A)
    newArgs = cell(nargin-1);
    for i = coder.unroll(1:nargin-1)
        newArgs{i} = full(varargin{i});
    end
    B = reshape(A, newArgs{1:nargin-1});
    return;
end
if nargin==2
    coder.internal.assert(nargin ~= 2 ||...
        numel(varargin{1}) < 3,...
        'MATLAB:reshape:sparseNDmatrix');
    coder.internal.assert(nargin ~= 2 ||...
        (~isempty(varargin{1}) && ~isscalar(varargin{1})),...
        'MATLAB:getReshapeDims:sizeVector');
    
    B = reshape(A, varargin{1}(1), varargin{1}(2));
    return
end

coder.internal.assert(~issparse(A) || nargin < 4, ...
    'MATLAB:reshape:sparseNDmatrix');

coder.internal.errorIf(isempty(varargin{1}) &&...
    isempty(varargin{2}),...
    'MATLAB:getReshapeDims:unknownDim');


sizeA = coder.internal.indexInt(size(A));

if isempty(varargin{1})
    coder.internal.assertValidSizeArg(varargin{2});
    coder.internal.assert(varargin{2} >= 0, 'MATLAB:checkDimCommon:nonnegativeSize'); 
    newN = coder.internal.indexInt(varargin{2});
    newM = calculateOtherDimension(newN, sizeA);
elseif isempty(varargin{2})
    coder.internal.assertValidSizeArg(varargin{1});
    coder.internal.assert(varargin{1} >= 0, 'MATLAB:checkDimCommon:nonnegativeSize');
    newM = coder.internal.indexInt(varargin{1});
    newN = calculateOtherDimension(newM, sizeA);
else
    coder.internal.assertValidSizeArg(varargin{:});
    coder.internal.assert(varargin{1} >= 0 &&...
        varargin{2} >= 0, 'MATLAB:checkDimCommon:nonnegativeSize');
    newM = coder.internal.indexInt(varargin{1});
    newN = coder.internal.indexInt(varargin{2});
    assertSameNumel(newM,newN,sizeA);
end


B = coder.internal.sparse.spallocLike(newM, newN, nnzInt(A), A );

if isempty(B)
    return;
end

colWriteHead = 1;
for col = 1:A.n
    startRow = A.colidx(col);
    endRow = A.colidx(col+1)-1;
    
    for offset = 0:(endRow-startRow)
        %FIXME: calculating linear index can overflow. might need to keep track of
        %"where we are" in the new matrix based on how we are moving through the
        %old one?
        
        oldLinearIndex = sub2ind(size(A), A.rowidx(startRow+offset), col);
        [newRow, newColumn] = ind2sub([newM, newN],oldLinearIndex);
        
        B.rowidx(startRow+offset) = newRow;
        B.d(startRow+offset) = A.d(startRow+offset);
        while newColumn >= colWriteHead
            B.colidx(colWriteHead) = startRow+offset;
            colWriteHead = colWriteHead+1;
        end
    end
end

B.colidx(colWriteHead:end) = A.colidx(end);

coder.internal.sparse.sanityCheck(B);
end



function out = calculateOtherDimension(knownDimension, inputDimensions)
coder.internal.prefer_const(knownDimension);
coder.internal.prefer_const(inputDimensions);

coder.internal.assert(knownDimension ~= 0 ||...
    (inputDimensions(1) == 0 || inputDimensions(2) == 0),...
    'Coder:MATLAB:getReshapeDims_notSameNumel');
if knownDimension == 0
    out = coder.internal.indexInt(0);
    return;
end


[oldSize, oldSizeCarry] = coder.internal.bigProduct(inputDimensions(1), inputDimensions(2), true);


if oldSizeCarry == 0
    %this is the error that coder gives for full matrices, but not what
    %MATLAB gives (which is more specific to incompatible sizes)
    coder.internal.assert(oldSizeCarry ~=0 ||...
        rem(oldSize, knownDimension) == 0,...
        'Coder:MATLAB:getReshapeDims_notSameNumel');
    out = oldSize/knownDimension;
else
    % we know knownDimension ~=0, so:
    % prod(inputSize) = knownDimension*out <=> 
    % prod(inputSize)/knownDimension = out <=>
    % x*y = knownDimension && ( inputSize(1) / x)*(inputSize(2)/ y) = out
    
    % to construct x and y, we need to make sure:
    % 1) they evenly divide the appropriate input size
    % 2) their product is knownDimension
    % If we use the GCD of the appropriate size, these conditions are met.
    % (1) is true since the gcd is a divisor of the size (by construction),
    % and (2) is true for the following reason:
    
    % Let A = a_1 ... a_n be the prime factors of inputDimensions(1) (with
    % repeats), and let B = b_1 ... b_n be the prime factors of input
    % dimensions(2). Then, if knownDimension is a legitimate size, its
    % prime factors together with the outputs prime factors will be a
    % partition of [A,B]. That is, the prime factors of knownDimension are
    % a subset of [A,B]. So, if we let x be the product of all prime
    % factors that come from A (i.e. gcd(knownDimension,
    % inputDimensions(1))), and y be the product of all the prime factors
    % that come from B (i.e. gcd(knownDimension/x, inputDimensions(2))),
    % then there should be no "extra" factors and x*y = knownDimension.
    
    firstGCD = gcd(knownDimension, inputDimensions(1)); %x, in above explanation
    reducedKnown = coder.internal.indexDivide(knownDimension, firstGCD); %removes prime factors that come from A
    reducedFirst = coder.internal.indexDivide(inputDimensions(1) , firstGCD);
    
    secondGCD = gcd(reducedKnown, inputDimensions(2)); %y, in above explanation
    reducedKnown = coder.internal.indexDivide(reducedKnown , secondGCD);%removes prime factors that come from B
    reducedSecond = coder.internal.indexDivide(inputDimensions(2) , secondGCD);
     
    %any remaining factors are not in A or B, so this cannot be a
    %legitimate size. This also double-checks that x*y == knownDimension
    coder.internal.assert(reducedKnown == 1,...
        'Coder:MATLAB:getReshapeDims_notSameNumel');
    
    [out, outOverflow] = coder.internal.bigProduct(reducedFirst, reducedSecond, true);
    
    MAXI = intmax(coder.internal.indexIntClass);
    coder.internal.assert(outOverflow==0, 'Coder:toolbox:SparseMaxSize', MAXI);
end
end


function assertSameNumel(n,m,oldSize)
coder.internal.prefer_const(n,m,oldSize);

[left, leftCarry] = coder.internal.bigProduct(n,m, false);
[right, rightCarry] = coder.internal.bigProduct(oldSize(1), oldSize(2), false);
coder.internal.assert(left==right &&...
    leftCarry==rightCarry,...
    'Coder:MATLAB:getReshapeDims_notSameNumel');
end


% LocalWords:  NDmatrix
