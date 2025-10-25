function x = castLike(obj, a)
%This function is for internal use only. It may be removed in the future.

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

    coder.internal.assert(isa(a,"matlabshared.spatialmath.internal.SpatialMatrixBase"), "shared_spatialmath:matobj:TransformExpected");
    x = cast(a, underlyingType(obj));
end
