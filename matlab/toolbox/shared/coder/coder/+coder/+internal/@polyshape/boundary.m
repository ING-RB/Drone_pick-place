function [X, Y] = boundary(pshape, i)
%MATLAB Code Generation Library Function
% BOUNDARY Get vertices of the polyshape boundary or of single boundary
% inside the polyshape

%   Copyright 2022 The MathWorks, Inc.

%#codegen

coder.internal.polyshape.checkScalar(pshape);

if nargin == 1
    if pshape.isEmptyShape()
        X = zeros(0, 1);
        Y = zeros(0, 1);
        return;
    end
    II = 1:pshape.numboundaries;
else
    coder.internal.polyshape.checkEmpty(pshape);
    II = coder.internal.polyshape.checkIndex(pshape, i);
end

[X, Y] = getBoundary(pshape.polyImpl, II);
