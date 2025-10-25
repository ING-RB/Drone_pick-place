classdef ros2actionclient < ros.ros2.internal.ActionQOSParser & ...
        ros.internal.mixin.InternalAccess & ...
        robotics.core.internal.mixin.Unsaveable & handle
%ROS2ACTIONCLIENT Create a simple ROS 2 action client
%   Use ROS2ACTIONCLIENT to connect to an action server and request the
%   execution of action goals. You can send multiple goals from the same
%   action client object, get feedback on the execution progress, and
%   cancel goals at any time.
%
%   CLIENT = ROS2ACTIONCLIENT(NODE, ACTIONNAME, ACTIONTYPE) creates a
%   CLIENT for the ROS 2 action with name ACTIONNAME and type ACTIONTYPE
%   regardless of whether an action server offering ACTIONNAME is
%   available. The action client is attached to the ros2node object, NODE.
%
%   CLIENT = ROS2ACTIONCLIENT(___,Name=Value) provides additional options
%   specified by one or more Name=Value pair arguments. You can specify
%   several name-value pair arguments in any order as
%   Name1= Value1, ..., NameN= ValueN:
%
%      "GoalServiceQoS"   - Quality of service settings to be declared for
%                           the goal service while sending goals through
%                           this action client. Specify a structure containing
%                           QoS settings such as History, Depth, 
%                           Reliability, and Durability.
%
%      "ResultServiceQoS" - Quality of service settings to be declared for
%                           the result service while getting result from
%                           action server. Specify a structure containing QoS
%                           settings such as History, Depth, Reliability,
%                           and Durability.
%
%      "CancelServiceQoS" - Quality of service settings to be declared for
%                           the cancel service while canceling goal(s) 
%                           through this action client. Specify a structure 
%                           containing QoS settings such as History, Depth,
%                           Reliability, and Durability.
%
%      "FeedbackTopicQoS" - Quality of service settings to be declared for
%                           the feedback topic while subscribing to goal
%                           feedback. Specify a structure containing QoS
%                           settings such as History, Depth, Reliability,
%                           and Durability.
%
%      "StatusTopicQoS"   - Quality of service settings to be declared for
%                           the status topic while getting goal status from
%                           action server. Specify a structure containing QoS
%                           settings such as History, Depth, Reliability,
%                           and Durability.
%
%   NOTE: The "Reliability" and "Durability" quality of service settings
%   mut be compatible between action servers and clients for a connection
%   to be made.
%
%   [CLIENT, GOALMSG] = ROS2ACTIONCLIENT(___) returns a goal message,
%   GOALMSG, that you can use to send to action server for execution. The
%   message will be initialized with default values.
%
%
%   ROS2ACTIONCLIENT properties:
%      ActionName        - (Read-Only) The name of the action
%      ActionType        - (Read-Only) The type of the action
%      IsServerConnected - (Read-Only) Indicates if client is connected to action server
%      GoalServiceQoS    - (Read-Only) Service QoS settings for sending goal
%      ResultServiceQoS  - (Read-Only) Service QoS settings for getting result
%      CancelServiceQoS  - (Read-Only) Service QoS settings for canceling goal
%      FeedbackTopicQoS  - (Read-Only) Topic QoS settings for receiving feedback 
%      StatusTopicQoS    - (Read-Only) Topic QoS settings for receiving goal status
%
%   ROS2ACTIONCLIENT methods:
%      ros2message              - Create goal message
%      waitforServer            - wait for action server to start
%      sendGoal                 - Send goal message to action server
%      cancelGoal               - Cancel specific goal this client sent
%      cancelGoalAndWait        - Cancel specific goal and wait for cancel response
%      cancelGoalsBefore        - Cancel goals accepted before timestamp
%      cancelGoalsBeforeAndWait - Cancel goals accepted before timestamp and wait for cancel response
%      cancelAllGoals           - Cancel all active goals this client sent
%      cancelAllGoalsAndWait    - Cancel all active goals this client send and wait for cancel response
%      getStatus                - Get status of specific goal this client sent
%      getResult                - Get result of specific goal this client sent
%
%   Example:
%      % Create a ROS 2 node
%      node = ros2node("/node_1");
%
%      % Create an action client and wait to connect to the action server
%      % (blocking). This assumes there is an action server for this action
%      % name in existence.
%      client = ROS2ACTIONCLIENT(node,"fibonacci",...
%          "example_interfaces/Fibonacci", ...
%          CancelServiceQoS=struct(Depth=200,History="keeplast"), ...
%          FeedbackTopicQoS=struct(Depth=200,History="keepall"));
%      waitForServer(client);
%
%      % Create the goal message
%      goalMsg = ros2message(client);
%      goalMsg.order = int32(8);
%
%      % Create optional callback functions
%      callbackOpts = ros2ActionSendGoalOptions(...
%          FeedbackFcn=@printFeedback, ...
%          ResultFcn=@printResult);
%
%      % Send a goal with customized callback functions to the server. This
%      call will return immediately.
%      goalHandle = sendGoal(client,goalMsg,callbackOpts);
%
%      function printFeedback(goalHandle,resp)
%          seq = resp.sequence;
%          fprintf("Feedback: Numbers for goal %s in received sequence: [", goalHandle.GoalUUID);
%          for i=1:numel(seq)
%              fprintf(" %d",seq(i));
%          end
%          fprintf(' ]\n');
%      end
%
%      function printResult(goalHandle,resp)
%          seq = resp.result.sequence;
%          fprintf("Result: Numbers for goal %s in received sequence: [", goalHandle.GoalUUID);
%          for i=1:numel(seq)
%              fprintf(" %d",seq(i));
%          end
%          fprintf(' ]\n');
%      end

