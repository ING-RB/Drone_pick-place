function [data, info] = velocityStamped
%VelocityStamped gives an empty data for geometry_msgs/VelocityStamped

% Copyright 2019-2021 The MathWorks, Inc.
data = struct();
data.MessageType = 'geometry_msgs/VelocityStamped';
[data.header, info.header] = ros.internal.ros2.messages.std_msgs.header;
info.header.MLdataType = 'struct';
[data.body_frame_id, info.body_frame_id] = ros.internal.ros2.messages.ros2.char('string',1,NaN,0);
[data.reference_frame_id, info.reference_frame_id] = ros.internal.ros2.messages.ros2.char('string',1,NaN,0);
[data.velocity, info.velocity] = ros.internal.ros2.messages.geometry_msgs.twist;
info.velocity.MLdataType = 'struct';
info.MessageType = 'geometry_msgs/VelocityStamped';
info.constant = 0;
info.default = 0;
info.maxstrlen = NaN;
info.MaxLen = 1;
info.MinLen = 1;
info.MatPath = cell(1,16);
info.MatPath{1} = 'header';
info.MatPath{2} = 'header.stamp';
info.MatPath{3} = 'header.stamp.sec';
info.MatPath{4} = 'header.stamp.nanosec';
info.MatPath{5} = 'header.frame_id';
info.MatPath{6} = 'body_frame_id';
info.MatPath{7} = 'reference_frame_id';
info.MatPath{8} = 'velocity';
info.MatPath{9} = 'velocity.linear';
info.MatPath{10} = 'velocity.linear.x';
info.MatPath{11} = 'velocity.linear.y';
info.MatPath{12} = 'velocity.linear.z';
info.MatPath{13} = 'velocity.angular';
info.MatPath{14} = 'velocity.angular.x';
info.MatPath{15} = 'velocity.angular.y';
info.MatPath{16} = 'velocity.angular.z';
