function angleInDegrees = radtodeg(angleInRadians)
% RADTODEG Convert angles from radians to degrees
%
%   RADTODEG is not recommended. Use rad2deg instead.
%
%   angleInDegrees = RADTODEG(angleInRadians) converts angle units from
%   radians to degrees.
%
%   See also: RAD2DEG

% Copyright 2009-2017 The MathWorks, Inc.

angleInDegrees = (180/pi) * angleInRadians;
