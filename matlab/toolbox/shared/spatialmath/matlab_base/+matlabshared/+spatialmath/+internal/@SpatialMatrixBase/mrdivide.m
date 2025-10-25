function o = mrdivide(obj1, obj2)
%mrdivide Pose composition with right division
%   T = T1/T2 composes two different se3 objects, T1
%   and the inverse of T2. This is the same as T = T1*inv(T2).
%   Either T1 or T2 must be a scalar. The scalar object
%   is composed with each element of the non-scalar object
%   array.
%   You can use se3 division to compose a sequence of
%   SE(3) transformations, so that T represents a rotation and
%   translation where the inverse of T2 is applied first,
%   followed by T1.
%
%   See also mtimes, mldivide, inv.

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

    if isa(obj1, "matlabshared.spatialmath.internal.SpatialMatrixBase") && isa(obj2, "matlabshared.spatialmath.internal.SpatialMatrixBase") && ...
            isequal(class(obj1), class(obj2))

        % Only support spatial math objects for now (no numerics)
        % Implicit expansion is supported by mtimes
        coder.internal.assert(isscalar(obj1) || isscalar(obj2), "shared_spatialmath:matobj:ScalarArg", "mrdivide, /");
        o = mtimes(obj1, inv(obj2));

    else
        coder.internal.errorIf(true, "shared_spatialmath:matobj:OperationReals", "mrdivide, /");
    end

end
