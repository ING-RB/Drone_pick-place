function [data, info] = queryTrajectoryStateRequest
%QueryTrajectoryState gives an empty data for control_msgs/QueryTrajectoryStateRequest

% Copyright 2019-2021 The MathWorks, Inc.
data = struct();
data.MessageType = 'control_msgs/QueryTrajectoryStateRequest';
[data.time, info.time] = ros.internal.ros2.messages.builtin_interfaces.time;
info.time.MLdataType = 'struct';
info.MessageType = 'control_msgs/QueryTrajectoryStateRequest';
info.constant = 0;
info.default = 0;
info.maxstrlen = NaN;
info.MaxLen = 1;
info.MinLen = 1;
info.MatPath = cell(1,3);
info.MatPath{1} = 'time';
info.MatPath{2} = 'time.sec';
info.MatPath{3} = 'time.nanosec';
