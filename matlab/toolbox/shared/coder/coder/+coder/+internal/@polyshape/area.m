function A = area(pshape, I)
%MATLAB Code Generation Library Function
% Obtain area of polyshape or boundary inside polyshape

%   Copyright 2022 The MathWorks, Inc.

%#codegen

coder.internal.polyshape.checkConsistency(pshape, nargin);

if (nargin == 1)
    n = coder.internal.polyshape.checkArray(pshape);
    A = zeros(n);
    for i=1:numel(pshape)
        if ~pshape(i).isEmptyShape()
            A(i) = pshape(i).polyImpl.getArea();
        end
    end
else
    coder.internal.polyshape.checkScalar(pshape);
    coder.internal.polyshape.checkEmpty(pshape);
    II = coder.internal.polyshape.checkIndex(pshape, I);
    A = zeros(length(II), 1);
    for i=1:length(II)
        A(i) = getBoundaryArea(pshape.polyImpl, II(i));
    end
end