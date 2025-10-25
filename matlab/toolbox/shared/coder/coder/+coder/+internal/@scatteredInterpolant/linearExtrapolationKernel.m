function yi = linearExtrapolationKernel(interpObj, xi, yi, nFuncVal, nSamplePts)
%

%   Copyright 2024 The MathWorks, Inc.

%#codegen

[vxIds, hullIds, vxBcoords, numVxs, nearestVec] = ...
    coder.internal.scatteredInterpAPI.nearestOnHull(interpObj.delTri, xi);
gradientVec = coder.nullcopy(zeros([1 2], 'double'));
for j = 0:nFuncVal-1
    boundaryVal = interpObj.sampleVal(vxIds(1) + j*nSamplePts)*vxBcoords(1);
    gradientVec(1) = interpObj.bndryGradients(1,j+1,hullIds(1))*vxBcoords(1);
    gradientVec(2) = interpObj.bndryGradients(2,j+1,hullIds(1))*vxBcoords(1);
    for i = 2:numVxs
        boundaryVal = boundaryVal + (interpObj.sampleVal(vxIds(i) + j*nSamplePts)*vxBcoords(i));
        gradientVec(1) = gradientVec(1) + interpObj.bndryGradients(1,j+1,hullIds(i))*vxBcoords(i);
        gradientVec(2) = gradientVec(2) + interpObj.bndryGradients(2,j+1,hullIds(i))*vxBcoords(i);
    end
    yi(j+1) = boundaryVal + (nearestVec(1)*gradientVec(1) + nearestVec(2)*gradientVec(2));
end
