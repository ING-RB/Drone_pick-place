function [data, info] = carlaScenario
%CarlaScenario gives an empty data for carla_ros_scenario_runner_types/CarlaScenario

% Copyright 2019-2020 The MathWorks, Inc.
%#codegen
data = struct();
data.MessageType = 'carla_ros_scenario_runner_types/CarlaScenario';
[data.Name, info.Name] = ros.internal.ros.messages.ros.char('string',0);
[data.ScenarioFile, info.ScenarioFile] = ros.internal.ros.messages.ros.char('string',0);
info.MessageType = 'carla_ros_scenario_runner_types/CarlaScenario';
info.constant = 0;
info.default = 0;
info.maxstrlen = NaN;
info.MaxLen = 1;
info.MinLen = 1;
info.MatPath = cell(1,2);
info.MatPath{1} = 'name';
info.MatPath{2} = 'scenario_file';
