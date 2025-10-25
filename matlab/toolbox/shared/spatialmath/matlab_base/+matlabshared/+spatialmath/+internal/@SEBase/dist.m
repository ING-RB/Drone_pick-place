function d = dist(T1, T2, weights)
%DIST Calculate distance between transformations
%   D = DIST(T1, T2) returns a distance metric between poses
%   represented by se3 objects T1 and T2. The translational
%   and rotational distance between T1 and T2 are calculated
%   independently and combined in a weighted sum. For the
%   translational distance, this function calculates the
%   Euclidean distance. The rotational distance is determined by the
%   angular difference between the rotation quaternions
%   representing T1 and T2. Translational distance is weighted
%   by 1.0, whereas rotational distance is weighted by 0.1.
%
%   D = DIST(T1, T2, WEIGHTS) allows you to specify how
%   translational and rotational distances are weighted.
%   WEIGHTS = [WEIGHTXYZ, WEIGHTQ] is a vector with the
%   translational weight (WEIGHTXYZ) and rotational weight
%   (WEIGHTQ) used in the metric calculation. The weights are real numbers
%   >= 0.
%
%   T1 and T2 must have compatible types and sizes. In the simplest case,
%   they can be the same size, or one can be a scalar. Two
%   inputs have compatible sizes if, for every dimension, the
%   dimension sizes of the inputs are either the same or one of
%   them is 1.

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

    matlabshared.spatialmath.internal.SpatialMatrixBase.parseSpatialMatrixInput(T1,T2);
    if nargin < 3
        % Use default weights
        weights = [1, 0.1];
    else
        % Parse user input
        validateattributes(weights, "numeric", {"nonempty", "real", "nonnan", ...
                                                "finite", "nonnegative", "numel", 2}, "dist", "weights");
    end

    % Use implicit expansion to find compatible sizes for T1 and T2
    [indT1, indT2] = matlabshared.spatialmath.internal.implicitExpansionIndices(T1.MInd, T2.MInd);
    indT1Lin = indT1(:);
    indT2Lin = indT2(:);

    % Find translational distance
    transl1 = toTrvec(T1);
    transl2 = toTrvec(T2);
    translDiff = transl1(:,indT1Lin) - transl2(:,indT2Lin);

    % Extract each translational component
    dx = translDiff(1,:);
    dy = translDiff(2,:);
    if size(translDiff,1) == 2
        dz = zeros(size(dx),"like",dx);
    else
        dz = translDiff(3,:);
    end

    % Find rotational distance
    q1 = toQuaternion(T1, 0, indT1Lin);
    q2 = toQuaternion(T2, 0, indT2Lin);

    qDist = dist(q1, q2).';

    % Distance for se3 is implemented as Cartesian product of R3
    % and so3 (For Quaternion).
    d = sqrt(weights(1) * (dx.*dx + dy.*dy + dz.*dz) + weights(2) * (qDist.*qDist));
    d = reshape(d, size(indT1));

end
