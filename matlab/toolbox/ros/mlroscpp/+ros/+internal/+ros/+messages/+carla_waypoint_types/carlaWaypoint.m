function [data, info] = carlaWaypoint
%CarlaWaypoint gives an empty data for carla_waypoint_types/CarlaWaypoint

% Copyright 2019-2020 The MathWorks, Inc.
%#codegen
data = struct();
data.MessageType = 'carla_waypoint_types/CarlaWaypoint';
[data.RoadId, info.RoadId] = ros.internal.ros.messages.ros.default_type('int32',1);
[data.SectionId, info.SectionId] = ros.internal.ros.messages.ros.default_type('int32',1);
[data.LaneId, info.LaneId] = ros.internal.ros.messages.ros.default_type('int32',1);
[data.IsJunction, info.IsJunction] = ros.internal.ros.messages.ros.default_type('logical',1);
[data.Pose, info.Pose] = ros.internal.ros.messages.geometry_msgs.pose;
info.Pose.MLdataType = 'struct';
info.MessageType = 'carla_waypoint_types/CarlaWaypoint';
info.constant = 0;
info.default = 0;
info.maxstrlen = NaN;
info.MaxLen = 1;
info.MinLen = 1;
info.MatPath = cell(1,14);
info.MatPath{1} = 'road_id';
info.MatPath{2} = 'section_id';
info.MatPath{3} = 'lane_id';
info.MatPath{4} = 'is_junction';
info.MatPath{5} = 'pose';
info.MatPath{6} = 'pose.position';
info.MatPath{7} = 'pose.position.x';
info.MatPath{8} = 'pose.position.y';
info.MatPath{9} = 'pose.position.z';
info.MatPath{10} = 'pose.orientation';
info.MatPath{11} = 'pose.orientation.x';
info.MatPath{12} = 'pose.orientation.y';
info.MatPath{13} = 'pose.orientation.z';
info.MatPath{14} = 'pose.orientation.w';