%   Copyright 2022-2023 The MathWorks, Inc.

    properties (SetAccess = private)
        %ActionName - Name of action associated with this client
        ActionName = ''

        %ActionType - Type of action associated with this client
        ActionType = ''

        %IsServerConnected - Indicates if client is connected to action server
        %   See also waitForServer
        IsServerConnected = false

        %GoalServiceQoS - QoS for Goal Service
        GoalServiceQoS

        %ResultServiceQoS - QoS for Result Service
        ResultServiceQoS

        %CancelServiceQoS - QoS for Cancel Service
        CancelServiceQoS

        %FeedbackTopicQoS - QoS for Feedback Topic
        FeedbackTopicQoS

        %StatusTopicQoS - QoS for Status Topic
        StatusTopicQoS
    end

    properties (Transient, Access = {?ros.internal.mixin.InternalAccess,...
                                     ?matlab.unittest.TestCase})
        %ActClientCallbackHandler - Helper to handle callbacks
        ActClientCallbackHandler = []

        %InternalNode - Internal representation of the node object
        %   Node required to get action client property information
        InternalNode = []

        %ServerNodeHandle - Designation of the node on the server
        %   Node handle required to get action client property information
        ServerNodeHandle = []

        %ActClientHandle - Designation of the action-client on the server
        %   This is required to get property information
        ActClientHandle = []

        %ActionInfo - includes other information for a given action
        %   This is required to properly create an action client
        ActionInfo = struct.empty

        %MaxConcurrentCallbacks - Number of callbacks allowed in queue.
        %   The concurrent callbacks limits the number of callbacks allowed
        %   on the main MATLAB thread, and is set to the recursion limit
        %   upon construction by default.
        MaxConcurrentCallbacks

        %Goal Index that will be sent to sendGoalActServer as parameter.
        GoalIndexInput = int64(0)
    end

    properties (Access = private)
        %CallbackFcnDataStruct - Struct containing GoalRespFcn, 
        %GoalRespUserData, FeedbackFcn, FeedbackUserData, ResultFcn, 
        %ResultUserData.
        CallbackFcnDataStruct

        %GoalInfoStruct - Struct for saving goal information containing 
        %GoalUUID, TimeStamp, ResultMsg, and ResultCode.
        GoalInfoStruct

        %GoalHandleHistory - Struct to save goal handles
        GoalHandleHistory

        %GoalCancelFcnStruct - Struct containing CancelFcn, CancelUserData,
        %and CancelResponse.
        GoalCancelFcnStruct

        %CancelAllGoalsResponse - Response to CancelAllGoals
        CancelAllGoalsResponse

        %CancelGoalsBeforeResponse - Response to CancelGoalsBefore
        CancelGoalsBeforeResponse

        %ActualCancelAllCallbackFcn - Callback function for CancelAllGoals
        ActualCancelAllCallbackFcn

        %ActualCancelAllUserData - Callback user data for CancelAllGoals
        ActualCancelAllUserData

        %ActualCancelBeforeCallbackFcn - Callback function for CancelGoalsBefore
        ActualCancelBeforeCallbackFcn

        %ActualCancelBeforeUserData - Callback user data for CancelGoalsBefore
        ActualCancelBeforeUserData

        %ClientUniqueID - Unique ID to identify action client
        ClientUniqueID

        %IsGoalReadyForAccess - Check whether goal information are ready
        IsGoalReadyForAccess = logical([]);
    end

    properties (Constant, Access = private)
        %DefaultTimeout - The default timeout for server connection
        DefaultTimeout = Inf

        %DefaultCallbackFcn - The default callback function
        DefaultCallbackFcn = @(goalHandle,cancelResp) []

        %CodeMap - dictionary for saving result codes
        %CodeMap is created based on:
        %   https://docs.ros2.org/foxy/api/action_msgs/msg/GoalStatus.html
        CodeMap = containers.Map(int8([0 4 5 6]), ...
                                    {'unknown', 'succeeded', ...
                                     'canceled', 'aborted'})
    end

    methods
        function [obj, varargout] = ros2actionclient(node, actionName, actionType, varargin)
        %ros2actionclient Create a ROS 2 action client object
        %   Attach a new action client to the given ROS 2 node. The "name"
        %   and "type" arguments are required and specifies the action to
        %   which this client should connect. Please see the class
        %   documentation (help ros2actionclient) for more details.

        % Parse the inputs to the constructor
            [actionName, actionType] = ...
                convertStringsToChars(actionName, actionType);
            parser = getConstructorParser(obj);
            parse(parser, node, actionName, actionType);

            node = parser.Results.node;
            resolvedName = resolveName(node, parser.Results.actionName);
            actionType = parser.Results.actionType; 

            % Parse QoS settings
            % Note: To avoid code generation required name-value pair 
            % affecting MATLAB interpretation, the following parsing is 
            % required.
            [paramNameParser, paramStructParser, codegenParser] = getParsers(obj);
            [codegenStartIdx, codegenEndIdx] = ros.internal.Parsing.findNameValueRangeIndex(varargin, codegenParser.Parameters);
            [paramStartIdx, paramEndIdx] = ros.internal.Parsing.findNameValueRangeIndex(varargin, paramNameParser.Parameters);

            parse(codegenParser, varargin{codegenStartIdx:codegenEndIdx});
            parse(paramNameParser, varargin{paramStartIdx:paramEndIdx});

            fs = fieldnames(paramNameParser.Results);
            % Length must be greater than 0
            fslen = length(fs);
            for i = 1:fslen
                parse(paramStructParser, paramNameParser.Results.(fs{i}));
                % Handle quality of service settings
                fs{i} = getQosSettings(obj, paramStructParser.Results);
            end

            % Handle quality of service settings
            % fs is organized by alphabetical order
            qosSettings = struct('goal_service_qos', fs{3}, ...
                'result_service_qos', fs{4}, ...
                'cancel_service_qos', fs{1}, ...
                'feedback_topic_qos', fs{2}, ...
                'status_topic_qos', fs{5});

            % Default QoS Depth is 1, and default QoS Durability is
            % transientlocal for ROS 2 Action
            if ~isfield(qosSettings.status_topic_qos,'depth')
                qosSettings.status_topic_qos.depth = uint64(1);
            end
            if ~isfield(qosSettings.status_topic_qos,'durability')
                qosSettings.status_topic_qos.durability = int32(1);
            end
            
            % Set up only once for each action client object
            updateObjectQoS(obj, qosSettings);

            % Set object properties
            obj.ActionName = resolvedName;
            obj.ActionType = actionType;
            
            % Save the internal node information for later use
            obj.InternalNode = node.InternalNode;
            obj.ServerNodeHandle = node.ServerNodeHandle;
            obj.MaxConcurrentCallbacks = get(0, 'RecursionLimit');

            % Ensure there is no conflict action type
            h = ros.ros2.internal.Introspection;
            existedType = h.getTypeFromActionName([],resolvedName,node);
            if ~isempty(existedType) && ~strcmp(existedType,actionType)
                error(message('ros:mlros2:actionclient:ActionTypeNoMatch', ...
                              resolvedName, ...
                              existedType, ...
                              actionType));
            end

            % Initialize action client callback handler
            obj.ActClientCallbackHandler = ros.internal.ros2.ActClientCallbackHandler;
            obj.ActClientCallbackHandler.ActClientWeakHandle = matlab.internal.WeakHandle(obj);

            % Get action info
            obj.ActionInfo = ros.internal.ros2.getActionInfo(...
                            [actionType 'Goal'], ...
                            actionType, 'Goal', 'action');

            % Create the action client object
            createActClient(obj, resolvedName, qosSettings);
            % Initialize private storage structure
            obj.CancelAllGoalsResponse = struct.empty;
            obj.ActualCancelAllCallbackFcn = function_handle.empty;
            obj.CancelGoalsBeforeResponse = struct.empty;
            obj.ActualCancelBeforeCallbackFcn = function_handle.empty;
            obj.GoalInfoStruct = struct;
            obj.GoalHandleHistory = struct;
            obj.CallbackFcnDataStruct = struct;
            obj.GoalCancelFcnStruct = struct;
            obj.generateUniqueID;
            node.ListofNodeDependentHandles{end+1} = matlab.internal.WeakHandle(obj);

            % Return goal message structure if requested
            if nargout > 1
                varargout{1} = ros2message(obj);
            end
        end

        function delete(obj)
        %DELETE Shut down action client
        %   DELETE(CLIENT) shuts down the ROS 2 action client object CLIENT
        %   and removes its registration from the internal server. If the
        %   goal that was last sent to the action server is active, it is
        %   not cancelled.

            % Remove all callback function dependency
            obj.ActualCancelAllCallbackFcn = function_handle.empty;
            obj.CallbackFcnDataStruct = [];

            % Delete all ActionClientGoalHandle in workspace since they are
            % no longer valuable when action client get deleted
            if ~isempty(obj.GoalHandleHistory)
                fn = fieldnames(obj.GoalHandleHistory);
                for i=1:length(fn)
                    delete(obj.GoalHandleHistory.(fn{i}));
                end
                obj.GoalHandleHistory = [];
            end

            % Remove action client and clear internal node
            if ~isempty(obj.InternalNode) && ...
                    isvalid(obj.InternalNode) && ...
                    ~isempty(obj.ActClientHandle)
                try
                    removeActClient(obj.InternalNode, ...
                                    obj.ActClientHandle);
                catch
                    warning(message('ros:mlros2:actionclient:ShutdownError'));
                end
            end
            obj.InternalNode = [];
        end

        function goalMsg = ros2message(obj)
        %ROS2MESSAGE Create a new goal message based on action type
        %   GOALMSG = ROS2MESSAGE(CLIENT) creates and returns a new goal
        %   message GOALMSG. The message type of GOALMSG is determined by
        %   the action type associated with this action client.
        %
        %   Example:
        %      % Create a node and action client
        %      node = ros2node("/sensors");
        %      client = ros2actionclient(node,"/fibonacci","example_interfaces/Fibonacci");
        %
        %      % Create goal message
        %      goalMsg = ROS2MESSAGE(client);
        %
        %   See also SENDGOAL.

            goalMsg = ros2message([obj.ActionType 'Goal']);
        end

        function [status, statusText] = waitForServer(obj, varargin)
        %WAITFORSERVER Wait for action server to start and connect
        %   WAITFORSERVER(CLIENT) blocks MATLAB from running the current
        %   program until the action server is started up and available to
        %   receive goals. Press Ctrl+C to abort the wait.
        %
        %   WAITFORSERVER(___,Name=Value) provides additional options
        %   specified by one or more Name=Value pair arguments. You can
        %   specify several name-value pair arguments in any order as
        %   Name1=Value1,...,NameN=ValueN:
        %
        %       "Timeout" - Specifies a timeout period, in seconds. If the
        %                   server does not start up in the timeout period,
        %                   this function displays an error message and
        %                   lets MATLAB continue running the current
        %                   program. Otherwise, the default value is Inf,
        %                   which blocks MATLAB from running the current
        %                   program until the action server is available.
        %
        %   [STATUS,STAUSTEXT] = WAITFORSERVER(___) returns a STATUS 
        %   indicating whether the server is available. If the server is
        %   not available within the TIMEOUT, no error will be thrown 
        %   and STATUS will be false.
        %   The STATUSTEXT can be one of the following:
        %
        %       'success' - The server is ready to start and connect
        %       'input'   - The input to the function is invalid
        %       'timeout' - The server is not ready within the specified
        %                   timeout

        % Initialize status
            status = false;
            try
                % Parse input arguments
                [varargin{:}] = convertStringsToChars(varargin{:});
                parser = getWaitForServerParser(obj);
                parse(parser, varargin{:});
                timeout = parser.Results.Timeout;
            catch ex
                if nargout > 1
                    statusText = 'input';
                    return
                end
                rethrow(ex)
            end

            % Wait until server is ready to connect (or timeout occurs)

            if ~isempty(obj.InternalNode) && ...
                    isvalid(obj.InternalNode) && ...
                    ~isempty(obj.ActClientHandle)
                status = waitForActServer(obj.InternalNode, ...
                                          obj.ActClientHandle, ...
                                          timeout);

            end
            if status == false
                if nargout > 0
                    statusText = 'timeout';
                    return;
                end
                error(message('ros:mlros2:actionclient:WaitServerTimeout', ...
                    obj.ActionName, num2str(timeout, '%.2f')));
            end
            statusText = 'success';
        end

        function goalHandle = sendGoal(obj, goalMsg, varargin)
        %SENDGOAL Send goal message to action server
        %   GOALHANDLE = SENDGOAL(CLIENT,GOALMSG) sends a goal message,
        %   GOALMSG, to the action server. This goal is tracked by the
        %   action client. The function does not wait for the goal to be
        %   executed and returns a goal handle, GOALHANDLE, immediately.
        %
        %   GOALHANDLE = SENDGOAL(CLIENT,GOALMSG,CALLBACKFCNS) sends a goal
        %   message, GOALMSG, associated with customized GoalRespFcn,
        %   FeedbackFcn, and ResultFcn callback functions, to the action
        %   server. The function does not wait for the goal to be executed
        %   and returns a goal handle, GOALHANDLE, immediately.
        %
        %   See also ros2ActionSendGoalOptions.

        % Parse input arguments
            narginchk(2,3);
            validateattributes(goalMsg, {'struct'},{'scalar'}, ...
                               'sendGoal', 'goalMsg');

            % Callback structure returned from ros2ActionSendGoalOptions has
            % already been validated.
            callbackSet = ros2ActionSendGoalOptions;
            if nargin>2
                callbackSet = varargin{1};
            end

            % Ensure action server is availble
            if ~obj.IsServerConnected
                error(message('ros:mlros2:actionclient:SendGoalError', ...
                              obj.ActionName, obj.ActionType));
            end
            
            % Send goal to action server
            % If the GoalResponse callback executes first even before
            % the goalIndex reaches front end action client,issues may arise. 
            % To avoid this ,front end will pass down a unique goalIndex to the ROS2
            % backend instead of generating the goalIndex at the ROS2
            % backend.
            obj.GoalIndexInput = obj.GoalIndexInput + 1;

            goalIndex = sendGoalToActServer(obj.InternalNode, ...
                                            obj.ActClientHandle, ...
                                            obj.GoalIndexInput,goalMsg);
            if goalIndex ~= obj.GoalIndexInput
                error(message('ros:mlros2:actionclient:SendGoalError', ...
                              obj.ActionName, obj.ActionType));
            end
            obj.IsGoalReadyForAccess(end+1) = false; 
            % Assign callback functions and user data
            structName = obj.generateStructName(goalIndex, 'CallbackInfo');
            obj.writeToCallbackStruct(structName, callbackSet);
            goalHandle = ros.internal.ros2.ActionClientGoalHandle(...
                matlab.internal.WeakHandle(obj), ...
                goalIndex, ...
                callbackSet.FeedbackFcn, ...
                callbackSet.ResultFcn);
            handleStructName = obj.generateStructName(goalIndex, 'CallbackInfo');
            obj.GoalHandleHistory.(handleStructName) = goalHandle;
        end

        function cancelGoal(obj, goalHandle, varargin)
        %CANCELGOAL Cancel specific goal this client sent
        %   CANCELGOAL(CLIENT,GOALHANDLE) sends a cancel request for the
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

        % Parse input arguments    
            parser = getCancelGoalParser(obj);
            parse(parser, goalHandle, varargin{:});
            cancelFcn = parser.Results.CancelFcn;
            goalHandle = parser.Results.goalHandle;

            util = ros.internal.Util.getInstance;
            util.waitUntilTrue(@() obj.IsGoalReadyForAccess(goalHandle.GoalIndex),10);

            if ~isempty(goalHandle.GoalUUID)
                % Extract actual cancel function and user data
                [actualCancelFcn, actualCancelUserData] = ...
                    ros.internal.Parsing.validateFunctionHandle(...
                        cancelFcn, 'cancelGoal', 'CancelFcn');

                % Assign callback function and user data.
                % A CancelResponse field has also been created for saving
                % cancel response message when received.
                structName = obj.generateStructName(goalHandle.GoalIndex, 'GoalCancel');
                obj.GoalCancelFcnStruct.(structName).CancelFcn = actualCancelFcn;
                obj.GoalCancelFcnStruct.(structName).CancelUserData = actualCancelUserData;
                obj.GoalCancelFcnStruct.(structName).CancelResponse = struct.empty;
                
                % Return "res" as a boolean to indicate whether cancelGoal has
                % been delivered successfully.
                res = cancelGoal(obj.InternalNode, ...
                                 obj.ActClientHandle, ...
                                 goalHandle.GoalIndex);
                if ~res
                    error(message('ros:mlros2:actionclient:CancelGoalError', ...
                        obj.ActionName, obj.ActionType));
                end
            end
        end

        function [cancelResponse, status, statusText] = cancelGoalAndWait(obj, goalHandle, varargin)
        %CANCELGOALANDWAIT Cancel specific goal and wait for response
        %   CANCELRESPONSE = CANCELGOALANDWAIT(CLIENT,GOALHANDLE) sends a
        %   cancel request for the goal associated with the goal handle,
        %   GOALHANDLE, to the action server and blocks MATLAB from running
        %   the current program until the action server returns the cancel
        %   response, CANCELRESPONSE. Press Ctrl+C to abort the wait.
        %
        %   CANCELRESPONSE = CANCELGOALANDWAIT(___,Name=Value) provides 
        %   additional options specified by one or more Name=Value pair
        %   arguments. You can specify several name-value pair arguments in
        %   any order as Name1=Value1,...,NameN=ValueN:
        %
        %       "Timeout" - Specifies a timeout period, in seconds. If the
        %                   server does not return the cancel response in 
        %                   the timeout period, this function displays an 
        %                   error message and lets MATLAB continue running 
        %                   the current program. Otherwise, the default 
        %                   value is Inf, which blocks MATLAB from running 
        %                   the current program until the action server is 
        %                   available.
        %
        %   [CANCELRESPONSE,STATUS,STATUSTEXT] = CANCELGOALANDWAIT(___)
        %   returns the final receive status and the associated status text.
        %   The STATUS indicates if the cancel response has been received
        %   successfully or not and the associated STATUSTEXT will capture
        %   information about the status. The STATUSTEXT can be one of the
        %   following:
        %
        %       'success'      - The response was successfully received.
        %       'input'        - The input to the function is invalid.
        %       'timeout'      - The response was not received within the
        %                          specified timeout.
            
            % Default return status
            status = false;

            try
                % Parse input arguments
                [varargin{:}] = convertStringsToChars(varargin{:});
                parser = getCancelGoalAndWaitParser(obj);
                parse(parser, goalHandle, varargin{:});
                goalHandle = parser.Results.goalHandle;
                timeout = parser.Results.Timeout;
            catch ex
                if nargout > 1
                    statusText = 'input';
                    return
                end
                rethrow(ex)
            end
            
            % Pre-allocate cancel goal information in GoalCancelFcnStruct
            structName = obj.generateStructName(goalHandle.GoalIndex, 'GoalCancel');
            obj.GoalCancelFcnStruct.(structName).CancelFcn = function_handle.empty;
            obj.GoalCancelFcnStruct.(structName).CancelUserData = {};
            obj.GoalCancelFcnStruct.(structName).CancelResponse = struct.empty;

            % Sent cancel goal request
            try
                res = cancelGoal(obj.InternalNode, ...
                                 obj.ActClientHandle, ...
                                 goalHandle.GoalIndex);
                if ~res
                    error(message('ros:mlros2:actionclient:CancelGoalError', ...
                        obj.ActionName, obj.ActionType));
                end
                % Wait until cancel goal response is available
                structName = obj.generateStructName(goalHandle.GoalIndex, 'GoalCancel');
                util = ros.internal.Util.getInstance;
                util.waitUntilTrue(@() obj.checkCancelAvailable(structName), ...
                                   timeout);
                cancelResponse = obj.GoalCancelFcnStruct.(structName).CancelResponse;
            catch ex
                if nargout <= 1
                    if strcmp(ex.identifier, 'ros:mlros:util:WaitTimeout')
                        error(message('ros:mlros2:actionclient:WaitTimeout', ...
                            'cancelGoalAndWait', num2str(timeout, '%.2f')))
                    else
                        rethrow(ex)
                    end
                else
                    cancelResponse = ros2message('action_msgs/CancelGoalResponse');
                    statusText = 'timeout';
                    return;
                end
            end

            status = true;
            statusText = 'success';
        end

        function cancelAllGoals(obj, varargin)
        %CANCELALLGOALS Cancel all goals this client sent
        %   CANCELALLGOALS(CLIENT) sends a cancel request to action server
        %   to cancel all active goals sent from this action client. The
        %   function does not wait for goals to be cancelled and returns
        %   immediately.
        %
        %   CANCELALLGOALS(___,Name=Value) provides additional options
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
        %                       function cancelFcn(MSG, VARARGIN)
        %
        %                     You pass additional arguments to the callback
        %                     function by including both the callback
        %                     function and the arguments as elements of a
        %                     cell array when setting the property.

        % Parse input arguments    
            parser = getCancelAllGoalsParser(obj);
            parse(parser, varargin{:});
            cancelFcn = parser.Results.CancelFcn;

            % Assign callback function and user data.
            [actualCancelFcn, actualCancelUserData] = ...
                ros.internal.Parsing.validateFunctionHandle(...
                    cancelFcn, 'cancelAllGoals', 'CancelFcn');
            obj.ActualCancelAllCallbackFcn = actualCancelFcn;
            obj.ActualCancelAllUserData = actualCancelUserData;

            % Return "res" as a boolean to indicate whether cancelAllGoals
            % has been delivered successfully.
            res = cancelAllGoal(obj.InternalNode, ...
                                obj.ActClientHandle);

            if ~res
                error(message('ros:mlros2:actionclient:CancelGoalError', ...
                    obj.ActionName, obj.ActionType));
            end
        end

        function [cancelResponse, status, statusText] = cancelAllGoalsAndWait(obj, varargin)
        %CANCELALLGOALSANDWAIT Cancel all goals and wait for response
        %   CANCELRESPONSE = CANCELALLGOALSANDWAIT(CLIENT) send a cancel
        %   request to cancel all active goals sent from the action client,
        %   CLIENT, to the action server and blocks MATLAB from running
        %   the current program until the action server returns the cancel
        %   response, CANCELRESPONSE. Press Ctrl+C to abort the wait.
        %
        %   CANCELRESPONSE = CANCELALLGOALSANDWAIT(___,Name=Value) provides 
        %   additional options specified by one or more Name=Value pair
        %   arguments. You can specify several name-value pair arguments in
        %   any order as Name1=Value1,...,NameN=ValueN:
        %
        %       "Timeout" - Specifies a timeout period, in seconds. If the
        %                   server does not return the cancel response in 
        %                   the timeout period, this function displays an 
        %                   error message and lets MATLAB continue running 
        %                   the current program. Otherwise, the default 
        %                   value is Inf, which blocks MATLAB from running 
        %                   the current program until the action server is 
        %                   available.
        %
        %   [CANCELRESPONSE,STATUS,STATUSTEXT] = CANCELALLGOALSANDWAIT(___)
        %   returns the final receive status and the associated status text.
        %   The STATUS indicates if the cancel response has been received
        %   successfully or not and the associated STATUSTEXT will capture
        %   information about the status. The STATUSTEXT can be one of the
        %   following:
        %
        %       'success'      - The response was successfully received.
        %       'input'        - The input to the function is invalid.
        %       'timeout'      - The response was not received within the
        %                          specified timeout.

            % Default return status
            status = false;

            try
                % Parse input arguments
                [varargin{:}] = convertStringsToChars(varargin{:});
                parser = getCancelAllGoalsAndWaitParser(obj);
                parse(parser, varargin{:});
                timeout = parser.Results.Timeout;
            catch ex
                if nargout > 1
                    statusText = 'input';
                    return
                end
                rethrow(ex)
            end

            % Avoid affect from previous call. (g2892306)
            obj.ActualCancelAllCallbackFcn = function_handle.empty;
            obj.ActualCancelAllUserData = {};

            try
                % Return "res" as a boolean to indicate whether cancelAllGoals
                % has been delivered successfully.
                res = cancelAllGoal(obj.InternalNode, ...
                                    obj.ActClientHandle);
                if ~res
                    error(message('ros:mlros2:actionclient:CancelGoalError', ...
                        obj.ActionName, obj.ActionType));
                end
                util = ros.internal.Util.getInstance;
                util.waitUntilTrue(@() ~isempty(obj.CancelAllGoalsResponse), ...
                                   timeout);
                cancelResponse = obj.CancelAllGoalsResponse;
                % Reset to empty
                obj.CancelAllGoalsResponse = struct.empty;
            catch ex
                if nargout <= 1
                    if strcmp(ex.identifier, 'ros:mlros:util:WaitTimeout')
                        error(message('ros:mlros2:actionclient:WaitTimeout',...
                            'cancelAllGoalsAndWait', num2str(timeout, '%.2f')))
                    else
                        rethrow(ex)
                    end
                else
                    cancelResponse = ros2message('action_msgs/CancelGoalResponse');
                    statusText = 'timeout';
                    return;
                end
            end

            status = true;
            statusText = 'success';
        end

        function cancelGoalsBefore(obj, timestamp, varargin)
        %CANCELGOALSBEFORE Cancel all goals at or before a specified time 
        %   CANCELGOALSBEFORE(CLIENT,TIMESTAMP) send a cancel request to 
        %   action server to cancel all active goals sent from this action 
        %   client at or before a specified ros2time timestamp, TIMESTAMP. 
        %   The function does not wait for goals to be cancelled and 
        %   returns immediately.
        %
        %   CANCELGOALSBEFORE(___,Name=Value) provides additional options
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
        %                       function cancelFcn(MSG, VARARGIN)
        %
        %                     You pass additional arguments to the callback
        %                     function by including both the callback
        %                     function and the arguments as elements of a
        %                     cell array when setting the property.

        % Parse input arguments    
            parser = getCancelGoalsBeforeParser(obj);
            parse(parser, timestamp, varargin{:});
            timestamp = parser.Results.timestamp;
            cancelFcn = parser.Results.CancelFcn;

            % Ensure timestamp contains sec and nanosec
            if ~(isfield(timestamp, 'sec') && isfield(timestamp,'nanosec') ...
                    && isa(timestamp.sec, 'int32') && isa(timestamp.nanosec,'uint32'))
                error(message('ros:mlros2:actionclient:CancelGoalTimeError'));
            end

            % Assign callback function and user data.
            [actualCancelFcn, actualCancelUserData] = ...
                ros.internal.Parsing.validateFunctionHandle(...
                    cancelFcn, 'cancelGoalsBefore', 'CancelFcn');
            obj.ActualCancelBeforeCallbackFcn = actualCancelFcn;
            obj.ActualCancelBeforeUserData = actualCancelUserData;

            % Return "res" as a boolean to indicate whether
            % cancelGoalsBefore has been delivered successfully.
            res = cancelGoalsBeforeTime(obj.InternalNode, ...
                                        obj.ActClientHandle, ...
                                        timestamp.sec, ...
                                        timestamp.nanosec);

            if ~res
                error(message('ros:mlros2:actionclient:CancelGoalError', ...
                    obj.ActionName, obj.ActionType));
            end
        end

        function [cancelResponse, status, statusText] = cancelGoalsBeforeAndWait(obj, timestamp, varargin)
        %CANCELGOALSBEFOREANDWAIT Cancel all goals before timestamp and wait for response
        %   CANCELRESPONSE = CANCELGOALSBEFOREANDWAIT(CLIENT,TIMESTAMP) 
        %   send a cancel request to cancel all active goals sent from the 
        %   action client, CLIENT, to the action server before the 
        %   specified ros2time timestamp, TIMESTAMP, and blocks MATLAB from
        %   running the current program until the action server returns the
        %   cancel response, CANCELRESPONSE. Press Ctrl+C to abort the wait.
        %
        %   CANCELRESPONSE = CANCELALLGOALSANDWAIT(___,Name=Value) provides 
        %   additional options specified by one or more Name=Value pair
        %   arguments. You can specify several name-value pair arguments in
        %   any order as Name1=Value1,...,NameN=ValueN:
        %
        %       "Timeout" - Specifies a timeout period, in seconds. If the
        %                   server does not return the cancel response in 
        %                   the timeout period, this function displays an 
        %                   error message and lets MATLAB continue running 
        %                   the current program. Otherwise, the default 
        %                   value is Inf, which blocks MATLAB from running 
        %                   the current program until the action server is 
        %                   available.
        %
        %   [CANCELRESPONSE,STATUS,STATUSTEXT] = CANCELALLGOALSANDWAIT(___)
        %   returns the final receive status and the associated status text.
        %   The STATUS indicates if the cancel response has been received
        %   successfully or not and the associated STATUSTEXT will capture
        %   information about the status. The STATUSTEXT can be one of the
        %   following:
        %
        %       'success'      - The response was successfully received.
        %       'input'        - The input to the function is invalid.
        %       'timeout'      - The response was not received within the
        %                          specified timeout.

            % Default return status
            status = false;

            try
                % Parse input arguments
                [varargin{:}] = convertStringsToChars(varargin{:});
                parser = getCancelGoalsBeforeAndWaitParser(obj);
                parse(parser, timestamp, varargin{:});
                timestamp = parser.Results.timestamp;
                timeout = parser.Results.Timeout;

                % Ensure timestamp contains sec and nanosec
                if ~(isfield(timestamp, 'sec') && isfield(timestamp,'nanosec') ...
                        && isa(timestamp.sec, 'int32') && isa(timestamp.nanosec,'uint32'))
                    error(message('ros:mlros2:actionclient:CancelGoalTimeError'));
                end
            catch ex
                if nargout > 1
                    statusText = 'input';
                    return
                end
                rethrow(ex)
            end

            % Avoid affect from previous call. (g2892306)
            obj.ActualCancelBeforeCallbackFcn = function_handle.empty;
            obj.ActualCancelBeforeUserData = {};

            try
                % Return "res" as a boolean to indicate whether
                % cancelGoalsBefore has been delivered successfully.
                res = cancelGoalsBeforeTime(obj.InternalNode, ...
                                            obj.ActClientHandle, ...
                                            timestamp.sec, ...
                                            timestamp.nanosec);
                if ~res
                    error(message('ros:mlros2:actionclient:CancelGoalError', ...
                        obj.ActionName, obj.ActionType));
                end
                util = ros.internal.Util.getInstance;
                util.waitUntilTrue(@() ~isempty(obj.CancelGoalsBeforeResponse), ...
                                   timeout);
                cancelResponse = obj.CancelGoalsBeforeResponse;
                % Reset to empty
                obj.CancelGoalsBeforeResponse = struct.empty;
            catch ex
                if nargout <= 1
                    if strcmp(ex.identifier, 'ros:mlros:util:WaitTimeout')
                        error(message('ros:mlros2:actionclient:WaitTimeout',...
                            'cancelGoalsBeforeAndWait', num2str(timeout, '%.2f')))
                    else
                        rethrow(ex)
                    end
                else
                    cancelResponse = ros2message('action_msgs/CancelGoalResponse');
                    statusText = 'timeout';
                    return;
                end
            end

            status = true;
            statusText = 'success';
        end

        function status = getStatus(obj, goalHandle)
        %GETSTATUS Get status of specific goal this client sent
        %   STATUS = GETSTATUS(CLIENT,GOALHANDLE) returns an int8 status
        %   indicating current status of the goal corresponding to the 
        %   goal handle, GOALHANDLE. The goal must be sent from the
        %   specified action client, CLIENT. Otherwise, the default status
        %   0 (unknown) will be returned. Refer to this page for more
        %   information about goal status:
        %       https://docs.ros2.org/foxy/api/action_msgs/msg/GoalStatus.html

            validateattributes(goalHandle,...
                {'ros.internal.ros2.ActionClientGoalHandle'},...
                {'scalar'},'getStatus','goalHandle');
            if ~isequal(goalHandle.ActionClientHandle.get.ClientUniqueID, obj.ClientUniqueID) || ...
                isempty(goalHandle.GoalUUID)
                status = int8(0);
                return;
            end
            goalIndex = goalHandle.GoalIndex;
            status = getGoalInfo(obj, goalIndex, 'GoalStatus');
        end

        function [resultMsg, status, statusText] = getResult(obj, goalHandle, varargin)
        %GETRESULT Get result of specific goal this client sent
        %   RESULTMSG = GETRESULT(CLIENT,GOALHANDLE) blocks MATLAB from 
        %   running the current program until the result response message
        %   of the goal handle, GOALHANDLE, arrived. Press Ctrl+C to 
        %   abort the wait. The specified goal must be sent from this
        %   client, CLIENT. Otherwise, an error will be thrown.
        %
        %   RESULTMSG = GETRESULT(___,Name=Value) provides additional 
        %   options specified by one or more Name=Value pair arguments.
        %   You can specify several name-value pair arguments in any 
        %   order as Name1=Value1,...,NameN=ValueN:
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

        % Default return
            resultMsg = ros2message([obj.ActionType 'Result']);
            status = false;

            validateattributes(goalHandle,...
                {'ros.internal.ros2.ActionClientGoalHandle'},...
                {'scalar'},'getResult','goalHandle');

            try
                if ~isequal(goalHandle.ActionClientHandle.get.ClientUniqueID, obj.ClientUniqueID)
                    error(message('ros:mlros2:actionclient:HandleMismatchError'));
                end
                if isempty(goalHandle.GoalUUID)
                    error(message('ros:mlros2:actionclient:EmptyUUIDError'));
                end
                [varargin{:}] = convertStringsToChars(varargin{:});
                parser = getResultParser(obj);
                parse(parser, varargin{:});
                timeout = parser.Results.Timeout;
            catch ex
                if nargout > 1
                    statusText = 'input';
                    return
                end
                rethrow(ex)
            end

            % Get result message and code from action client
            try
                util = ros.internal.Util.getInstance;
                util.waitUntilTrue(@() ~isempty(obj.getGoalInfo(goalHandle.GoalIndex, 'ResultMsg')), ...
                                   timeout);
                resultMsg = obj.getGoalInfo(goalHandle.GoalIndex, 'ResultMsg');
                resultCode = obj.getGoalInfo(goalHandle.GoalIndex, 'ResultCode');
            catch ex
                if nargout <= 1
                    if strcmp(ex.identifier, 'ros:mlros:util:WaitTimeout')
                        error(message('ros:mlros2:actionclient:WaitTimeout', ...
                            'getResult', num2str(timeout, '%.2f')))
                    else
                        rethrow(ex)
                    end
                end
                % Return default result message
                statusText = 'timeout';
                return;
            end
            [status, statusText] = obj.getStatusFromCode(resultCode);
            statusText = convertStringsToChars(statusText);
        end
    end

    %% Custom Getters and Setters for Properties
    methods
        function isConnected = get.IsServerConnected(obj)
            res = isActServerConnected(obj.InternalNode,...
                                               obj.ActClientHandle);
            isConnected = res.isServerConnected;
        end

        function processGoalResponseCallback(obj, msg, info)
            % Get the timestamp when goal is been accepted
            timeStruct = getCurrentTime(obj.InternalNode, ...
                                        obj.ServerNodeHandle, ...
                                        false);
            timeStamp = ros2time(timeStruct.sec, timeStruct.nsec);
            obj.IsGoalReadyForAccess(msg.goalIndex) = true; 

            % Write goal response timestamp and UUID to GoalInfoStruct
            structName = obj.generateStructName(msg.goalIndex, 'GoalInfo');
            obj.createNewGoalInfo(structName);
            obj.GoalInfoStruct.(structName).GoalUUID = msg.goalUUID;
            obj.GoalInfoStruct.(structName).GoalUUIDInUint8 = msg.goalUUIDArray;
            obj.GoalInfoStruct.(structName).TimeStamp = timeStamp;

            % Return immediately if goalUUID is empty - rejected by server
            if isempty(msg.goalUUID)
                warning(message('ros:mlros2:actionclient:GoalRejected'));
                return;
            end

            % Run goal response callback function if it is not empty
            handleStructName = obj.generateStructName(msg.goalIndex, 'CallbackInfo');
            structName = obj.generateStructName(msg.goalIndex, 'CallbackInfo');
            if isequal(info.handle, obj.ActClientHandle) && ...
                    ~isempty(obj.CallbackFcnDataStruct.(structName).GoalRespFcn)
                feval(obj.CallbackFcnDataStruct.(structName).GoalRespFcn, ...
                      obj.GoalHandleHistory.(handleStructName), ...
                      obj.CallbackFcnDataStruct.(structName).GoalRespUserData{:});
            end
        end

        function processFeedbackCallback(obj, msg, info)
            % Run feedback callback function if it is not empty
            handleStructName = obj.generateStructName(msg.goalIndex, 'CallbackInfo');
            structName = obj.generateStructName(msg.goalIndex, 'CallbackInfo');
            if isequal(info.handle, obj.ActClientHandle) && ...
                    ~isempty(obj.CallbackFcnDataStruct.(structName).FeedbackFcn)
                feval(obj.CallbackFcnDataStruct.(structName).FeedbackFcn, ...
                      obj.GoalHandleHistory.(handleStructName), ...
                      msg.Feedback, ...
                      obj.CallbackFcnDataStruct.(structName).FeedbackUserData{:});
            end
        end

        function processResultCallback(obj, msg, info, ~)
            % Run result callback function if it is not empty
            handleStructName = obj.generateStructName(msg.goalIndex, 'CallbackInfo');
            structName = obj.generateStructName(msg.goalIndex, 'CallbackInfo');
            if isequal(info.handle, obj.ActClientHandle) && ...
                    ~isempty(obj.CallbackFcnDataStruct.(structName).ResultFcn)
                wrappedResult.result = msg.Result;
                wrappedResult.code = msg.resultStatus;
                wrappedResult.goalUUID = msg.goalUUID;

                feval(obj.CallbackFcnDataStruct.(structName).ResultFcn, ...
                      obj.GoalHandleHistory.(handleStructName), ...
                      wrappedResult, ...
                      obj.CallbackFcnDataStruct.(structName).ResultUserData{:});
            end

            % Write ResultMsg and ResultCode to GoalInfoStruct
            structName = obj.generateStructName(msg.goalIndex, 'GoalInfo');
            obj.GoalInfoStruct.(structName).ResultMsg = msg.Result;
            obj.GoalInfoStruct.(structName).ResultCode = msg.resultStatus;
        end

        function processCancelCallback(obj, msg, info)
            % Run cancel callback function if it is not empty
            handleStructName = obj.generateStructName(msg.goalIndex, 'CallbackInfo');
            structName = obj.generateStructName(msg.goalIndex, 'GoalCancel');
            if isequal(info.handle, obj.ActClientHandle) && ...
                    ~isempty(obj.GoalCancelFcnStruct.(structName).CancelFcn)
                feval(obj.GoalCancelFcnStruct.(structName).CancelFcn, ...
                      obj.GoalHandleHistory.(handleStructName), ...
                      msg.cancelResponse, ...
                      obj.GoalCancelFcnStruct.(structName).CancelUserData{:});
            end
            % Write cancel response to GoalCancelFcnStruct
            obj.GoalCancelFcnStruct.(structName).CancelResponse = msg.cancelResponse;
        end

        function processCancelAllCallback(obj, msg, info)
            % Run cancel all callback function if it is not empty
            if isequal(info.handle, obj.ActClientHandle) && ... 
                    ~isempty(obj.ActualCancelAllCallbackFcn)
                feval(obj.ActualCancelAllCallbackFcn, ...
                      msg, ...
                      obj.ActualCancelAllUserData{:});
            end
            % Update CancelAllGoalsResponse
            obj.CancelAllGoalsResponse = msg;
        end

        function processCancelBeforeCallbackFcn(obj, msg, info)
            % Run cancel before callback function if it is not empty
            if isequal(info.handle, obj.ActClientHandle) && ... 
                    ~isempty(obj.ActualCancelBeforeCallbackFcn)
                feval(obj.ActualCancelBeforeCallbackFcn, ...
                      msg, ...
                      obj.ActualCancelBeforeUserData{:});
            end
            % Update CancelGoalsBeforeResponse
            obj.CancelGoalsBeforeResponse = msg;
        end
    end

    methods (Hidden)
        function ret = getGoalInfo(obj, goalIndex, infoTag)
        %getGoalInfo Get goal information given goal index
        %   This function returns goal information based on given goal
        %   index and infoTag. Goal handle objects can use this function to
        %   access goal information with a ros2actionclient handle.

            util = ros.internal.Util.getInstance;
            util.waitUntilTrue(@() obj.IsGoalReadyForAccess(goalIndex),10);
            switch infoTag
                case 'GoalStatus'
                    res = getActState(obj.InternalNode, ...
                              obj.ActClientHandle, ...
                              goalIndex);
                    ret = int8(res.state);
                otherwise
                    structName = obj.generateStructName(goalIndex, 'GoalInfo');
                    ret = obj.GoalInfoStruct.(structName).(infoTag);
            end
        end
    end

    methods (Access = private)
        function updateObjectQoS(obj, qosSettings)
        %updateObjectQoS updates the QoS properties of the object
            obj.GoalServiceQoS = obj.getQoSString(qosSettings, 'goal_service_qos');
            obj.ResultServiceQoS = obj.getQoSString(qosSettings, 'result_service_qos');
            obj.CancelServiceQoS = obj.getQoSString(qosSettings, 'cancel_service_qos');
            obj.FeedbackTopicQoS = obj.getQoSString(qosSettings, 'feedback_topic_qos');
            obj.StatusTopicQoS = obj.getQoSString(qosSettings, 'status_topic_qos');
        end

        function createActClient(obj, actionName, qosConfig)
        %createActClient creates action client on ROS 2 network

            
            dependentPkgs = {'action_msgs', 'builtin_interfaces', 'unique_identifier_msgs'};
            dependentLibNameMap = containers.Map({'win64','maci64','maca64','glnxa64'}, ...
                                                 { ...
                                                     strcat(dependentPkgs,'.dll'), ...
                                                     strcat('libmw',dependentPkgs,'.dylib'),...
                                                     strcat('libmw',dependentPkgs,'.dylib'),...
                                                     strcat('libmw',dependentPkgs,'.so')...
                                                  });
            commonPaths = fullfile(matlabroot,'toolbox','ros','bin',computer('arch'),dependentLibNameMap(computer('arch')));

            % It is necessary to load the dll's of unique message types for
            % goal, feedback and result.
            dllPathGoal = ros.internal.utilities.getPathOfDependentDlls([obj.ActionType 'Goal'],'ros2');
            dllPathFeedback = ros.internal.utilities.getPathOfDependentDlls([obj.ActionType 'Feedback'],'ros2');
            dllPathResult = ros.internal.utilities.getPathOfDependentDlls([obj.ActionType 'Result'],'ros2');
            dllPaths = unique([commonPaths dllPathGoal dllPathFeedback dllPathResult]);
            
            onGoalResponseCallbackFcn = 'onGoalResponseCallbackFcn';
            onFeedbackReceivedCallbackFcn = 'onFeedbackReceivedCallbackFcn';
            onResultReceivedCallbackFcn = 'onResultReceivedCallbackFcn';
            onCancelCallbackFcn = 'onCancelCallbackFcn';
            onCancelAllCallbackFcn = 'onCancelAllCallbackFcn';
            onCancelBeforeCallbackFcn = 'onCancelBeforeCallbackFcn';

            try
                returnCall = addActClient(obj.InternalNode, ...
                                          obj.ServerNodeHandle, ...
                                          actionName, ...
                                          obj.ActionInfo.path, ...
                                          obj.ActionInfo.cppFactoryClass, ...
                                          onGoalResponseCallbackFcn, ...
                                          onFeedbackReceivedCallbackFcn, ...
                                          onResultReceivedCallbackFcn, ...
                                          onCancelCallbackFcn, ...
                                          onCancelAllCallbackFcn, ...
                                          onCancelBeforeCallbackFcn, ...
                                          dllPaths, ...
                                          qosConfig);
                if isempty(returnCall) || ~isstruct(returnCall)
                    error(message('ros:mlros2:node:InvalidReturnCallError'))
                elseif ~isfield(returnCall, 'handle') || ...
                        isempty(returnCall.handle) || ...
                        ~isfield(returnCall, 'actionName') || ...
                        isempty(returnCall.actionName)
                    error(message('ros:mlros2:node:InvalidReturnCallHandleError'))
                end
                obj.ActClientHandle = returnCall.handle;

                % Initialize callback
                initActClientCallback(obj.InternalNode, ...
                                      returnCall.handle, ...
                                      obj.ActClientCallbackHandler, ...
                                      obj.MaxConcurrentCallbacks);
                % No need to check reply - should error on failure
            catch ex
                % TODO: update error message tag
                newEx = MException(message('ros:mlros2:actionclient:CreateError', ...
                                           obj.ActionName, ...
                                           obj.ActionType));
                throw(newEx.addCause(ex));
            end
        end

        function [paramNameParser, paramStructParser, codegenParser] = getParsers(obj)
        %getParsers Setup parsers to parse QoS settings

            % Code generation related name value pairs are not required for
            % MATLAB interpretation.
            codegenParser = inputParser;
            addParameter(codegenParser, 'SendGoalOptions', @(x) ...
                         validateattributes(x, {'cell'}, ...
                                           {'nonempty'}, ...
                                           'ros2actionclient','SendGoalOptions'));
            addParameter(codegenParser, 'CancelFcn', @(x) ...
                         validateattributes(x, {'function_handle','cell'}, ...
                                           {'nonempty'}, ...
                                           'ros2actionclient','CancelFcn'));
            addParameter(codegenParser, 'CancelAllFcn', @(x) ...
                         validateattributes(x, {'function_handle','cell'}, ...
                                           {'nonempty'}, ...
                                           'ros2actionclient','CancelAllFcn'));
            addParameter(codegenParser, 'CancelBeforeFcn', @(x) ...
                         validateattributes(x, {'function_handle','cell'}, ...
                                           {'nonempty'}, ...
                                           'ros2actionclient','CancelBeforeFcn'));

            paramNameParser = inputParser;
            addParameter(paramNameParser,'GoalServiceQoS', struct, ...
                @(x) validateattributes(x, ...
                {'struct'}, ...
                {'nonempty','scalar'}, ...
                'ros2actionclient', ...
                'GoalServiceQoS'));
            addParameter(paramNameParser,'ResultServiceQoS', struct, ...
                @(x) validateattributes(x, ...
                {'struct'}, ...
                {'nonempty','scalar'}, ...
                'ros2actionclient', ...
                'ResultServiceQoS'));
            addParameter(paramNameParser,'CancelServiceQoS', struct, ...
                @(x) validateattributes(x, ...
                {'struct'}, ...
                {'nonempty','scalar'}, ...
                'ros2actionclient', ...
                'CancelServiceQoS'));
            addParameter(paramNameParser,'FeedbackTopicQoS', struct, ...
                @(x) validateattributes(x, ...
                {'struct'}, ...
                {'nonempty','scalar'}, ...
                'ros2actionclient', ...
                'FeedbackTopicQoS'));
            addParameter(paramNameParser,'StatusTopicQoS', struct, ...
                @(x) validateattributes(x, ...
                {'struct'}, ...
                {'nonempty','scalar'}, ...
                'ros2actionclient', ...
                'StatusTopicQoS'));

            paramStructParser = inputParser;
            paramStructParser = addQoSToParser(obj,paramStructParser,'ros2actionclient');
        end

        function structName = generateStructName(~, goalIndex, structPrefix)
        %generateStructName Generate structure field name based on goalIndex
        %   This function returns a structure field name by appending goal 
        %   index to a structPrefix.
            structName = [structPrefix num2str(goalIndex)];
        end

        function createNewGoalInfo(obj, structName)
        %createNewGoalInfo Creates a new goal information structure
        %   This function adds a new goal information structure containing
        %   'GoalUUID', 'TimeStamp', 'ResultMsg', and 'ResultCode' into the
        %   GoalInfoStruct.
            newInfo = struct('GoalUUID', uint8(0), ...
                             'TimeStamp', ros2time(0), ...
                             'ResultMsg', [], ...
                             'ResultCode', int8(0));
            obj.GoalInfoStruct.(structName) = newInfo;
        end

        function writeToCallbackStruct(obj, structName, callbackStruct)
        %writeToCallbackStruct Writes a new structure containing GoalRespFcn, 
        %   GoalRespUserData, FeedbackFcn, FeedbackUserData, ResultFcn, and
        %   ResultUserData into CallbackFcnDataStruct.
            obj.CallbackFcnDataStruct.(structName) = callbackStruct;
        end

        function cancelAvailable = checkCancelAvailable(obj, structName)
        %checkCancelAvailable check whether cancel response is available
            cancelAvailable = false;
            if ~isempty(obj.GoalCancelFcnStruct.(structName).CancelResponse)
                cancelAvailable = true;
            end
        end

        function generateUniqueID(obj)
            strOpts = ['A':'Z' 'a':'z'];
            obj.ClientUniqueID = strOpts(randi([1,52],1,8));
        end

        function [status, statusText] = getStatusFromCode(obj,resultCode)
            statusText = obj.CodeMap(resultCode);
            status = ~strcmp(statusText, 'timeout');
        end
    end

    methods (Access = ?matlab.unittest.TestCase)

        function parser = getConstructorParser(~)
        %getConstructorParser Set up parser for constructor inputs
        % Set up ordered inputs
            parser = inputParser;
            addRequired(parser, 'node', @(x) ...
                        validateattributes(x, {'ros2node'}, ...
                                           {'scalar'}, ...
                                           'ros2actionclient', 'node'));
            addRequired(parser, 'actionName', @(x) ...
                        validateattributes(x, {'char','string'}, ...
                                           {'scalartext','nonempty'}, ...
                                           'ros2actionclient', 'actionName'));
            addRequired(parser, 'actionType', @(x) ...
                        validateattributes(x, {'char','string'}, ...
                                           {'scalartext','nonempty'}, ...
                                           'ros2actionclient', 'actionType'));
        end

        function parser = getWaitForServerParser(obj)
        %getWaitForServerParser Set up parser for waitForServer inputs

            parser = inputParser;
            addParameter(parser, 'Timeout', obj.DefaultTimeout, ...
                         @(x) validateattributes(x, {'numeric'}, ...
                                                 {'scalar','nonempty','positive','nonnan'}, ...
                                                 'waitForServer', 'Timeout'));
        end

        function parser = getCancelGoalParser(obj)
        %getCancelGoalParser Set up parser for cancelGoal inputs

            parser = inputParser;
            addRequired(parser, 'goalHandle', @(x) ...
                        validateattributes(x, {'ros.internal.ros2.ActionClientGoalHandle'}, ...
                                           {'scalar'}, ...
                                           'cancelGoal','goalHandle'));
            addParameter(parser, 'CancelFcn', obj.DefaultCallbackFcn);
        end

        function parser = getCancelAllGoalsParser(obj)
        %getCancelAllGoalsParser Set up parser for cancelAllGoals inputs

            parser = inputParser;
            addParameter(parser, 'CancelFcn', obj.DefaultCallbackFcn);
        end

        function parser = getCancelGoalsBeforeParser(obj)
        %getCancelGoalsBeforeParser Set up parser for cancelGoalsBefore inputs

            parser = inputParser;
            addRequired(parser, 'timestamp', @(x) ...
                        validateattributes(x, {'struct'}, ...
                                           {'scalar'}, ...
                                           'cancelGoalsBefore','timestamp'));
            addParameter(parser, 'CancelFcn', obj.DefaultCallbackFcn);
        end

        function parser = getCancelGoalAndWaitParser(obj)
        %getCancelGoalAndWaitParser Set up parser for CancelGoalAndWait

            parser = inputParser;
            addRequired(parser, 'goalHandle', @(x) ...
                        validateattributes(x, {'ros.internal.ros2.ActionClientGoalHandle'}, ...
                                           {'scalar'}, ...
                                           'cancelGoalAndWait','goalHandle'));
            addParameter(parser, 'Timeout', obj.DefaultTimeout, ...
                         @(x) validateattributes(x, {'numeric'}, ...
                                                 {'scalar','nonempty','positive','nonnan'}, ...
                                                 'cancelGoalAndWait', 'Timeout'));
        end

        function parser = getCancelAllGoalsAndWaitParser(obj)
        %getCancelAllGoalsAndWaitParser Set up parser for CancelAllGoalsAndWait

            parser = inputParser;
            addParameter(parser, 'Timeout', obj.DefaultTimeout, ...
                         @(x) validateattributes(x, {'numeric'}, ...
                                                 {'scalar','nonempty','positive','nonnan'}, ...
                                                 'cancelAllGoalsAndWait', 'Timeout'));
        end

        function parser = getCancelGoalsBeforeAndWaitParser(obj)
        %getCancelGoalsBeforeAndWaitParser Set up parser for CancelGoalsBeforeAndWait

            parser = inputParser;
            addRequired(parser, 'timestamp', @(x) ...
                        validateattributes(x, {'struct'}, ...
                                           {'scalar'}, ...
                                           'cancelGoalsBeforeAndWait','timestamp'));
            addParameter(parser, 'Timeout', obj.DefaultTimeout, ...
                         @(x) validateattributes(x, {'numeric'}, ...
                                                 {'scalar','nonempty','positive','nonnan'}, ...
                                                 'cancelGoalsBeforeAndWait', 'Timeout'));
        end

        function parser = getResultParser(obj)
        %getResultParser Set up parser for getResult inputs

            parser = inputParser;
            addParameter(parser, 'Timeout', obj.DefaultTimeout, ...
                         @(x) validateattributes(x, {'numeric'}, ...
                                                 {'scalar','nonempty','positive','nonnan'}, ...
                                                 'getResult', 'Timeout'));
        end
    end

    methods (Static = true, Access = private)
        function name = matlabCodegenRedirect(~)
            name = 'ros.internal.codegen.ros2actionclient';
        end
    end
end
