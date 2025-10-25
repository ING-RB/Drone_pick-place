function t = tilt(orientations)
%

%   Copyright 2023 The MathWorks, Inc.		

%#codegen

arguments
    orientations  % required
end
% tilt(orientations) computes the angle in radians between the body and nav
% frame z-axes. It is reference frame agnostic. orientations can be a
% vector of quaternions or 3-by-3-by-N rotation matrices.

positioning.internal.Utilities.validateQuatOrRotmat(orientations, ...
    'tilt', 'orientations', 1);
r = positioning.internal.Utilities.convertToRotmat(orientations);
t = squeeze(acos(r(3,3,:)));
end
