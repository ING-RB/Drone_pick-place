function o = ldivide(obj1, obj2)
%ldivide Pose composition with element-wise left division
%   T = T1.\T2 composes se3 object arrays
%   element-by-element by left dividing each element of T1
%   with each corresponding element of T2. This is the same
%   as calling inv(T1e)*T2e for each element of the input arrays.
%   T1 and T2 must have compatible sizes.
%   In the simplest cases, they can be the same
%   size or one can be a scalar. Two inputs have compatible sizes if, for
%   every dimension, the dimension sizes of the inputs are either the same
%   or one of them is 1.
%
%   See also times, rdivide, inv.

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

    if isa(obj1, "matlabshared.spatialmath.internal.SpatialMatrixBase") && isa(obj2, "matlabshared.spatialmath.internal.SpatialMatrixBase") && ...
            isequal(class(obj1), class(obj2))

        % Only support spatial math objects for now (no numerics)
        % Implicit expansion is supported by times
        o = times(inv(obj1), obj2);

    else
        % Use errorIf to ensure compile-time error
        coder.internal.errorIf(true, "shared_spatialmath:matobj:OperationReals", "ldivide, .\");
    end

end
