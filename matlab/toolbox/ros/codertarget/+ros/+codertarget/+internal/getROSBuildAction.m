function ret = getROSBuildAction(hObj)
%This function is for internal use only. It may be removed in the future.

% getROSBuildAction Returns the value of 'Build Action' option saved as a
% cell array representing available options in the Simulink Configuration 
% set
% This function can accept the following objects as input:
%   - CoderTarget.SettingsController
%   - Simulink.ConfigSet

% Copyright 2024 The MathWorks, Inc.

if isa(hObj,'Simulink.ConfigSet')
    cs = hObj;
else
    cs = hObj.getConfigSet;
end

isROSCtrl = codertarget.data.getParameterValue(cs,'ROS.GenerateROSControl');
try
    isROSComponent = codertarget.data.getParameterValue(cs,'ROS.GenerateROSComponent');
catch
    isROSComponent = false;
end

isRemoteBuild = codertarget.data.getParameterValue(cs, 'ROS.RemoteBuild');

if ~ (isROSCtrl || isROSComponent)
    % Standard code generation
    ret = {'None', 'Build', 'Build and load', 'Build and run'};
else
    % ROS(2) Control code generation
    if isRemoteBuild
        ret = {'None', 'Build and load'};
    else
        ret = {'None'};
    end
end