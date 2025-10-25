function [data, info] = getWaypointRequest
%GetWaypoint gives an empty data for carla_waypoint_types/GetWaypointRequest

% Copyright 2019-2020 The MathWorks, Inc.
%#codegen
data = struct();
data.MessageType = 'carla_waypoint_types/GetWaypointRequest';
[data.Location, info.Location] = ros.internal.ros.messages.geometry_msgs.point;
info.Location.MLdataType = 'struct';
info.MessageType = 'carla_waypoint_types/GetWaypointRequest';
info.constant = 0;
info.default = 0;
info.maxstrlen = NaN;
info.MaxLen = 1;
info.MinLen = 1;
info.MatPath = cell(1,4);
info.MatPath{1} = 'location';
info.MatPath{2} = 'location.x';
info.MatPath{3} = 'location.y';
info.MatPath{4} = 'location.z';
