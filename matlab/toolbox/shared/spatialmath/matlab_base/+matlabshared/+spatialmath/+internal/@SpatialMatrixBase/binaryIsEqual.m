function eq = binaryIsEqual(T1,T2)
%This function is for internal use only. It may be removed in the future.

%binaryIsEqual Compare numeric values in matrices
%   TF = binaryIsEqual(T1,T2) returns TRUE if T1 and T2 have the same
%   class type, the same size, and all values of the underlying matrices
%   are numerically equal. This uses ISEQUAL under the hood, with all its quirks.
%
%   One of T1 and T2 can also be a numeric matrix (or 3D array) that will
%   be compared to the underlying matrix of the object.
%
%   See also isequal, binaryIsEqualn.

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

    if isa(T1,"matlabshared.spatialmath.internal.SpatialMatrixBase") && isa(T2,"matlabshared.spatialmath.internal.SpatialMatrixBase")
        % Make sure that both objects have the same (concrete) type, e.g. both
        % are se3. When comparing objects, we take the object array size into
        % account.
        % There is no need to check MInd, since the size check ensures that
        % both MInds have the same size + our code ensures that MInd is always
        % 1:numel(T1), so no additional comparison is needed.
        eq = isequal(class(T1), class(T2)) && ...
             isequal(size(T1),size(T2)) && ...
             isequal(T1.M,T2.M);
    elseif isa(T1,"matlabshared.spatialmath.internal.SpatialMatrixBase") && isa(T2,"numeric")
        % One input is an object, the other is a numeric matrix
        % Note that this ignores the object array size in obj1, since the size
        % doesn't matter when extracting numeric matrices, e.g. tform(s) ==
        % tform(s.') for a 2D array.
        eq = isequal(T1.M,T2);
    else
        eq = false;
    end
end
