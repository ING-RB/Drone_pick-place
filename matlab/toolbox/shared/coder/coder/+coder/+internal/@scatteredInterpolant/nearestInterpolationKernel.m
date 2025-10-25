function yi = nearestInterpolationKernel(interpObj, xi, yi, ...
                                         nFuncVal, nSamplePts, extrapByMethod, extrapFuncHandle)

% Loop body for nearest method. Both, interpolation and extrapolation are
% performed by the same function 'dsearch'.
% 'xi' is a single query point.
% 'yi' is a temp storage of size(obj.sampleVal, 2:end) i.e number of values
% being computed for this point.
% 'nFuncVal' -> number of vals for multi-valued interpolation, 1 otherwise.
% 'nSamplePts' -> number of sample points after duplicates are merged.
% 'extrapByMethod' is true if extrapolation should also be performed in
% current call.

%   Copyright 2024 The MathWorks, Inc.

%#codegen

coder.inline('always');
coder.internal.prefer_const(extrapFuncHandle, extrapByMethod, nFuncVal, nSamplePts)

if ~allfinite(xi)
    yi(:) = coder.internal.interpolate.interpNaN(interpObj.sampleVal);
else
    [isInConvexHull, ptId] = interpObj.delTri.dsearch(xi);
    if isInConvexHull || extrapByMethod
        for j = 0:nFuncVal-1
            yi(j+1) = interpObj.sampleVal(ptId + j*nSamplePts);
        end
    else
        yi = extrapFuncHandle(xi, yi, nFuncVal, nSamplePts);
    end
end
