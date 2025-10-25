function [localTimeScaling, errorFlag] = getTimeScalingAtEvalTime(timeScalingTimeVec, timeScaling, evalTime, timeInterval)
%getTimeScalingAtEvalTime Obtain the time scaling values s(t), sd(t), and sdd(t) at t = EVALTIME
%   The user can define the time scaling over a range, but only
%   the values required at the evaluation instant(s) is
%   required at each step. This method uses interpolation to
%   obtain the local values of s(t) and its time derivatives.

%   Copyright 2018-2019 The MathWorks, Inc.

%#codegen

    % If time scaling time is a scalar, evaluation time must also be a
    % scalar and the values must match.
    coder.internal.errorIf((numel(timeScalingTimeVec) == 1) && (numel(evalTime) > 1), 'shared_robotics:robotslcore:trajectorygeneration:TimeScalingIntervalInterpError');
    coder.internal.errorIf((numel(timeScalingTimeVec) == 1) && (timeScalingTimeVec ~= evalTime), 'shared_robotics:robotslcore:trajectorygeneration:TimeScalingIntervalInterpError');
        
    % Ensure that evalTime and timeScalingTimeVec are always processed as
    % row vectors, since this can affect the downstream dimensions in this
    % utility
    evalTime = reshape(evalTime, 1, numel(evalTime));
    timeScalingTimeVec = reshape(timeScalingTimeVec, 1, numel(timeScalingTimeVec));

    % Initialize output
    localTimeScaling = zeros(3, numel(evalTime));
    errorFlag = 0;

    % Validate general time scaling inputs
    coder.internal.errorIf(any(timeScaling(1,:) < 0) || any(timeScaling(1,:) > 1) , 'shared_robotics:robotslcore:trajectorygeneration:TimeScalingInputError')
    
    % Two kinds of valid inputs 
    if (numel(timeScalingTimeVec) == numel(evalTime)) && all(timeScalingTimeVec == evalTime)
        % The time scaling time vector and evaluation time match. In this
        % case, the time scaling is provided exactly at the specified
        % instants over which the block is evaluated
        sLocal = timeScaling(1,1:length(evalTime));
        sdLocal = timeScaling(2,1:length(evalTime));
        sddLocal = timeScaling(3,1:length(evalTime));
        localTimeScaling(:,:) = [sLocal; sdLocal; sddLocal];
        
    elseif (numel(timeScalingTimeVec) > 1)
        % The time scaling time vector spans the range set by time
        % interval. The time scaling is provided as a discretized set index
        % by the time scaling time. Interpolation is used to compute values
        % at specific evaluation times.
        
        coder.internal.errorIf(any([timeInterval(1) timeInterval(end)] ~= [timeScalingTimeVec(1) timeScalingTimeVec(end)]), 'shared_robotics:robotslcore:trajectorygeneration:TimeScalingIntervalInterpError');
        sLocal = interp1(timeScalingTimeVec, timeScaling(1,:), evalTime, 'linear', 'extrap');
        sdLocal = interp1(timeScalingTimeVec, timeScaling(2,:), evalTime, 'linear', 'extrap');
        sddLocal = interp1(timeScalingTimeVec, timeScaling(3,:), evalTime, 'linear', 'extrap');
        localTimeScaling(:,:) = [sLocal; sdLocal; sddLocal];
    end

    % Saturate outputs outside the time interval
    lowerBoundIdx = evalTime < timeInterval(1);
    upperBoundIdx = evalTime > timeInterval(2);
    if any(lowerBoundIdx)
        localTimeScaling(:, lowerBoundIdx) = repmat([0; 0; 0], 1, sum(lowerBoundIdx));
    end

    if any(upperBoundIdx)
        localTimeScaling(:, upperBoundIdx) = repmat([1; 0; 0], 1, sum(upperBoundIdx));
    end

end
