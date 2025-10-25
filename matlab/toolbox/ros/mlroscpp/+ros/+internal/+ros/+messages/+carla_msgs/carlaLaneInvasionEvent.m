function [data, info] = carlaLaneInvasionEvent
%CarlaLaneInvasionEvent gives an empty data for carla_msgs/CarlaLaneInvasionEvent

% Copyright 2019-2020 The MathWorks, Inc.
%#codegen
data = struct();
data.MessageType = 'carla_msgs/CarlaLaneInvasionEvent';
[data.Header, info.Header] = ros.internal.ros.messages.std_msgs.header;
info.Header.MLdataType = 'struct';
[data.CrossedLaneMarkings, info.CrossedLaneMarkings] = ros.internal.ros.messages.ros.default_type('int32',NaN);
[data.LANEMARKINGOTHER, info.LANEMARKINGOTHER] = ros.internal.ros.messages.ros.default_type('int32',1, 0);
[data.LANEMARKINGBROKEN, info.LANEMARKINGBROKEN] = ros.internal.ros.messages.ros.default_type('int32',1, 1);
[data.LANEMARKINGSOLID, info.LANEMARKINGSOLID] = ros.internal.ros.messages.ros.default_type('int32',1, 2);
info.MessageType = 'carla_msgs/CarlaLaneInvasionEvent';
info.constant = 0;
info.default = 0;
info.maxstrlen = NaN;
info.MaxLen = 1;
info.MinLen = 1;
info.MatPath = cell(1,10);
info.MatPath{1} = 'header';
info.MatPath{2} = 'header.seq';
info.MatPath{3} = 'header.stamp';
info.MatPath{4} = 'header.stamp.sec';
info.MatPath{5} = 'header.stamp.nsec';
info.MatPath{6} = 'header.frame_id';
info.MatPath{7} = 'crossed_lane_markings';
info.MatPath{8} = 'LANE_MARKING_OTHER';
info.MatPath{9} = 'LANE_MARKING_BROKEN';
info.MatPath{10} = 'LANE_MARKING_SOLID';
