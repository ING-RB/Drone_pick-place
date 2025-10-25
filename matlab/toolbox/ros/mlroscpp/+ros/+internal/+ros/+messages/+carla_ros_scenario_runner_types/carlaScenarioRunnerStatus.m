function [data, info] = carlaScenarioRunnerStatus
%CarlaScenarioRunnerStatus gives an empty data for carla_ros_scenario_runner_types/CarlaScenarioRunnerStatus

% Copyright 2019-2020 The MathWorks, Inc.
%#codegen
data = struct();
data.MessageType = 'carla_ros_scenario_runner_types/CarlaScenarioRunnerStatus';
[data.STOPPED, info.STOPPED] = ros.internal.ros.messages.ros.default_type('uint8',1, 0);
[data.STARTING, info.STARTING] = ros.internal.ros.messages.ros.default_type('uint8',1, 1);
[data.RUNNING, info.RUNNING] = ros.internal.ros.messages.ros.default_type('uint8',1, 2);
[data.SHUTTINGDOWN, info.SHUTTINGDOWN] = ros.internal.ros.messages.ros.default_type('uint8',1, 3);
[data.ERROR, info.ERROR] = ros.internal.ros.messages.ros.default_type('uint8',1, 4);
[data.Status, info.Status] = ros.internal.ros.messages.ros.default_type('uint8',1);
info.MessageType = 'carla_ros_scenario_runner_types/CarlaScenarioRunnerStatus';
info.constant = 0;
info.default = 0;
info.maxstrlen = NaN;
info.MaxLen = 1;
info.MinLen = 1;
info.MatPath = cell(1,6);
info.MatPath{1} = 'STOPPED';
info.MatPath{2} = 'STARTING';
info.MatPath{3} = 'RUNNING';
info.MatPath{4} = 'SHUTTINGDOWN';
info.MatPath{5} = 'ERROR';
info.MatPath{6} = 'status';
