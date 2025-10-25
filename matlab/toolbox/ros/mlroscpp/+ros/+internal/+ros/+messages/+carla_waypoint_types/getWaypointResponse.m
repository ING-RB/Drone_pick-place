function [data, info] = getWaypointResponse
%GetWaypoint gives an empty data for carla_waypoint_types/GetWaypointResponse

% Copyright 2019-2020 The MathWorks, Inc.
%#codegen
data = struct();
data.MessageType = 'carla_waypoint_types/GetWaypointResponse';
[data.Waypoint, info.Waypoint] = ros.internal.ros.messages.carla_waypoint_types.carlaWaypoint;
info.Waypoint.MLdataType = 'struct';
info.MessageType = 'carla_waypoint_types/GetWaypointResponse';
info.constant = 0;
info.default = 0;
info.maxstrlen = NaN;
info.MaxLen = 1;
info.MinLen = 1;
info.MatPath = cell(1,15);
info.MatPath{1} = 'waypoint';
info.MatPath{2} = 'waypoint.road_id';
info.MatPath{3} = 'waypoint.section_id';
info.MatPath{4} = 'waypoint.lane_id';
info.MatPath{5} = 'waypoint.is_junction';
info.MatPath{6} = 'waypoint.pose';
info.MatPath{7} = 'waypoint.pose.position';
info.MatPath{8} = 'waypoint.pose.position.x';
info.MatPath{9} = 'waypoint.pose.position.y';
info.MatPath{10} = 'waypoint.pose.position.z';
info.MatPath{11} = 'waypoint.pose.orientation';
info.MatPath{12} = 'waypoint.pose.orientation.x';
info.MatPath{13} = 'waypoint.pose.orientation.y';
info.MatPath{14} = 'waypoint.pose.orientation.z';
info.MatPath{15} = 'waypoint.pose.orientation.w';
