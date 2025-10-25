function PG = extractPropsAndCallSimplifyAPI(subject, keepc)
%MATLAB Code Generation Library Function
% Extract properties of the polyshape and call simplify in clipperAPI

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

coder.inline('always');
subNumBnd = subject.numboundaries;
subNumPts = subject.polyImpl.polyNumPoints;
[subX, subY] = getVtxArray(subject.polyImpl);
subIsHole = uint8(ishole(subject));
[subStPtr, subEnPtr] = getBoundaryPtr(subject.polyImpl);
subAreas = getBoundaryAreas(subject.polyImpl);
subFillRule = subject.polyImpl.getFillingRule();

[vx, vy] = coder.internal.clipperAPI.simplify(subNumBnd, subNumPts, subX, subY, ...
                                              subIsHole, subStPtr, subEnPtr, subAreas, keepc, subFillRule);

PG = coder.internal.polyshape();
PG.polyImpl = addPoints(PG.polyImpl, vx, vy, numel(vx), ...
                        uint8(coder.internal.polyshapeHelper.boundaryTypeEnum.SolidCW));
