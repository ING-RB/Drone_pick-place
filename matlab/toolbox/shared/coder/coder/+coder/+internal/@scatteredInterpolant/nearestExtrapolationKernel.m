function yi = nearestExtrapolationKernel(interpObj, xi, yi, ...
                                         nFuncVal, nSamplePts)
%

%   Copyright 2024 The MathWorks, Inc.

%#codegen

coder.inline('always')
coder.internal.prefer_const(nFuncVal, nSamplePts)

if ~allfinite(xi)
    yi(:) = coder.internal.interpolate.interpNaN(interpObj.sampleVal);
else
    [~, ptId] = interpObj.delTri.dsearch(xi);
    for j = 0:nFuncVal-1
        yi(j+1) = interpObj.sampleVal(ptId + j*nSamplePts);
    end
end
