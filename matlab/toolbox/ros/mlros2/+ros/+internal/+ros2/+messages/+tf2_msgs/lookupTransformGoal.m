function [data, info] = lookupTransformGoal
%LookupTransformGoal gives an empty data for tf2_msgs/LookupTransformGoal

% Copyright 2019-2021 The MathWorks, Inc.
data = struct();
data.MessageType = 'tf2_msgs/LookupTransformGoal';
[data.target_frame, info.target_frame] = ros.internal.ros2.messages.ros2.char('string',1,NaN,0);
[data.source_frame, info.source_frame] = ros.internal.ros2.messages.ros2.char('string',1,NaN,0);
[data.source_time, info.source_time] = ros.internal.ros2.messages.builtin_interfaces.time;
info.source_time.MLdataType = 'struct';
[data.timeout, info.timeout] = ros.internal.ros2.messages.builtin_interfaces.duration;
info.timeout.MLdataType = 'struct';
[data.target_time, info.target_time] = ros.internal.ros2.messages.builtin_interfaces.time;
info.target_time.MLdataType = 'struct';
[data.fixed_frame, info.fixed_frame] = ros.internal.ros2.messages.ros2.char('string',1,NaN,0);
[data.advanced, info.advanced] = ros.internal.ros2.messages.ros2.default_type('logical',1,0);
info.MessageType = 'tf2_msgs/LookupTransformGoal';
info.constant = 0;
info.default = 0;
info.maxstrlen = NaN;
info.MaxLen = 1;
info.MinLen = 1;
info.MatPath = cell(1,13);
info.MatPath{1} = 'target_frame';
info.MatPath{2} = 'source_frame';
info.MatPath{3} = 'source_time';
info.MatPath{4} = 'source_time.sec';
info.MatPath{5} = 'source_time.nanosec';
info.MatPath{6} = 'timeout';
info.MatPath{7} = 'timeout.sec';
info.MatPath{8} = 'timeout.nanosec';
info.MatPath{9} = 'target_time';
info.MatPath{10} = 'target_time.sec';
info.MatPath{11} = 'target_time.nanosec';
info.MatPath{12} = 'fixed_frame';
info.MatPath{13} = 'advanced';
