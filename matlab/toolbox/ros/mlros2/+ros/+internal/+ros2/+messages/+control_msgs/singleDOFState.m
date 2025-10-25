function [data, info] = singleDOFState
%SingleDOFState gives an empty data for control_msgs/SingleDOFState

% Copyright 2019-2021 The MathWorks, Inc.
data = struct();
data.MessageType = 'control_msgs/SingleDOFState';
[data.name, info.name] = ros.internal.ros2.messages.ros2.char('string',1,NaN,0);
[data.reference, info.reference] = ros.internal.ros2.messages.ros2.default_type('double',1,0);
[data.feedback, info.feedback] = ros.internal.ros2.messages.ros2.default_type('double',1,0);
[data.feedback_dot, info.feedback_dot] = ros.internal.ros2.messages.ros2.default_type('double',1,0);
[data.error, info.error] = ros.internal.ros2.messages.ros2.default_type('double',1,0);
[data.error_dot, info.error_dot] = ros.internal.ros2.messages.ros2.default_type('double',1,0);
[data.time_step, info.time_step] = ros.internal.ros2.messages.ros2.default_type('double',1,0);
[data.output, info.output] = ros.internal.ros2.messages.ros2.default_type('double',1,0);
info.MessageType = 'control_msgs/SingleDOFState';
info.constant = 0;
info.default = 0;
info.maxstrlen = NaN;
info.MaxLen = 1;
info.MinLen = 1;
info.MatPath = cell(1,8);
info.MatPath{1} = 'name';
info.MatPath{2} = 'reference';
info.MatPath{3} = 'feedback';
info.MatPath{4} = 'feedback_dot';
info.MatPath{5} = 'error';
info.MatPath{6} = 'error_dot';
info.MatPath{7} = 'time_step';
info.MatPath{8} = 'output';
