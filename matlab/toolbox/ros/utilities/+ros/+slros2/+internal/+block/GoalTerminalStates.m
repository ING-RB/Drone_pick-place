classdef GoalTerminalStates < int8
%This class is for internal use only. It may be removed in the future.

%GoalTerminalStates Terminal states for an action goal on ROS/ROS 2 network.
%   All the enumerations are prefixed with "SL", since the property
%   names will become defines in the generated C++ code and we want to
%   avoid name collisions.
%
%   See also CancelActionGoal.

%   Copyright 2023 The MathWorks, Inc.

%#codegen

    enumeration
        % SLSucceeded - The goal has been achieved successfully by the action server.
        SLSucceeded (4)

        % SLCanceled - The goal has been canceled after an external request from an action client.
        SLCanceled (5)

        % SLAborted - The goal has been terminated by the action server without an external request.
        SLAborted (6)

        % SLRejected - The goal has been rejected by the action server
        SLRejected (-1)
    end
end
