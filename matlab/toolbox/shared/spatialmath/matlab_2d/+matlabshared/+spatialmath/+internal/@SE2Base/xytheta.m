function pose = xytheta(obj)
%XYTHETA Convert to compact pose representation
%   POSE = XYTHETA(T) converts the transformation array T (with N
%   elements) to an N-by-3 matrix, POSE. Each row of POSE represents a 2-D
%   pose of the form [X Y THETA]. [THETA] is the rotation angle around the
%   z-axis (in radians) and [X Y] is the translation.

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

    pose = robotics.internal.tform2xytheta(obj.tform);

end
