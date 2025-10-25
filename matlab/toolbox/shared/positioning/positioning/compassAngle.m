function h = compassAngle(orientations, RF)
%

%   Copyright 2023 The MathWorks, Inc. 

%#codegen

arguments
    orientations
    RF (1,3) char {mustBeMember(RF, {'NED', 'ENU'})} = 'NED'
end

% compassAngle computes the yaw angle from north on a 0-2pi scale

positioning.internal.Utilities.validateQuatOrRotmat(orientations, 'compassAngle', 'orientations', 1);
q = positioning.internal.Utilities.convertToQuat(orientations);

% Get the Z rotation (yaw)
e = euler(q, 'ZYX', 'frame');
yaw = e(:,1);

% ENU rotates backwards and starts at East, so flip it.
if strcmp(RF, 'ENU')
    yaw = cast(pi/2, 'like', yaw) - yaw;
end

h = zeros(size(yaw), 'like', yaw);
% Wrapping: compassAngle goes from 0-2*pi
%   North = 0 deg
%   East = 90 deg
%   South = 180 deg
%   West = 270 deg
thezero = cast(0, 'like', yaw);
idx = yaw >= thezero;
h(idx) = yaw(idx);

twopi = cast(2*pi, 'like', yaw);
h(~idx) = twopi + yaw(~idx);

% if yaw was -eps, h will be flushed to 2*pi. We want 0. Therefore:
h(h==twopi) = thezero;
end

