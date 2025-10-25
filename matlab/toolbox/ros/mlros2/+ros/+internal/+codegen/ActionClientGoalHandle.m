classdef ActionClientGoalHandle < ros.internal.mixin.InternalAccess
%This class is for internal use only. It may be removed in the future.

%ActionClientGoalHandle Goal handle object for ROS 2 action client goals
%   Use ActionClientGoalHandle to inspect and interact with goals sent by
%   action clients. Each goal has its unique goal handle, which associated
%   with the action client object that sent out the goal. You can query
%   goal information or get goal results by accessing properties and member
%   functions of goal handle.

%   Copyright 2022 The MathWorks, Inc.
%#codegen
    properties (Hidden)
        %GoalIndex - Goal Index used in backend to identify goals
        GoalIndex
        %ActionClientHandle - handle for action client associate with goal
        ActionClientHandle
    end

    properties (SetAccess = private)
        %GoalUUID - unique ID for action client goal
        GoalUUID
        %TimeStamp - time stamp when goal was accepted by action server
        TimeStamp
        %Status - Goal status associated with the goal handle
        Status
    end

    methods
        function obj = ActionClientGoalHandle(actClientHandle, goalIndex, goalUUID, timeStamp)
        %ActionClientGoalHandle Create a ROS 2 action goal handle object
        %   The action goal handle object will be created and returned as
        %   the output of sendGoal function in ros2actionclient. Please see
        %   the class documentation (help ros2actionclient) for more
        %   details.

            obj.ActionClientHandle = actClientHandle;
            obj.GoalIndex = goalIndex;
            obj.GoalUUID = goalUUID;
            obj.TimeStamp = timeStamp;
        end

        function status = get.Status(obj)
        %getter function to return property Status
            status = obj.ActionClientHandle.getStatus(obj);
        end

        function [resultMsg, status, statusText] = getResult(obj, varargin)
        %GETRESULT Get the result message and code for action goal
        %   RESULTMSG = GETRESULT(GOALHANDLE) blocks MATLAB from running
        %   the current program until the result response message of the
        %   goal handle, GOALHANDLE, arrived. Press Ctrl+C to abort the
        %   wait.
        %
        %   RESULTMSG = GETRESULT(___,Name=Value) provides additional 
        %   options specified by one or more Name=Value pair arguments.
        %   You can specify several name-value pair arguments in any 
        %   order as Name1,Value1,...,NameN,ValueN:
        %
        %       "Timeout" - Specifies a timeout period, in seconds. If 
        %                   the result does not return in the timeout 
        %                   period, this function displays an error 
        %                   message and lets MATLAB continue running the
        %                   current program. Otherwise, the default 
        %                   value is Inf, which blocks MATLAB from 
        %                   running the current program until the action
        %                   server is available.
        %
        %   [RESULTMSG,STATUS,STATUSTEXT] = GETRESULT(___) returns the
        %   final receive status and the associated status text. The STATUS
        %   indicates if the result message has been received successfully
        %   or not and the associated STATUSTEXT will capture information
        %   about the status. The STATUSTEXT can be one of the following:
        %
        %       'unknown'   - Failed to return for unknown reason. 
        %       'succeeded' - The result message was successfully received.
        %       'canceled'  - Failed to return because goal was canceled.
        %       'aborted'   - Failed to return because goal was aborted.
        %       'input'     - The input to the function is invalid.
        %       'timeout'   - Failed to return within the specified timeout.

            [resultMsg, status, statusText] = obj.ActionClientHandle.getResult(obj, varargin{:});
        end
    end
end