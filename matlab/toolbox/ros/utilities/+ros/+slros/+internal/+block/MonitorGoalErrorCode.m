classdef MonitorGoalErrorCode < uint8
%This class is for internal use only. It may be removed in the future.

%MonitorGoalErrorCode Error Codes for Monitor Action Goal block. These represent
%   the kind of error occurred when monitoring a goal that was sent on ROS/ROS 2 network.
%   All the enumerations are prefixed with "SL", since the property
%   names will become defines in the generated C++ code and we want to
%   avoid name collisions.
%
%   See also CancelActionGoal.

%   Copyright 2023 The MathWorks, Inc.

%#codegen

    enumeration
        %SLMonitorGoalSuccess - Action goal have transitioned to the CANCELING state successfully
        SLMonitorGoalSuccess (0)

        %SLMonitorGoalRejected - Action server rejected the goal request, no
        %feedback or result should be received
        SLMonitorGoalRejected (1)

        %SLMonitorGoalInvalidUUID - Action goal ID does not exist.
        SLMonitorGoalInvalidUUID (2)

        %SLMonitorGoalServerUnavailable - Action server is not available
        SLMonitorGoalServerUnavailable (3)
    end
end
