classdef SendGoalErrorCode < uint8
%This class is for internal use only. It may be removed in the future.

%SendGoalErrorCode Error Codes for Send Action Goal block. These represent
%   the kind of error occurred when sending a goal on ROS/ROS 2 network.
%   All the enumerations are prefixed with "SL", since the property
%   names will become defines in the generated C++ code and we want to
%   avoid name collisions.
%
%   See also SendActionGoal.

%   Copyright 2023 The MathWorks, Inc.

%#codegen

    enumeration
        %SLSendGoalSuccess - Action goal is sent successfully
        SLSendGoalSuccess (0)

        %SLSendGoalRejected - Action server rejected the goal request
        SLSendGoalRejected (1)

        %SLSendGoalFailure - Sending goal to the action server failed
        SLSendGoalFailure (2)

        %SLSendGoalServerUnavailable - Action server is not available
        SLSendGoalServerUnavailable (3)
    end
end
