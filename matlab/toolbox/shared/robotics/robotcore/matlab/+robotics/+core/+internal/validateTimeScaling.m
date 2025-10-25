function validatedTimeScaling = validateTimeScaling(timeScalingMatrix, timeVectorLength, fcnName)
%This function is for internal use only. It may be removed in the future.

%VALIDATETIMESCALING Validate time scaling inputs

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

validateattributes(timeScalingMatrix, {'single','double'}, {'nonempty','nrows',3,'real','finite'}, fcnName,'TimeScaling');

% Error if there is a size mismatch. Note that the error is agnostic of the
% function name, despite the error ID.
coder.internal.errorIf(size(timeScalingMatrix,2) ~= timeVectorLength, 'shared_robotics:robotcore:utils:RotTrajTimeScalingLength');

% Bounds and constants
tol = sqrt(eps(class(timeScalingMatrix)));
upperBound = 1;
lowerBound = 0;

% Round values just outside bounds to be within bounds, then validate. In
% this way the error message will reflect the actual upper bounds and the
% tolerance is only handled internally.
timeScalingPos = timeScalingMatrix(1,:);
idxAboveBndWithinTol = (timeScalingPos > upperBound) & (timeScalingPos < upperBound + tol);
idxBelowBndWithinTol = (timeScalingPos < lowerBound) & (timeScalingPos > lowerBound - tol);
timeScalingPos(idxAboveBndWithinTol) = upperBound;
timeScalingPos(idxBelowBndWithinTol) = lowerBound;
validateattributes(timeScalingPos, {'numeric'}, {'>=', lowerBound, '<=', upperBound}, fcnName,'TimeScaling(1,:)');

% Return the time scaling, adjusted for tolerance
validatedTimeScaling = [timeScalingPos; timeScalingMatrix(2:3,:)];

end
