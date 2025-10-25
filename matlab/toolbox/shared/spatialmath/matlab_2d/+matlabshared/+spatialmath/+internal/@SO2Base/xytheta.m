function pose = xytheta(obj)
%XYTHETA Convert to compact pose representation
%   POSE = XYTHETA(R) converts the rotation array R (with N elements) to an
%   N-by-3 matrix, POSE. Each row of POSE represents a 2-D pose of the form
%   [X Y THETA].
%   [THETA] is the rotation angle around the z-axis (in radians) and [X Y]
%   is the translation and will always be zero.

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

    transl = zeros(size(obj.M,3),obj.Dim,"like",obj.M);
    theta = robotics.internal.rotm2theta(obj.rotm);

    pose = [transl theta];

end
