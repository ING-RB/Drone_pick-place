classdef CancelGoalErrorCode < uint8
%This class is for internal use only. It may be removed in the future.

%CancelGoalErrorCode Error Codes for Cancel Action Goal block. These represent
%   the kind of error occurred when canceling a goal on ROS/ROS 2 network.
%   All the enumerations are prefixed with "SL", since the property
%   names will become defines in the generated C++ code and we want to
%   avoid name collisions.
%
%   See also CancelActionGoal.

%   Copyright 2023 The MathWorks, Inc.

%#codegen

    enumeration
        %SLCancelGoalSuccess - Action goal have transitioned to the CANCELING state successfully
        SLCancelGoalSuccess (0)

        %SLCancelGoalTerminated - Action goal is not cancelable because it is already in a terminal state
        SLCancelGoalTerminated (1)

        %SLCancelGoalInvalidUUID - Action goal ID does not exist.
        SLCancelGoalInvalidUUID (2)

        %SLCancelGoalServerUnavailable - Action server is not available
        SLCancelGoalServerUnavailable (3)
    end
end
