function out = times(obj1, obj2)
%times Element-wise pose composition (multiplication)
%   T = T1.*T2 composes (multiplies) se3 object arrays
%   element-by-element by multiplying each element of T1
%   with each corresponding element of T2. T1 and T2
%   must have compatible sizes. In the simplest cases, they can be the same
%   size or one can be a scalar. Two inputs have compatible sizes if, for
%   every dimension, the dimension sizes of the inputs are either the same
%   or one of them is 1.
%
%   You can use se3 multiplication to compose a sequence of
%   SE(3) transformations, so that T represents a rotation and
%   translation where T2 is applied first, followed by T1.
%
%   See also mtimes.

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

    if isa(obj1, "matlabshared.spatialmath.internal.SpatialMatrixBase") && isa(obj2, "matlabshared.spatialmath.internal.SpatialMatrixBase") && ...
            isequal(class(obj1), class(obj2))

        % Only support spatial math objects in multiplication for now (no
        % numerics)

        [indObj1, indObj2] = matlabshared.spatialmath.internal.implicitExpansionIndices(obj1.MInd, obj2.MInd);

        numMats = numel(indObj1);
        % Preallocate output. The underlying type is determined by the
        % underlying type of the first matrix.
        M = zeros(obj1.Dim, obj1.Dim, numMats, "like", obj1.M);
        for i = 1:numel(indObj1)
            M(:,:,i) = obj1.M(:,:,indObj1(i)) * obj2.M(:,:,indObj2(i));
        end
        out = obj1.fromMatrix(M, size(indObj1));
    else
        % Use errorIf to ensure compile-time error
        coder.internal.errorIf(true, "shared_spatialmath:matobj:OperationReals", "times, .*");
    end

end
