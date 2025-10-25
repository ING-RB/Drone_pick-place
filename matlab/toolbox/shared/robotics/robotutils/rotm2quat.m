function quat = rotm2quat( R )
%ROTM2QUAT Convert rotation matrix to quaternion
%   Q = ROTM2QUAT(R) converts a 3D rotation matrix, R, into the
%   corresponding unit quaternion representation, Q. The input, R, is an
%   3-by-3-by-N matrix containing N orthonormal rotation matrices.
%   The output, Q, is an N-by-4 matrix containing N quaternions. Each
%   quaternion is of the form q = [w x y z], with w as the scalar number.
%   Each element of Q must be a real number.
%
%   If the input matrices are not orthonormal, the function will
%   return the quaternions that correspond to the orthonormal matrices
%   closest to the imprecise matrix inputs.
%
%
%   Example:
%      % Convert a rotation matrix to a quaternion
%      R = [0 0 1; 0 1 0; -1 0 0];
%      q = rotm2quat(R)
%
%   References:
%   [1] I.Y. Bar-Itzhack, "New method for extracting the quaternion from a
%       rotation matrix," Journal of Guidance, Control, and Dynamics,
%       vol. 23, no. 6, pp. 1085-1087, 2000
%
%   See also quat2rotm

%   Copyright 2014-2022 The MathWorks, Inc.

%#codegen

    robotics.internal.validation.validateRotationMatrix(R, 'rotm2quat', 'R');
    quat = robotics.internal.rotm2quat(R);

end
