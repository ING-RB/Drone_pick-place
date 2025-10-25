function TF = ishole(pshape, I)
%MATLAB Code Generation Library Function
% ISHOLE Array of logicals indicating if the boundary is a hole or not.

%   Copyright 2023-2024 The MathWorks, Inc.

%#codegen

coder.internal.polyshape.checkScalar(pshape);

numboundaries = pshape.polyImpl.numBoundaries;
if (nargin == 1)
    if ~numboundaries
        TF = zeros(0,1,'logical');
    else
        TF = zeros(pshape.polyImpl.numBoundaries, 1,'logical');

        for i = 1:numboundaries
            TF(i) = pshape.polyImpl.getBoundaryIsHole(i);
        end
    end
else
    coder.internal.polyshape.checkEmpty(pshape);
    II = coder.internal.polyshape.checkIndex(pshape, I);
    numQueries = numel(II);

    TF = zeros(numQueries, 1,'logical');

    for i = 1:numQueries
        TF(i) = pshape.polyImpl.getBoundaryIsHole(II(i));
    end

end
