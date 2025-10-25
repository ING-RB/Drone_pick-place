function [bdObj, resolveNest, ptsErased] = eraseBoundary(bdObj, bndIdx)
%

%   Copyright 2023-2024 The MathWorks, Inc.
%#codegen

[bdStPtr, bdEnPtr] = getBoundary(bdObj, bndIdx);

bdObj.vertices = bdObj.vertices.eraseVertices(bdStPtr, bdEnPtr);
ptsErased = getBoundarySize(bdObj, bndIdx);

nPts = bdEnPtr - bdStPtr + 1;
for k = bndIdx+1:numel(bdObj.stPtr)
    bdObj.stPtr(k) = bdObj.stPtr(k) - nPts;
    bdObj.enPtr(k) = bdObj.enPtr(k) - nPts;
end

% Returns false if resolveNesting has to be rerun
resolveNest = true;
if bdObj.bType(bndIdx) == coder.internal.polyshapeHelper.boundaryTypeEnum.AutoSolid ...
        || bdObj.bType(bndIdx) == coder.internal.polyshapeHelper.boundaryTypeEnum.AutoHole
    resolveNest = false;
end

% Clean up the boundary properties
bdObj = bdObj.removeBndProps(bndIdx);
