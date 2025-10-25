function randquat = randRotation(N)
%This function is for internal use only. It may be removed in the future.

%RANDROTATION Generates a random uniform unit-quaternion
%
%   Q = randRotation() generates a random unit-quaternion using
%   the sub-group algorithm. The random quaternion is
%   a vector of the form q = [w, x, y, z] where,
%   the quaternion's distribution is uniform.
%
%   Q = randRotation(N) generates Q which is an N-by-4 matrix
%   containing N quaternions. Each quaternion is of the form
%   q = [w, x, y, z], with the scalar number in the first column.
%   The generated quaternion is distributed uniformly.
%
%   Examples:
%        % Generate a single random rotation
%        randquat = robotics.core.internal.randRotation
%
%        % Generate 10 random rotations
%        randquat = robotics.core.internal.randRotation(10)
%
%   References:
%       [1] Shoemake, Ken. "Uniform random rotations."
%           Graphics Gems III (IBM Version). 1992. 124-132.
%
%       [2] Kuffner, James J. "Effective sampling and distance metrics for 3D rigid body path planning."
%           Robotics and Automation, 2004. Proceedings. ICRA'04.
%           2004 IEEE International Conference on. Vol. 4. IEEE, 2004.
%
% Copyright 2018-2020 The MathWorks, Inc.

%#codegen

    if nargin == 0 % check for call of randRotation()
        r = rand(1, 3);
    elseif nargin == 1 % check for call of randRotation(N)
        r = rand(3, N)';
    end
    s = r(:, 1);
    sigma1 = sqrt(1 - s);
    sigma2 = sqrt(s);
    theta1 = 2 * pi * r(:, 2);
    theta2 = 2 * pi * r(:, 3);

    w = cos(theta2) .* sigma2;
    x = sin(theta1) .* sigma1;
    y = cos(theta1) .* sigma1;
    z = sin(theta2) .* sigma2;

    randquat = [w, x, y, z];

end
