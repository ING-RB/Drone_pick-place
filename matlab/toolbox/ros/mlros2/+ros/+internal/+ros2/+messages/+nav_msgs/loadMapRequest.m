function [data, info] = loadMapRequest
%LoadMap gives an empty data for nav_msgs/LoadMapRequest

% Copyright 2019-2021 The MathWorks, Inc.
data = struct();
data.MessageType = 'nav_msgs/LoadMapRequest';
[data.map_url, info.map_url] = ros.internal.ros2.messages.ros2.char('string',1,NaN,0);
info.MessageType = 'nav_msgs/LoadMapRequest';
info.constant = 0;
info.default = 0;
info.maxstrlen = NaN;
info.MaxLen = 1;
info.MinLen = 1;
info.MatPath = cell(1,1);
info.MatPath{1} = 'map_url';
