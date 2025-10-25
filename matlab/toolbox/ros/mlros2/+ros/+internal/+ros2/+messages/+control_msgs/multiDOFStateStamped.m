function [data, info] = multiDOFStateStamped
%MultiDOFStateStamped gives an empty data for control_msgs/MultiDOFStateStamped

% Copyright 2019-2021 The MathWorks, Inc.
data = struct();
data.MessageType = 'control_msgs/MultiDOFStateStamped';
[data.header, info.header] = ros.internal.ros2.messages.std_msgs.header;
info.header.MLdataType = 'struct';
[data.dof_states, info.dof_states] = ros.internal.ros2.messages.control_msgs.singleDOFState;
info.dof_states.MLdataType = 'struct';
info.dof_states.MaxLen = NaN;
info.dof_states.MinLen = 0;
info.MessageType = 'control_msgs/MultiDOFStateStamped';
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
info.MatPath{6} = 'dof_states';
info.MatPath{7} = 'dof_states.name';
info.MatPath{8} = 'dof_states.reference';
info.MatPath{9} = 'dof_states.feedback';
info.MatPath{10} = 'dof_states.feedback_dot';
info.MatPath{11} = 'dof_states.error';
info.MatPath{12} = 'dof_states.error_dot';
info.MatPath{13} = 'dof_states.time_step';
info.MatPath{14} = 'dof_states.output';
