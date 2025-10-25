function [data, info] = meshFile
%MeshFile gives an empty data for visualization_msgs/MeshFile

% Copyright 2019-2021 The MathWorks, Inc.
data = struct();
data.MessageType = 'visualization_msgs/MeshFile';
[data.filename, info.filename] = ros.internal.ros2.messages.ros2.char('string',1,NaN,0);
[data.data, info.data] = ros.internal.ros2.messages.ros2.default_type('uint8',NaN,0);
info.MessageType = 'visualization_msgs/MeshFile';
info.constant = 0;
info.default = 0;
info.maxstrlen = NaN;
info.MaxLen = 1;
info.MinLen = 1;
info.MatPath = cell(1,2);
info.MatPath{1} = 'filename';
info.MatPath{2} = 'data';
