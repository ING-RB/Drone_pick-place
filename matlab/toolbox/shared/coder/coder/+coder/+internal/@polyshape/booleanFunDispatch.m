function [pgon, shapeId, vertexId] = booleanFunDispatch(subject, clip, collinear, boolFunEnum, simplify)
%MATLAB Code Generation Library Function
% Wrapper function used in boolean functions to extract polyshape properties
% call clipperAPI.

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

subNumBnd = subject.numboundaries;
clipNumBnd = clip.numboundaries;

subNumPts = subject.polyImpl.polyNumPoints;
clipNumPts = clip.polyImpl.polyNumPoints;

[subX, subY] = getVtxArray(subject.polyImpl);
[clipX, clipY] = getVtxArray(clip.polyImpl);

subIsHole = uint8(subject.polyImpl.getIsHole());
clipIsHole = uint8(clip.polyImpl.getIsHole());

[subStPtr, subEnPtr] = getBoundaryPtr(subject.polyImpl);
[clipStPtr, clipEnPtr] = getBoundaryPtr(clip.polyImpl);
subAreas = getBoundaryAreas(subject.polyImpl);
clipAreas = getBoundaryAreas(clip.polyImpl);

subFillRule = subject.polyImpl.getFillingRule();
clipFillRule = clip.polyImpl.getFillingRule();

[vx, vy, shapeId, vertexId] = ...
    coder.internal.clipperAPI.boolBinaryOp(subNumBnd, clipNumBnd, ...
                                           subNumPts, clipNumPts, subX, subY, ...
                                           clipX, clipY, subIsHole, clipIsHole, ...
                                           subStPtr, subEnPtr, clipStPtr, clipEnPtr, ...
                                           subAreas, clipAreas, collinear, boolFunEnum, ...
                                           subFillRule, clipFillRule, simplify);

pgon = coder.internal.polyshapeHelper.polygon();
if ~(isempty(vx) || isempty(vy))
    pgon = addPoints(pgon, vx, vy, numel(vx), ...
                     uint8(coder.internal.polyshapeHelper.boundaryTypeEnum.SolidCW));
    pgon = pgon.resolveNesting();
end
