function [data, info] = carlaBoundingBox
%CarlaBoundingBox gives an empty data for carla_msgs/CarlaBoundingBox

% Copyright 2019-2020 The MathWorks, Inc.
%#codegen
data = struct();
data.MessageType = 'carla_msgs/CarlaBoundingBox';
[data.Center, info.Center] = ros.internal.ros.messages.geometry_msgs.vector3;
info.Center.MLdataType = 'struct';
[data.Size, info.Size] = ros.internal.ros.messages.geometry_msgs.vector3;
info.Size.MLdataType = 'struct';
info.MessageType = 'carla_msgs/CarlaBoundingBox';
info.constant = 0;
info.default = 0;
info.maxstrlen = NaN;
info.MaxLen = 1;
info.MinLen = 1;
info.MatPath = cell(1,8);
info.MatPath{1} = 'center';
info.MatPath{2} = 'center.x';
info.MatPath{3} = 'center.y';
info.MatPath{4} = 'center.z';
info.MatPath{5} = 'size';
info.MatPath{6} = 'size.x';
info.MatPath{7} = 'size.y';
info.MatPath{8} = 'size.z';
