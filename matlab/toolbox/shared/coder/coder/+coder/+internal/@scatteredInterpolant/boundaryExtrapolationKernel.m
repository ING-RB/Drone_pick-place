function yi = boundaryExtrapolationKernel(interpObj, xi, yi, nFuncVal, nSamplePts)
%

%   Copyright 2024 The MathWorks, Inc.

%#codegen
[vxIds, ~, vxBcoords, numVxs, ~] = ...
    coder.internal.scatteredInterpAPI.nearestOnHull(interpObj.delTri, xi);
for j = 0:nFuncVal-1
    yi(j+1) = 0;
    for i = 1:numVxs
        yi(j+1) = yi(j+1) + (interpObj.sampleVal(vxIds(i) + j*nSamplePts)*vxBcoords(i));
    end
end
