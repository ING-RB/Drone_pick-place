function extraInfo_bus = extraInfo()
% This class is for internal use only. It may be removed in the future.

%   Copyright 2024 The MathWorks, Inc.

controllerTEBExtraInfo.LastFeasibleIdx = 1;
controllerTEBExtraInfo.DistanceFromStartPose = zeros(332,1);
controllerTEBExtraInfo.HasReachedGoal = false; 
controllerTEBExtraInfo.TrajectoryCost = 1; 
controllerTEBExtraInfo.ExitFlag = 1;

% Create Estimation Data Bus for Simulink Model
extraInfoBusInfo = Simulink.Bus.createObject(controllerTEBExtraInfo);
extraInfo_bus = evalin('base', extraInfoBusInfo.busName);

% Delete created Bus from base workspace
evalin('base', 'clear slBus1' );
end