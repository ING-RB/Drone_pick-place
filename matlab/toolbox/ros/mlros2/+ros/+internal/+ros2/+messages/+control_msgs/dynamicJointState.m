function [data, info] = dynamicJointState
%DynamicJointState gives an empty data for control_msgs/DynamicJointState

% Copyright 2019-2021 The MathWorks, Inc.
data = struct();
data.MessageType = 'control_msgs/DynamicJointState';
[data.header, info.header] = ros.internal.ros2.messages.std_msgs.header;
info.header.MLdataType = 'struct';
[data.joint_names, info.joint_names] = ros.internal.ros2.messages.ros2.char('string',NaN,NaN,0);
[data.interface_values, info.interface_values] = ros.internal.ros2.messages.control_msgs.interfaceValue;
info.interface_values.MLdataType = 'struct';
info.interface_values.MaxLen = NaN;
info.interface_values.MinLen = 0;
info.MessageType = 'control_msgs/DynamicJointState';
info.constant = 0;
info.default = 0;
info.maxstrlen = NaN;
info.MaxLen = 1;
info.MinLen = 1;
info.MatPath = cell(1,9);
info.MatPath{1} = 'header';
info.MatPath{2} = 'header.stamp';
info.MatPath{3} = 'header.stamp.sec';
info.MatPath{4} = 'header.stamp.nanosec';
info.MatPath{5} = 'header.frame_id';
info.MatPath{6} = 'joint_names';
info.MatPath{7} = 'interface_values';
info.MatPath{8} = 'interface_values.interface_names';
info.MatPath{9} = 'interface_values.values';
