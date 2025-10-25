function d = gravitydir(orientations, RF)
%

%   Copyright 2023 The MathWorks, Inc.		

%#codegen


arguments
    orientations
    RF (1,3) char {mustBeMember(RF, {'NED', 'ENU'})} = 'NED'
end

% gravitydir computes the direction of "down" in the body reference frame.

positioning.internal.Utilities.validateQuatOrRotmat(orientations, 'gravitydir', 'orientations', 1);
m = positioning.internal.Utilities.convertToRotmat(orientations);

if strcmpi(RF, "NED")
    d = squeeze(m(:,3,:)).';
else
    % ENU
    d = -squeeze(m(:,3,:)).';
end
