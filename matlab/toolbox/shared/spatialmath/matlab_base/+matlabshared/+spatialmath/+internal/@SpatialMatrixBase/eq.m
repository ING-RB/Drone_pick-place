function tf = eq(T1,T2)
%EQ Element-by-element equality check
%
%   T1 == T2 does element-by-element comparisons between the
%   arrays T1 and T2 and returns an array with elements set
%   to logical 1 (TRUE) where the underlying matrices are equal and
%   elements set to logical 0 (FALSE) where they are not. T1
%   and T2 must have compatible sizes. In the simplest cases, they can be the same
%   size or one can be a scalar. Two inputs have compatible sizes if, for
%   every dimension, the dimension sizes of the inputs are either the same
%   or one of them is 1.
%
%   When comparing numeric values of matrices, EQ does not
%   consider the underlying class of the values in determining
%   whether they are equal. In other words,
%   double(T) and single(T) are considered equal.
%
%   See also ne.

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

    coder.internal.assert((isa(T1,"matlabshared.spatialmath.internal.SpatialMatrixBase") || isa(T1,"numeric")) && ...
                          (isa(T2,"matlabshared.spatialmath.internal.SpatialMatrixBase") || isa(T2,"numeric")), ...
                          "shared_spatialmath:matobj:TransformOrNumeric");

    if isa(T1,"matlabshared.spatialmath.internal.SpatialMatrixBase") && isa(T2,"matlabshared.spatialmath.internal.SpatialMatrixBase") && ...
            isequal(class(T1), class(T2))

        % Support implicit expansion. This will throw an error if sizes are
        % incompatible.
        [indT1, indT2] = matlabshared.spatialmath.internal.implicitExpansionIndices(T1.MInd, T2.MInd);
        eqRow = eqMatrix(T1.M, indT1, T2.M, indT2);
        tf = reshape(eqRow, size(indT1));

    elseif isa(T1,"matlabshared.spatialmath.internal.SpatialMatrixBase") && isa(T2,"numeric")
        % Note that this ignores the object array size in T1, since the size
        % doesn't matter when extracting numeric matrices, e.g. tform(s) ==
        % tform(s.') for a 2D array.
        if isempty(T2)
            tf = true(0,0);
            return;
        end

        T2Ind = cast(1:size(T2,3),"like",T2);
        [indT1, indT2] = matlabshared.spatialmath.internal.implicitExpansionIndices(T1.MInd(:)', T2Ind);
        eqRow = eqMatrix(T1.M, indT1, T2, indT2);

        % Make the output the shape of the object array
        tf = reshape(eqRow, size(T1.MInd));

    elseif isa(T2,"matlabshared.spatialmath.internal.SpatialMatrixBase") && isa(T1,"numeric")

        if isempty(T1)
            tf = true(0,0);
            return;
        end

        T1Ind = cast(1:size(T1,3),"like",T1);
        [indT2, indT1] = matlabshared.spatialmath.internal.implicitExpansionIndices(T2.MInd(:)', T1Ind);
        eqRow = eqMatrix(T2.M, indT2, T1, indT1);

        % Make the output the shape of the object array
        tf = reshape(eqRow, size(T2.MInd));

    else
        % This branch is important for codegen + if T1 and T2 are both spatial
        % matrix objects, but not of the same concrete type.
        tf = false(size(T1)) & false(size(T2));
    end

end
