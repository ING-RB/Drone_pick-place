function R = quat2rotm( q )
%This method is for internal use only. It may be removed in the future.

%QUAT2ROTM Convert quaternion to rotation matrix
%   R = QUAT2ROTM(Q) normalizes the input quaternion to a unit quaternion,
%   and converts it into an orthonormal rotation matrix, R. The input, Q,
%   is an N-by-4 matrix containing N quaternions, where each quaternion
%   represents a 3D rotation and is of the form [w x y z], where w is a
%   numeric scalar, and each element of Q must be a real numeric scalar.
%
%
%   This is an internal function that does no input validation and is used
%   by user-facing functionality.
%
%   See also quat2rotm.

%   Copyright 2022-2023 The MathWorks, Inc.

%#codegen

% Normalize and transpose the quaternions
    q = robotics.internal.normalizeRows(q).';

    % Reshape the quaternions in the depth dimension
    q2 = reshape(q,[4 1 size(q,2)]);

    s = q2(1,1,:);
    x = q2(2,1,:);
    y = q2(3,1,:);
    z = q2(4,1,:);

    % Explicitly define concatenation dimension for codegen
    tempR = cat(1, 1 - 2*(y.^2 + z.^2),   2*(x.*y - s.*z),   2*(x.*z + s.*y),...
                2*(x.*y + s.*z), 1 - 2*(x.^2 + z.^2),   2*(y.*z - s.*x),...
                2*(x.*z - s.*y),   2*(y.*z + s.*x), 1 - 2*(x.^2 + y.^2) );

    R = reshape(tempR, [3, 3, length(s)]);
    R = permute(R, [2 1 3]);

end
