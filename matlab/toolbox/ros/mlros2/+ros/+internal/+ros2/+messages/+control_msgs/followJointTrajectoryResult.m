function [data, info] = followJointTrajectoryResult
%FollowJointTrajectoryResult gives an empty data for control_msgs/FollowJointTrajectoryResult

% Copyright 2019-2021 The MathWorks, Inc.
data = struct();
data.MessageType = 'control_msgs/FollowJointTrajectoryResult';
[data.error_code, info.error_code] = ros.internal.ros2.messages.ros2.default_type('int32',1,0);
[data.SUCCESSFUL, info.SUCCESSFUL] = ros.internal.ros2.messages.ros2.default_type('int32',1,0, 0, [NaN]);
[data.INVALID_GOAL, info.INVALID_GOAL] = ros.internal.ros2.messages.ros2.default_type('int32',1,0, -1, [NaN]);
[data.INVALID_JOINTS, info.INVALID_JOINTS] = ros.internal.ros2.messages.ros2.default_type('int32',1,0, -2, [NaN]);
[data.OLD_HEADER_TIMESTAMP, info.OLD_HEADER_TIMESTAMP] = ros.internal.ros2.messages.ros2.default_type('int32',1,0, -3, [NaN]);
[data.PATH_TOLERANCE_VIOLATED, info.PATH_TOLERANCE_VIOLATED] = ros.internal.ros2.messages.ros2.default_type('int32',1,0, -4, [NaN]);
[data.GOAL_TOLERANCE_VIOLATED, info.GOAL_TOLERANCE_VIOLATED] = ros.internal.ros2.messages.ros2.default_type('int32',1,0, -5, [NaN]);
[data.error_string, info.error_string] = ros.internal.ros2.messages.ros2.char('string',1,NaN,0);
info.MessageType = 'control_msgs/FollowJointTrajectoryResult';
info.constant = 0;
info.default = 0;
info.maxstrlen = NaN;
info.MaxLen = 1;
info.MinLen = 1;
info.MatPath = cell(1,8);
info.MatPath{1} = 'error_code';
info.MatPath{2} = 'SUCCESSFUL';
info.MatPath{3} = 'INVALID_GOAL';
info.MatPath{4} = 'INVALID_JOINTS';
info.MatPath{5} = 'OLD_HEADER_TIMESTAMP';
info.MatPath{6} = 'PATH_TOLERANCE_VIOLATED';
info.MatPath{7} = 'GOAL_TOLERANCE_VIOLATED';
info.MatPath{8} = 'error_string';
