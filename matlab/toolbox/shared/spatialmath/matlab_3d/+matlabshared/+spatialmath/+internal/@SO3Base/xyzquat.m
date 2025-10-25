function pose = xyzquat(obj)
%XYZQUAT Convert to compact pose representation
%   POSE = XYZQUAT(R) converts the rotation array R (with N elements) to an
%   N-by-7 matrix, POSE. Each row of POSE represents a 3-D pose of the form
%   [X Y Z QW QX QY QZ].
%   [QW QX QY QZ] is the quaternion rotation corresponding to R and [X Y Z]
%   is the translation and will always be zero.

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

    transl = zeros(size(obj.M,3),obj.Dim,"like",obj.M);
    quat = robotics.internal.rotm2quat(obj.rotm);

    pose = [transl quat];

end
