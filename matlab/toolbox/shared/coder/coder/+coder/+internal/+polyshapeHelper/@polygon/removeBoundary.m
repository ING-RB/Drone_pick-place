function pg = removeBoundary(pg, bdIdx)
%MATLAB Code Generation Library Function
% Remove the boundary specified by the index

%   Copyright 2023-2024 The MathWorks, Inc.

%#codegen

unqBdIdx = unique(pg.accessOrder.getMappedIndex(bdIdx));
bdIdx = unique(bdIdx);

pg.numBoundaries = pg.numBoundaries - numel(unqBdIdx);
pg = pg.clearDerived();
totPtsRemoved = 0;
for idx = numel(unqBdIdx):-1:1
    [pg.boundaries, b, ptsErased] = eraseBoundary(pg.boundaries, unqBdIdx(idx));
    pg.nestingResolved = b & pg.nestingResolved;
    totPtsRemoved = totPtsRemoved + ptsErased;
end

pg.polyNumPoints = pg.polyNumPoints - totPtsRemoved;
pg.accessOrder = updateAccessOnRemove(pg.accessOrder, bdIdx, numel(bdIdx));
pg = pg.resolveNesting();

pg = pg.updateDerived();
