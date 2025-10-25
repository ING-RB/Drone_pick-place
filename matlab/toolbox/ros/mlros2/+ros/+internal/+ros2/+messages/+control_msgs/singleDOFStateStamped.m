function [data, info] = singleDOFStateStamped
%SingleDOFStateStamped gives an empty data for control_msgs/SingleDOFStateStamped

% Copyright 2019-2021 The MathWorks, Inc.
data = struct();
data.MessageType = 'control_msgs/SingleDOFStateStamped';
[data.header, info.header] = ros.internal.ros2.messages.std_msgs.header;
info.header.MLdataType = 'struct';
[data.dof_state, info.dof_state] = ros.internal.ros2.messages.control_msgs.singleDOFState;
info.dof_state.MLdataType = 'struct';
info.MessageType = 'control_msgs/SingleDOFStateStamped';
info.constant = 0;
info.default = 0;
info.maxstrlen = NaN;
info.MaxLen = 1;
info.MinLen = 1;
info.MatPath = cell(1,14);
info.MatPath{1} = 'header';
info.MatPath{2} = 'header.stamp';
info.MatPath{3} = 'header.stamp.sec';
info.MatPath{4} = 'header.stamp.nanosec';
info.MatPath{5} = 'header.frame_id';
info.MatPath{6} = 'dof_state';
info.MatPath{7} = 'dof_state.name';
info.MatPath{8} = 'dof_state.reference';
info.MatPath{9} = 'dof_state.feedback';
info.MatPath{10} = 'dof_state.feedback_dot';
info.MatPath{11} = 'dof_state.error';
info.MatPath{12} = 'dof_state.error_dot';
info.MatPath{13} = 'dof_state.time_step';
info.MatPath{14} = 'dof_state.output';
