function a = axang(obj)
%AXANG Extract axis-angle rotation
%   A = AXANG(T) extracts the N rotations from the se3 array T and converts
%   them to an N-by-4 matrix of equivalent axis-angle vectors.
%   Each row of A represents an axis-angle vector and is of the form
%   [X Y Z THETA], with the first three elements specifying the rotation
%   axis and the last element defining the rotation angle (in radians).
%
%   See also eul, quat.

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

    a = robotics.internal.tform2axang(obj.M);

end
