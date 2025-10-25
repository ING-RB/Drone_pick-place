function [data, info] = carlaCollisionEvent
%CarlaCollisionEvent gives an empty data for carla_msgs/CarlaCollisionEvent

% Copyright 2019-2020 The MathWorks, Inc.
%#codegen
data = struct();
data.MessageType = 'carla_msgs/CarlaCollisionEvent';
[data.Header, info.Header] = ros.internal.ros.messages.std_msgs.header;
info.Header.MLdataType = 'struct';
[data.OtherActorId, info.OtherActorId] = ros.internal.ros.messages.ros.default_type('uint32',1);
[data.NormalImpulse, info.NormalImpulse] = ros.internal.ros.messages.geometry_msgs.vector3;
info.NormalImpulse.MLdataType = 'struct';
info.MessageType = 'carla_msgs/CarlaCollisionEvent';
info.constant = 0;
info.default = 0;
info.maxstrlen = NaN;
info.MaxLen = 1;
info.MinLen = 1;
info.MatPath = cell(1,11);
info.MatPath{1} = 'header';
info.MatPath{2} = 'header.seq';
info.MatPath{3} = 'header.stamp';
info.MatPath{4} = 'header.stamp.sec';
info.MatPath{5} = 'header.stamp.nsec';
info.MatPath{6} = 'header.frame_id';
info.MatPath{7} = 'other_actor_id';
info.MatPath{8} = 'normal_impulse';
info.MatPath{9} = 'normal_impulse.x';
info.MatPath{10} = 'normal_impulse.y';
info.MatPath{11} = 'normal_impulse.z';
