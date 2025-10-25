function [data, info] = executeScenarioResponse
%ExecuteScenario gives an empty data for carla_ros_scenario_runner_types/ExecuteScenarioResponse

% Copyright 2019-2020 The MathWorks, Inc.
%#codegen
data = struct();
data.MessageType = 'carla_ros_scenario_runner_types/ExecuteScenarioResponse';
[data.Result, info.Result] = ros.internal.ros.messages.ros.default_type('logical',1);
info.MessageType = 'carla_ros_scenario_runner_types/ExecuteScenarioResponse';
info.constant = 0;
info.default = 0;
info.maxstrlen = NaN;
info.MaxLen = 1;
info.MinLen = 1;
info.MatPath = cell(1,1);
info.MatPath{1} = 'result';
