function qmult = quatMultiply(q, r)
%This function is for internal use only. It may be removed in the future.

%quatMultiply Multiply two quaternions
%   QMULT = quatMultiply(Q,R) calculates the quaternion product, QMULT,
%   for two input quaternions, Q and R.  The inputs Q and R are Nx4 matrices
%   of quaternions. These N quaternions will be multiplied pairwise (row-by-row).
%   Each quaternion is of the form q = [w x y z], with the scalar number
%   as the first value.
%   The output quaternion, QMULT, is the concatenation of the two
%   rotations represented by the input quaternions.

%   Copyright 2014-2024 The MathWorks, Inc.

%#codegen
% Calculate imaginary portion of quaternion product
qimag = [q(:,1).*r(:,2) q(:,1).*r(:,3) q(:,1).*r(:,4)] + ...
    [r(:,1).*q(:,2) r(:,1).*q(:,3) r(:,1).*q(:,4)]+...
    [ q(:,3).*r(:,4)-q(:,4).*r(:,3) ...
    q(:,4).*r(:,2)-q(:,2).*r(:,4) ...
    q(:,2).*r(:,3)-q(:,3).*r(:,2)];

% Calculate real portion of quaternion product
qreal = q(:,1).*r(:,1) - q(:,2).*r(:,2) - ...
    q(:,3).*r(:,3) - q(:,4).*r(:,4);

% Output quaternion.
qmult = [qreal, qimag];

end
