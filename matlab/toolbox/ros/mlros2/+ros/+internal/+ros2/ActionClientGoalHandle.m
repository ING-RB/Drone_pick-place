classdef ActionClientGoalHandle < ros.internal.mixin.InternalAccess & ...
        robotics.core.internal.mixin.Unsaveable & handle
%This class is for internal use only. It may be removed in the future.

%ActionClientGoalHandle Goal handle object for ROS 2 action client goals
%   Use ActionClientGoalHandle to inspect and interact with goals sent by
%   action clients. Each goal has its unique goal handle, which associated
%   with the action client object that sent out the goal. You can query
%   goal information or get goal results by accessing properties and member
%   functions of goal handle.
%
%   Use the sendGoal method on a ros2ActionClient object to create an
%   ActionClientGoalHandle object.
%
%
%   ActionClientGoalHandle properties:
%      GoalUUID    - (Read-Only) Unique ID for action client goal
%      Status      - (Read-Only) Goal status of the goal
%      TimeStamp   - (Read-Only) Timestamp when goal was accepted by server
%      FeedbackFcn - (Read-Only) Feedback callback function
%      ResultFcn   - (Read-Only) Result callback function
%
%   ActionClientGoalHandle methods:
%      getResult   - Get result message and code associated with the goal
%
%   Example:
%      % Create a ROS 2 node
%      node = ros2node("/node_1");
%
%      % Create an action client and wait to connect to the action server
%      % (blocking). This assumes there is an action server for this action
%      % name in existence.
%      client = ROS2ACTIONCLIENT(node,"fibonacci",...
%          "example_interfaces/Fibonacci");
%      waitForServer(client);
%
%      % Create the goal message
%      goalMsg = ros2message(client);
%      goalMsg.order = int32(8);
%
%      % Send a goal to the server. This call will return immediately.
%      goalHandle = sendGoal(client,goalMsg);
%
%      % Get int8 status of the goal at any stage during goal execution
%      % Refer to the following link for goal stage representation
%      % https://docs.ros2.org/foxy/api/action_msgs/msg/GoalStatus.html
%      status = goalHandle.Status;
%
%      % Get result message, final status, and statusText of the goal
%      with a timeout of 10s.
%      [resultMsg,status,statusText] = getResult(goalHandle,Timeout=10);
%       

%   Copyright 2022-2023 The MathWorks, Inc.

    properties (Hidden)
        %GoalIndex - Goal Index used in backend to identify goals
        GoalIndex

        %ActionClientHandle - handle for action client associate with goal
        ActionClientHandle

        %LatestInfoMapForFeedbackCB - Map that contains feedback 
        % callback function name as key and latest available information
        % for the callback as value.
        LatestInfoMapForFeedbackCB
    end

    properties (SetAccess = private)
        %GoalUUID - unique ID for action client goal
        GoalUUID

        %Status - Goal status associated with the goal handle
        Status

        %TimeStamp - time stamp when goal was accepted by action server
        TimeStamp

        %FeedbackFcn - Feedback callback associated with goal
        FeedbackFcn

        %ResultFcn - Result callback associated with goal
        ResultFcn
    end

    properties(Hidden, SetAccess = private)
        %GoalUUIDInUint8 - Unique ID in uint8 for action client goal
        GoalUUIDInUint8
    end
    
    methods
        function obj = ActionClientGoalHandle(actionClient, goalIndex, feedbackFcn, resultFcn)
        %ActionClientGoalHandle Create a ROS 2 action goal handle object
        %   The action goal handle object will be created and returned as
        %   the output of sendGoal function in ros2actionclient. Please see
        %   the class documentation (help ros2actionclient) for more
        %   details.

        % Validate input arguments
            validateattributes(actionClient, {'matlab.internal.WeakHandle'}, ...
                {'scalar'}, 'ActionClientGoalHandle', 'actionClient');
            validateattributes(goalIndex, {'numeric'}, ...
                {'scalar','integer','positive'}, ...
                'ActionClientGoalHandle','goalIndex');
            validateattributes(feedbackFcn, ...
                {'function_handle'}, {'scalar','nonempty'}, ...
                'ActionClientGoalHandle', 'feedbackFcn');
            validateattributes(resultFcn, ...
                {'function_handle'}, {'scalar','nonempty'}, ...
                'ActionClientGoalHandle', 'resultFcn');
            % Assign to properties
            obj.ActionClientHandle = actionClient;
            obj.GoalIndex = goalIndex;
            obj.FeedbackFcn = feedbackFcn;
            obj.ResultFcn = resultFcn;
            obj.LatestInfoMapForFeedbackCB = containers.Map('KeyType', 'char', 'ValueType', 'Any');
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

            status = false;
            statusText = 'unknown';
            if nargout > 1
                [resultMsg, status, statusText] = obj.ActionClientHandle.get.getResult(obj, varargin{:});
            else
                resultMsg = obj.ActionClientHandle.get.getResult(obj, varargin{:});
            end
        end

        function cancelGoal(obj,varargin)
        %CANCELGOAL Cancel specific goal using goal handle
        %   CANCELGOAL(GOALHANDLE) sends a cancel request for the
        %   goal associated with the goal handle, GOALHANDLE. The function 
        %   does not wait for the goal to be cancelled and returns
        %   immediately.
        %
        %   CANCELGOAL(___,Name=Value) provides additional options
        %   specified by one or more Name=Value pair arguments. You can
        %   specify several name-value pair arguments in any order as
        %   Name1=Value1,...,NameN=ValueN:
        %
        %       "CancelFcn" - Specifies a callback function. This function 
        %                     is called when the cancel response reaches
        %                     this action client. The first argument, GH,
        %                     is the goal handle of the corresponding goal.
        %                     The function signature is as follows:
        %
        %                       function cancelFcn(GH, MSG, VARARGIN)
        %
        %                     You pass additional arguments to the callback
        %                     function by including both the callback
        %                     function and the arguments as elements of a
        %                     cell array when setting the property.

            obj.ActionClientHandle.get.cancelGoal(obj, varargin{:});
        end

        function status = getStatus(obj)
        %GETSTATUS Get status from goal handle associated with specific goal
        %   STATUS = GETSTATUS(GOALHANDLE) returns an int8 status
        %   indicating current status of the goal corresponding to the 
        %   goal handle, GOALHANDLE. The default goal status is returned as -1, 
        %   if the server does not accept the goal. Refer to this page for more
        %   information about goal status:
        %       https://docs.ros2.org/foxy/api/action_msgs/msg/GoalStatus.html

            status = obj.ActionClientHandle.get.getStatus(obj);
        end
    end

    %% Custom Getter and Setter functions
    methods
        function timeStamp = get.TimeStamp(obj)
            timeStamp = obj.ActionClientHandle.get.getGoalInfo(obj.GoalIndex, 'TimeStamp');
        end

        function goalUUID = get.GoalUUID(obj)
            goalUUID = obj.ActionClientHandle.get.getGoalInfo(obj.GoalIndex, 'GoalUUID');
        end

        function goalUUIDInUint8 = get.GoalUUIDInUint8(obj)
            goalUUIDInUint8 = obj.ActionClientHandle.get.getGoalInfo(obj.GoalIndex, 'GoalUUIDInUint8');
        end

        function goalStatus = get.Status(obj)
            goalStatus = obj.ActionClientHandle.get.getGoalInfo(obj.GoalIndex, 'GoalStatus');
        end
    end
end
