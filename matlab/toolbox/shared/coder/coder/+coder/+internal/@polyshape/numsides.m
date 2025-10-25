function NV = numsides(pshape, I)
%MATLAB Code Generation Library Function
% NUMSIDES Get number of sides in polyshape or of boundary inside polyshape

%   Copyright 2022 The MathWorks, Inc.

%#codegen

coder.internal.polyshape.checkConsistency(pshape, nargin);

if (nargin == 1)
    %does not error if polyshape is empty
    %does not warn if polyshape is not simplified
    n = coder.internal.polyshape.checkArray(pshape);
    NV = zeros(n);
    for i=1:numel(pshape)
        NV(i) = pshape(i).polyImpl.getNumPoints();
    end
else
    coder.internal.polyshape.checkScalar(pshape);
    coder.internal.polyshape.checkEmpty(pshape);
    II = coder.internal.polyshape.checkIndex(pshape, I);
    n = length(II);
    NV = zeros(n, 1);
    for i=1:n
        NV(i) = pshape.polyImpl.getNumPointsInBoundary(II(i));
    end
end
