function [data, info] = executeScenarioRequest
%ExecuteScenario gives an empty data for carla_ros_scenario_runner_types/ExecuteScenarioRequest

% Copyright 2019-2020 The MathWorks, Inc.
%#codegen
data = struct();
data.MessageType = 'carla_ros_scenario_runner_types/ExecuteScenarioRequest';
[data.Scenario, info.Scenario] = ros.internal.ros.messages.carla_ros_scenario_runner_types.carlaScenario;
info.Scenario.MLdataType = 'struct';
info.MessageType = 'carla_ros_scenario_runner_types/ExecuteScenarioRequest';
info.constant = 0;
info.default = 0;
info.maxstrlen = NaN;
info.MaxLen = 1;
info.MinLen = 1;
info.MatPath = cell(1,3);
info.MatPath{1} = 'scenario';
info.MatPath{2} = 'scenario.name';
info.MatPath{3} = 'scenario.scenario_file';
