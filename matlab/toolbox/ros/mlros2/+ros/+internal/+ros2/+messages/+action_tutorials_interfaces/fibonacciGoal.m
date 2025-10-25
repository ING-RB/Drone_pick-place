function [data, info] = fibonacciGoal
%FibonacciGoal gives an empty data for action_tutorials_interfaces/FibonacciGoal

% Copyright 2019-2021 The MathWorks, Inc.
data = struct();
data.MessageType = 'action_tutorials_interfaces/FibonacciGoal';
[data.order, info.order] = ros.internal.ros2.messages.ros2.default_type('int32',1,0);
info.MessageType = 'action_tutorials_interfaces/FibonacciGoal';
info.constant = 0;
info.default = 0;
info.maxstrlen = NaN;
info.MaxLen = 1;
info.MinLen = 1;
info.MatPath = cell(1,1);
info.MatPath{1} = 'order';
