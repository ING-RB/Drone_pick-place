function [data, info] = getActorWaypointRequest
%GetActorWaypoint gives an empty data for carla_waypoint_types/GetActorWaypointRequest

% Copyright 2019-2020 The MathWorks, Inc.
%#codegen
data = struct();
data.MessageType = 'carla_waypoint_types/GetActorWaypointRequest';
[data.Id, info.Id] = ros.internal.ros.messages.ros.default_type('uint32',1);
info.MessageType = 'carla_waypoint_types/GetActorWaypointRequest';
info.constant = 0;
info.default = 0;
info.maxstrlen = NaN;
info.MaxLen = 1;
info.MinLen = 1;
info.MatPath = cell(1,1);
info.MatPath{1} = 'id';
