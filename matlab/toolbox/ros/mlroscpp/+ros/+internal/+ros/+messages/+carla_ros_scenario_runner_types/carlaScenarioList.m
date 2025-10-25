function [data, info] = carlaScenarioList
%CarlaScenarioList gives an empty data for carla_ros_scenario_runner_types/CarlaScenarioList

% Copyright 2019-2020 The MathWorks, Inc.
%#codegen
data = struct();
data.MessageType = 'carla_ros_scenario_runner_types/CarlaScenarioList';
[data.Scenarios, info.Scenarios] = ros.internal.ros.messages.carla_ros_scenario_runner_types.carlaScenario;
info.Scenarios.MLdataType = 'struct';
info.Scenarios.MaxLen = NaN;
info.Scenarios.MinLen = 0;
data.Scenarios = data.Scenarios([],1);
info.MessageType = 'carla_ros_scenario_runner_types/CarlaScenarioList';
info.constant = 0;
info.default = 0;
info.maxstrlen = NaN;
info.MaxLen = 1;
info.MinLen = 1;
info.MatPath = cell(1,3);
info.MatPath{1} = 'scenarios';
info.MatPath{2} = 'scenarios.name';
info.MatPath{3} = 'scenarios.scenario_file';
