function pose = xyzquat(obj)
%XYZQUAT Convert to compact pose representation
%   POSE = XYZQUAT(T) converts the transformation array T (with N elements)
%   to an N-by-7 matrix, POSE. Each row of POSE represents a 3-D pose of
%   the form [X Y Z QW QX QY QZ]. [X Y Z] is the translation and [QW QX QY
%   QZ] is the quaternion rotation.

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

    pose = robotics.internal.tform2xyzquat(obj.M);

end
