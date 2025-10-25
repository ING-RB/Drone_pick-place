classdef(Hidden) FactorTypeEnum < double
%This class is for internal use only. It may be removed in the future.

%   Copyright 2023 The MathWorks, Inc.

    %FACTORTYPEENUM Enum class for the all factor types same as the back
    %end
   
    enumeration
        Two_SE2_F (0) 
        Two_SE3_F (1)
        SE2_Point2_F (2)
        SE3_Point3_F (3)
        IMU_F (4)
        GPS_F (5)
        SE2_Prior_F (6)
        SE3_Prior_F (7)
        IMU_Bias_Prior_F (8)
        Vel3_Prior_F (9)
        Camera_SE3_Point3_F (10)
    end

end