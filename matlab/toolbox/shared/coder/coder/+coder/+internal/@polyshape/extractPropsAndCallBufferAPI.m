function PG = extractPropsAndCallBufferAPI(pshape, d, jointType, miterLimit)
%MATLAB Code Generation Library Function
% Extract properties of the polyshape and call polybuffer in clipperAPI

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen
coder.inline('always');
subNumBnd = pshape.numboundaries;
subNumPts = pshape.polyImpl.polyNumPoints;
[subX, subY] = getVtxArray(pshape.polyImpl);
subIsHole = uint8(ishole(pshape));
[subStPtr, subEnPtr] = getBoundaryPtr(pshape.polyImpl);
subAreas = getBoundaryAreas(pshape.polyImpl);

[vx, vy] = coder.internal.clipperAPI.offset(subNumBnd, subNumPts, subX, subY, ...
                                            subIsHole, subStPtr, subEnPtr, subAreas, d, miterLimit, jointType);

PG = coder.internal.polyshape();
PG.polyImpl = addPoints(PG.polyImpl, vx, vy, numel(vx), ...
                        uint8(coder.internal.polyshapeHelper.boundaryTypeEnum.SolidCW));
PG.SimplifyState = 1;
PG.KeepCollinearPoints = pshape.KeepCollinearPoints;
