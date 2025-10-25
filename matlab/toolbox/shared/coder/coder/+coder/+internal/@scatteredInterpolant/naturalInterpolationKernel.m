function yi = naturalInterpolationKernel(interpObj, xi, yi, nFuncVal, ...
    nSamplePts, extrapFuncHandle)
%

%   Copyright 2024-2025 The MathWorks, Inc.

%#codegen
coder.internal.prefer_const(extrapFuncHandle)

% Constants defining the outcome of natural neighbor computation.
NATURAL_NBR_FAILED_OUTSIDE = coder.internal.indexInt(0); %#ok<NASGU>
NATURAL_NBR_FAILED_BOUNDARY = coder.internal.indexInt(1);
NATURAL_NBR_FAILED_INSIDE = coder.internal.indexInt(2);
NATURAL_NBR_OK = coder.internal.indexInt(3);

if ~allfinite(xi)
    yi(:) = coder.internal.interpolate.interpNaN(interpObj.sampleVal);
else
    [yi, nnOutcome] = coder.internal.scatteredInterpAPI.naturalNeighborInterpolation( ...
        interpObj.delTri, interpObj.sampleVal, nFuncVal, xi, yi);
    
    if nnOutcome == NATURAL_NBR_OK
        % Natural neighbor computation was successful.
        return
    elseif (nnOutcome == NATURAL_NBR_FAILED_BOUNDARY || ...
            nnOutcome == NATURAL_NBR_FAILED_INSIDE)
        coder.internal.warning('Coder:polyfun:naturalFallbackToLinear', ...
            coder.internal.flt2str(xi(1)), coder.internal.flt2str(xi(2)));
        % The point is either on boundary of convex hull or we encountered non-finites
        % during natural neighbor computation. Fallback to linear interpolation.
        yi = interpObj.linearInterpolationKernel(xi, yi, nFuncVal, ...
            nSamplePts, extrapFuncHandle);
    else
        % Point is outside convex hull, call the extrapolation method.
        yi = extrapFuncHandle(xi, yi, nFuncVal, nSamplePts);
    end
end