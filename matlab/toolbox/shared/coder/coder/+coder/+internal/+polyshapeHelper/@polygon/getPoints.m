function a_vertices = getPoints(pgon)
%MATLAB Code Generation Library Function
% Get the vertices of the polyshape

%   Copyright 2023 The MathWorks, Inc.

%#codegen

np = pgon.getNumPoints;
nc = pgon.getNumBoundaries;
npt = max(np + nc - 1, 0);

a_vertices = coder.nullcopy(zeros(npt,2));

if (npt == 0)
    return;
end

i = 1;
for it = 1:nc
    ic = pgon.accessOrder.getMappedIndex(it);       
    size1 = getBoundarySize(pgon.boundaries, ic) - 1;
    for j = 1:size1

        [a_vertices(i), a_vertices(i + npt)] = getCoordAtIdx(pgon.boundaries, ic, j);

        i = i + 1;
    end
    if (it < nc)
        a_vertices(i) = nan;
        a_vertices(i + npt) = nan;
        i = i + 1;
    end
end