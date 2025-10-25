function C = pTimesTranspose(A, transposeA, B, transposeB)
%PTIMESTRANSPOSE matrix multiply with transposed inputs
%
%   PTIMESTRANSPOSE(A, transA, B, transB) performs a matrix-matrix multiply
%   of A and B applying transposes to A and B as appropriate. The two
%   transpose flags can have the following values:
%      0  No transpose
%      1  Non-conjugate transpose
%      2  Conjugate transpose
%
%   Example:
%       A = tall([ 1 2 3; 4 5 6 ]);
%       B = tall([ 7 8 9; 10 11 12 ]);
%       C = A'*B; % C is 2x2
%
%   See also: tall, tall/mtimes.

%   Copyright 2016-2024 The MathWorks, Inc.

allowedTypes = {'numeric', 'char', 'logical'};
A = tall.validateType(A, mfilename, allowedTypes, 1);
B = tall.validateType(B, mfilename, allowedTypes, 2);

% Special case for A'*B and A.'*B where both are tall
if istall(A) && istall(B) && (transposeB==0)
    [A, B] = validateSameTallSize(A, B);
    C = iTallTimesTranspose(A, B, transposeA);
    return;
end

% Transpose the inputs if requested
A = iMaybeTranspose(A, transposeA);
B = iMaybeTranspose(B, transposeB);

% Now we can simply multiply them
C = mtimes(A,B);

end

function C = iTallTimesTranspose(A, B, op)
% Do a times transpose two tall arrays given the operation type OP where:
%   op==1 means non-conjugating
%   op==2 means conjugating

C = chunkfun(@(a,b) iChunkTimesTranspose(a, b, op), A, B);
% sum(C,1) will generate a double input if C is an integer, keep track of
% the type of C for further validation when reshaping sum(C, 1).
headC = head(C, 1);
C = clientfun(@iReshapeC, sum(C, 1), headC, size(A), size(B));

aAdaptor = matlab.bigdata.internal.adaptors.getAdaptor(A);
bAdaptor = matlab.bigdata.internal.adaptors.getAdaptor(B);
if aAdaptor.NDims > 2
    error(message('MATLAB:transpose:NDArray'));
elseif bAdaptor.NDims > 2
    error(message('MATLAB:mtimes:inputsMustBe2D'));
end
C.Adaptor = setKnownSize(C.Adaptor, [getSizeInDim(aAdaptor, 2), getSizeInDim(bAdaptor, 2)]);
end

function X = iMaybeTranspose(X, op)
% Transpose an array if specified by OP, where:
%   op==0 means no transpose
%   op==1 means non-conjugating transpose
%   op==2 means conjugating transpose
%
% Note that tall inputs cannot be transposed (op must be 0)
if op==0
    return;
end

% We are about to transpose. 
% This will throw an appropriate error if the input is tall.
if op==1
    X = transpose(X);
elseif op==2
    X = ctranspose(X);
end
end

function C = iChunkTimesTranspose(A, B, op)
% Do a times transpose of one chunk of a pair of tall arrays being reduced
% in the tall dimension.
%   op==1 means non-conjugating
%   op==2 means conjugating
if op == 1
    C = reshape(A.'*B, 1, []);
else
    C = reshape(A'*B, 1, []);
end
end

function sumC = iReshapeC(sumC, headC, sizeA, sizeB)
% Reshape the output C and check for invalid integer types for two tall
% inputs of the same height.
isScalarInputs = all(sizeA == 1) && all(sizeB == 1);
isIntegerC = isinteger(headC);
if isIntegerC && ~isScalarInputs
    error(message('MATLAB:mtimes:integerNotSupported'));
end

if isIntegerC
    % If C was an integer, we need to cast sumC. For the rest of allowed
    % types, keep the type of sumC (double or single).
    sumC = cast(sumC, like=headC);
end

sumC = reshape(sumC, sizeA(2), sizeB(2));
end
