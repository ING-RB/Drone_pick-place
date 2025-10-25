function pgon = cleanup(pshape, d)
%MATLAB Code Generation Private Function

%   Copyright 2023-2024 The MathWorks, Inc.

%#codegen

pgonNumBnd = pshape.numboundaries;
pgonNumPts = pshape.polyImpl.polyNumPoints;
[pgonX, pgonY] = getVtxArray(pshape.polyImpl);
pgonIsHole = uint8(ishole(pshape));
[pgonStPtr, pgonEnPtr] = getBoundaryPtr(pshape.polyImpl);
pgonAreas = getBoundaryAreas(pshape.polyImpl);

[vx, vy] = coder.internal.clipperAPI.rmSliverOp(d, pgonNumBnd, ...
                                                pgonNumPts, pgonX, pgonY, pgonIsHole, pgonStPtr, pgonEnPtr, pgonAreas);

pgon = coder.internal.polyshapeHelper.polygon();
if ~(isempty(vx) || isempty(vy))
    pgon = addPoints(pgon, vx, vy, numel(vx), ...
                     uint8(coder.internal.polyshapeHelper.boundaryTypeEnum.SolidCW));
    pgon = pgon.resolveNesting();
    [issorted, cri, dir, refPt] = pshape.polyImpl.accessOrder.getProps();
    if issorted
        pgon = pgon.updateDerived(); % Need to update polyshape props to sort.
        pgon.accessOrder = sortBoundaries(pgon.accessOrder, pgon.boundaries, dir, cri, refPt);
    end
end
