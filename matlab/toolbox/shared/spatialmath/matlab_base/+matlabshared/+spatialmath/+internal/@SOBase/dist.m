function d = dist(R1, R2)
%DIST Calculate angular distance between rotations
%   D = DIST(R1, R2) computes the angular distance in radians
%   between so2 or so3 objects R1 and R2. The rotations are converted
%   to quaternions and the well-defined quaternion angular
%   distance is used.
%
%   R1 and R2 must have compatible types and sizes. In the simplest case,
%   they can be the same size, or one can be a scalar. Two
%   inputs have compatible sizes if, for every dimension, the
%   dimension sizes of the inputs are either the same or one of
%   them is 1.
%
%   See also quaternion/dist.

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

    matlabshared.spatialmath.internal.SpatialMatrixBase.parseSpatialMatrixInput(R1,R2);

    % Use implicit expansion to find compatible sizes for R1 and R2
    [indR1, indR2] = matlabshared.spatialmath.internal.implicitExpansionIndices(R1.MInd, R2.MInd);
    indR1Lin = indR1(:);
    indR2Lin = indR2(:);

    % Find rotational distance
    q1 = toQuaternion(R1, 0, indR1Lin);
    q2 = toQuaternion(R2, 0, indR2Lin);

    qDist = dist(q1, q2).';
    d = reshape(qDist, size(indR1));

end
