classdef(Hidden) NodeTypeEnum < int32
%This class is for internal use only. It may be removed in the future.

%   Copyright 2024 The MathWorks, Inc.

    %NODETYPEENUM Enum class for the all node types same as the back
    %end used in factor graph
   
    enumeration
        All_Types (-2)
        None (-1)
        Pose_SE3 (0)
        Pose_SE2 (1)
        Point_XY (2)
        Point_XYZ (3)
        Vel_3 (4)
        IMU_Bias (5)
        Pseudo_Pose_SE3 (6)
        Orientation_SO3 (7)
        Orientation_SO3_AD (8)
        Eigen_Quaternion (9)
        Angle (10)
        Pose_SE3_Scale (11)
        Transform_SE3 (12)
    end

end