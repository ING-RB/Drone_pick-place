function l = linaccel(orientations, accReadings, RF)
%

%   Copyright 2023 The MathWorks, Inc.		

%#codegen
arguments
    orientations
    accReadings (:,3) {mustBeFinite, mustBeA(accReadings, {'single', 'double'} )}
    RF (1,3) char {mustBeMember(RF, {'NED', 'ENU'})} = 'NED'
end

% linaccel computes the linear acceleration present in an accelerometer
% reading given the orientation of the accelerometer.

positioning.internal.Utilities.validateQuatOrRotmat(orientations, 'linaccel', 'orientations', 1);
q = positioning.internal.Utilities.convertToQuat(orientations);

Nq = size(q,1);
Na = size(accReadings,1);
coder.internal.assert(Nq == Na || Na == 1 || Nq == 1, 'shared_positioning:utilities:IncompatibleSizes', 1, 2);

% Rotate the accelerometer reading back to the parent frame.
totalAccel = rotatepoint(q, accReadings);

g = fusion.internal.UnitConversions.geeToMetersPerSecondSquared(ones(1,1, 'like', accReadings));
if strcmp(RF, "NED")
    l = -(totalAccel - [0 0 g]);
else
    l = -(totalAccel + [0 0 g]);
end

