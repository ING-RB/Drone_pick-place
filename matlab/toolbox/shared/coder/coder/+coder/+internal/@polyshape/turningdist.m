function S = turningdist(P, Q)
%MATLAB Code Generation Library Function

% Copyright 2023 The MathWorks, Inc.

%#codegen

if nargin == 1
    coder.internal.assert(isvector(P), 'MATLAB:polyshape:vectorPolyshapeError');
    coder.internal.polyshape.checkScalar(P);  % remove when array of objects is supported
    Q = P;
else
    coder.internal.assert(isa(Q,'coder.internal.polyshape'), ...
        'MATLAB:polyshape:polyshapeTypeError');
    coder.internal.polyshape.checkScalar(Q); % remove when array of objects is supported
end

coder.internal.errorIf(numboundaries(P) > 1, 'MATLAB:polyshape:firstOneBoundary');
coder.internal.errorIf(numboundaries(Q) > 1, 'MATLAB:polyshape:secondOneBoundary')

isPEmpty = isEmptyShape(P);
isQEmpty = isEmptyShape(Q);

if ~isPEmpty && ~isQEmpty
    R = polyCompare(P.polyImpl, Q.polyImpl);
    S = R(1);
elseif xor(isPEmpty, isQEmpty)
    S = Inf;
else
    S = 0;
end
   
