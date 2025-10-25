classdef ros2actionserver < ros.ros2.internal.ActionQOSParser & ...
        ros.internal.mixin.InternalAccess & ...
        robotics.core.internal.mixin.Unsaveable & handle
    %

    %   Copyright 2023 The MathWorks, Inc.

    properties (SetAccess = private)
        %ActionName - Name of action associated with this server
        ActionName = ''

        %ActionType - Type of action associated with this server
        ActionType = ''

        %MultiGoalMode - Action mode of accepting multiple goal
        MultiGoalMode = 'on'
    end

    properties
        %ExecuteGoalFcn - Callback property for new goal execution
        ExecuteGoalFcn
        ReceiveGoalFcn
        CancelGoalFcn
    end

    properties(SetAccess = private)
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

    properties (Access = {?ros.internal.mixin.InternalAccess, ...
            ?matlab.unittest.TestCase})
        %GoalMessageType - The message type of the goal message
        GoalMessageType

        %FeedbackMessageType - The message type of the feedback message
        FeedbackMessageType

        %ResultMessageType - The message type of the result message
        ResultMessageType

        %ActualExecuteGoalFcn - Actual activation callback function after
        %parsing the user provided callback function and callback-data
        ActualExecuteGoalFcn
        ActualReceiveGoalFcn
        ActualCancelGoalFcn

        %ExecuteGoalFcnUserData - Callback-data provided by the user with
        %execute-goal callback function
        ExecuteGoalFcnUserData
        ReceiveGoalFcnUserData
        CancelGoalFcnUserData

        %Parser - Helper object for parsing tasks
        Parser
    end

    properties (Transient, Access = {?ros.internal.mixin.InternalAccess, ...
            ?matlab.unittest.TestCase})
        %ExecuteGoalCallbackHandler - Helper to handle callbacks
        ExecuteGoalCallbackHandler = []

        %InternalNode - Internal representation of the node object
        %   Node required to get property information
        InternalNode = []

        %ServerNodeHandle - Designation of the node on the server
        %   Node handle required to get property information
        ServerNodeHandle = []

        %ActionServerHandle - Designation of the action server on the server
        %This is required to get property information
        ActionServerHandle = []

        %ActionInfo - includes other information for a given action
        ActionInfo = struct.empty

        %MaxConcurrentCallbacks - Number of callbacks allowed in queue.
        %   The concurrent callbacks limits the number of callbacks allowed
        %   on the main MATLAB thread, and is set to the recursion limit
        %   upon construction by default
        MaxConcurrentCallbacks

        %LastGoalUUID
        LastGoalUUID = string.empty

        %GoalAcceptanceStatue
        GoalAcceptanceStatue = false
    end

    properties (Constant, Access = ?ros.internal.mixin.InternalAccess)
        % Goal status text to send back to client with corresponding method
        GoalStatusAborted = 'aborted'
        GoalStatusCanceled = 'canceled'
        GoalStatusSucceeded = 'succeeded'
        % Goal status enum to pass to backend function
        GoalStatusRejectEnum = int32(1)
        GoalStatusAcceptExecuteEnum = int32(2)
        GoalStatusAcceptDeferEnum = int32(3)
        CancelStatusEnum = int32(2)
    end

    methods
        function [obj, varargout] = ros2actionserver(node, actionName, actionType, varargin)

            % Parse the inputs to the constructor
            [actionName, actionType] = ...
                convertStringsToChars(actionName, actionType);
            [parser, qosStructParser] = getConstructorParser(obj);

            parse(parser, node, actionName, actionType, varargin{:});

            node = parser.Results.node;
            resolvedName = resolveName(node, parser.Results.actionName);
            actionType = parser.Results.actionType;

            % Parse QoS settings
            fs = fieldnames(parser.Results);
            qosFields = fs(contains(fs,'QoS'));
            qosInputs = cell.empty;
            % Length must be greater than 0
            qosLen = length(qosFields);
            for i = 1:qosLen
                parse(qosStructParser, parser.Results.(qosFields{i}));
                % Handle quality of service settings
                qosInputs{i} = getQosSettings(obj, qosStructParser.Results);
            end

            % Handle quality of service settings
            % qosInputs is organized by alphabetical order
            qosSettings = struct('goal_service_qos', qosInputs{3}, ...
                'result_service_qos', qosInputs{4}, ...
                'cancel_service_qos', qosInputs{1}, ...
                'feedback_topic_qos', qosInputs{2}, ...
                'status_topic_qos', qosInputs{5});
            
            % Default QoS Depth is 1, and default QoS Durability is
            % transientlocal for ROS 2 Action
            if ~isfield(qosSettings.status_topic_qos,'depth')
                qosSettings.status_topic_qos.depth = uint64(1);
            end
            if ~isfield(qosSettings.status_topic_qos,'durability')
                qosSettings.status_topic_qos.durability = int32(1);
            end

            % Set up only once for each action server object
            updateObjectQoS(obj, qosSettings);

            % Make sure that action type is valid
            % Note: action name will not be evaluate here. ROS 2 Action
            % allows multiple action servers with same name and type exist
            % at the same time. If one tries to create another server with 
            % same name but different type as an existed server, an error 
            % will be thrown from backend.
            actionTypes = ros.ros2.internal.Introspection.getAllActionTypesStatic;
            if ~ismember(actionType, actionTypes)
                error(message('ros:mlros2:actionserver:InvalidType', actionType));
            end

            % Set object properties
            obj.ActionName = resolvedName;
            obj.ActionType = actionType;
            obj.GoalMessageType = [actionType 'Goal'];
            obj.FeedbackMessageType = [actionType 'Feedback'];
            obj.ResultMessageType = [actionType 'Result'];
            obj.ExecuteGoalFcn = parser.Results.ExecuteGoalFcn;
            obj.ReceiveGoalFcn = parser.Results.ReceiveGoalFcn;
            obj.CancelGoalFcn = parser.Results.CancelGoalFcn;
            multiGoalMode = parser.Results.MultiGoalMode;
            obj.MultiGoalMode = convertStringsToChars(multiGoalMode);


            % Save the internal node information for later use
            obj.InternalNode = node.InternalNode;
            obj.ServerNodeHandle = node.ServerNodeHandle;
            obj.MaxConcurrentCallbacks = get(0,'RecursionLimit');

            % Ensure there is no conflict action type
            h = ros.ros2.internal.Introspection;
            existedType = h.getTypeFromActionName([],resolvedName,node);
            if ~isempty(existedType) && ~strcmp(existedType,actionType)
                error(message('ros:mlros2:actionserver:ActionTypeNoMatch', ...
                              resolvedName, ...
                              existedType, ...
                              actionType));
            end

            % Get action info
            obj.ActionInfo = ros.internal.ros2.getActionInfo(...
                                 obj.GoalMessageType, ...
                                 actionType, ...
                                 'Goal','action');

            % Create callback handler object
            obj.ExecuteGoalCallbackHandler = ...
                ros.internal.ros2.ActServerCallbackHandler;
            obj.ExecuteGoalCallbackHandler.ActServerWeakHandle = matlab.internal.WeakHandle(obj);

            % Create the action server object
            createActionServer(obj, resolvedName, qosSettings);

            node.ListofNodeDependentHandles{end+1} = matlab.internal.WeakHandle(obj);

            % Return result message structure if requested
            if nargout > 1
                varargout{1} = ros2message(obj);
            end
        end

        function delete(obj)

        % Cannot tell server to remove the action client without valid
        % internal node and server handle value
            if ~isempty(obj.InternalNode) && ...
                    isvalid(obj.InternalNode) && ...
                    ~isempty(obj.ActionServerHandle)
                try
                    removeActServer(obj.InternalNode, ...
                                    obj.ActionServerHandle);
                catch
                    warning(message('ros:mlros2:actionserver:ShutdownError'));
                end
            end
            obj.InternalNode = [];
        end

        function msg = ros2message(obj)

            msg = ros2message(obj.ResultMessageType);
        end

        function msg = getFeedbackMessage(obj)

            msg = ros2message(obj.FeedbackMessageType);
        end

        function set.ExecuteGoalFcn(obj, goalFcn)

        %   Make sure this is a valid function specifier
        %   Error if empty, as execute goal callback is required for action
        %   server to operate
            [fcnHandle, userData] = ...
                ros.internal.Parsing.validateFunctionHandle(goalFcn);

            % Set properties used when message is received
            obj.ActualExecuteGoalFcn = fcnHandle; %#ok<MCSUP>
            obj.ExecuteGoalFcnUserData = userData; %#ok<MCSUP>
            obj.ExecuteGoalFcn = goalFcn;
        end

        function set.ReceiveGoalFcn(obj, goalFcn)

            [fcnHandle, userData] = ...
                ros.internal.Parsing.validateFunctionHandle(goalFcn);
            obj.ActualReceiveGoalFcn = fcnHandle; %#ok<MCSUP>
            obj.ReceiveGoalFcnUserData = userData; %#ok<MCSUP>
            obj.ReceiveGoalFcn = goalFcn;
        end

        function set.CancelGoalFcn(obj, goalFcn)

            [fcnHandle, userData] = ...
                ros.internal.Parsing.validateFunctionHandle(goalFcn);
            obj.ActualCancelGoalFcn = fcnHandle; %#ok<MCSUP>
            obj.CancelGoalFcnUserData = userData; %#ok<MCSUP>
            obj.CancelGoalFcn = goalFcn;
        end

        function sendFeedback(obj, goalStruct, feedbackMsg)

            try
                % Send feedback over the network
                publishFeedback(obj.InternalNode, ...
                                obj.ActionServerHandle, ...
                                goalStruct.goalUUID, ...
                                feedbackMsg);
            catch ex
                % See if the issue is with the message structure
                validateInputMessage(obj, feedbackMsg, obj.FeedbackMessageType, 'sendFeedback');
                % See if the issue is with the goal structure
                if ~isfield(goalStruct, 'goal') || ~isfield(goalStruct, 'goalUUID')
                    error(message('ros:mlros2:actionserver:InvalidGoalStruct'));
                else
                    validateInputMessage(obj, goalStruct.goal, obj.GoalMessageType, 'sendFeedback');
                end
                % Otherwise, pass the error back through the callback
                rethrow(ex);
            end
        end

        function status = isPreemptRequested(obj, goalStruct)

            try
                % check preempt status
                responseStruct = isPreemptRequested(obj.InternalNode, ...
                                                    obj.ActionServerHandle, ...
                                                    goalStruct.goalUUID);
                status = responseStruct.isPreemptRequested;
            catch ex
                % See if the issue is with the goal structure
                if ~isfield(goalStruct, 'goal') || ~isfield(goalStruct, 'goalUUID')
                    error(message('ros:mlros2:actionserver:InvalidGoalStruct'));
                else
                    validateInputMessage(obj, goalStruct.goal, obj.GoalMessageType, 'isPreemptRequested');
                end
                % Otherwise, pass the error back through the callback
                rethrow(ex);
            end
        end

        function handleGoalResponse(obj,goalStruct,action)

            try
                validateattributes(action,{'char','string'}, ...
                             {'scalartext','nonempty'},'handleGoalResponse','action');
                if ~any(strcmpi(action,["REJECT","ACCEPT_AND_EXECUTE"]))
                    error(message('ros:mlros2:actionserver:InvalidGoalResponseAction',action));
                end
                action = convertStringsToChars(action);
    
                if strcmp(action,'REJECT')
                    updateGoalStatus(obj.InternalNode, obj.ActionServerHandle,goalStruct.goalUUID,obj.GoalStatusRejectEnum);
                else
                    % By default, ACCEPT_AND_EXECUTE
                    updateGoalStatus(obj.InternalNode, obj.ActionServerHandle,goalStruct.goalUUID,obj.GoalStatusAcceptExecuteEnum);
                end
                obj.GoalAcceptanceStatue = true;
            catch ex
                % See if the issue is with the goal structure
                if ~isfield(goalStruct, 'goal') || ~isfield(goalStruct, 'goalUUID')
                    error(message('ros:mlros2:actionserver:InvalidGoalStruct'));
                else
                    validateInputMessage(obj, goalStruct.goal, obj.GoalMessageType, 'handleGoalResponse');
                end
                % Otherwise, pass the error back through the callback
                rethrow(ex);
            end
        end
    end

    methods
        function processGoalReceivedCallback(obj, goalStruct, varargin)
        %processGoalReceivedCallback Take action when receving a new goal
            try
                feval(obj.ActualReceiveGoalFcn, ...
                      obj, ...
                      goalStruct, ...
                      obj.ReceiveGoalFcnUserData{:});
    
                if ~obj.GoalAcceptanceStatue
                    % By default, ACCEPT_AND_EXECUTE
                    updateGoalStatus(obj.InternalNode, obj.ActionServerHandle,goalStruct.goalUUID,obj.GoalStatusAcceptExecuteEnum);
                end
            catch ex
                % Reject goal if error happens
                updateGoalStatus(obj.InternalNode, obj.ActionServerHandle,goalStruct.goalUUID,obj.GoalStatusRejectEnum);
                obj.GoalAcceptanceStatue = false;
                rethrow(ex)
            end
        end

        function processGoalCancelCallback(obj, goalStruct)
        %processGoalCancelCallback Take action when receive a cancal request

            updateCancelStatus(obj,goalStruct);
            feval(obj.ActualCancelGoalFcn, ...
                  obj, ...
                  goalStruct, ...
                  obj.CancelGoalFcnUserData{:});
        end

        function processGoalAcceptedCallback(obj, goalStruct)
        %processGoalAcceptedCallback Take action based on goal from client to execute

            % If MultiGoalMode is set to 'off', only one goal is allowed at
            % a time. Abort previous goal
            if strcmp(obj.MultiGoalMode,'off') && ~isempty(obj.LastGoalUUID)
                % Abort last goal
                abortGoal(obj.InternalNode, ...
                          obj.ActionServerHandle, ...
                          obj.LastGoalUUID,...
                          obj.GoalStatusAborted, ...
                          ros2message(obj));
                obj.LastGoalUUID = string.empty;
                warning(message('ros:mlros2:actionserver:SingleModeAbortingWarn'));
            end

            updateGoalStatus(obj.InternalNode, ...
                             obj.ActionServerHandle, ...
                             goalStruct.goalUUID, ...
                             obj.GoalStatusAcceptExecuteEnum);
            obj.LastGoalUUID = goalStruct.goalUUID;

            % Default messages to pass to user's callback
            defaultFeedbackMsg = getFeedbackMessage(obj);
            defaultResultMsg = ros2message(obj);

            try
                % Call user-provided function to execute the goal
                %c1 = parallel.pool.Constant(obj);
                %c2 = obj.ActualExecuteGoalFcn;
                [resultMsg, success] = feval(...
                             obj.ActualExecuteGoalFcn, ...
                             obj, ...
                             goalStruct, ...
                             defaultFeedbackMsg, ...
                             defaultResultMsg, ...
                             obj.ExecuteGoalFcnUserData{:});
                %[resultMsg, success] = fetchOutputs(f);
            catch ex
                % Abort the goal if something goes wrong due to exception
                % or user mistake in callback
                resultMsg = defaultResultMsg;
                success = false;
                warning(message('ros:mlros2:actionserver:UserCallbackError', ex.message));
            end

            try
                % Send the result back over the network
                if success
                    succeedGoal(obj.InternalNode, ...
                                obj.ActionServerHandle, ...
                                goalStruct.goalUUID,...
                                obj.GoalStatusSucceeded, ...
                                resultMsg);
                elseif isPreemptRequested(obj,goalStruct)
                    preemptGoal(obj.InternalNode, ...
                                obj.ActionServerHandle, ...
                                goalStruct.goalUUID,...
                                obj.GoalStatusCanceled, ...
                                resultMsg);
                else
                    abortGoal(obj.InternalNode, ...
                              obj.ActionServerHandle, ...
                              goalStruct.goalUUID,...
                              obj.GoalStatusAborted, ...
                              resultMsg);
                end
            catch ex
                % Abort the goal if the result message cannot be sent
                % Use the default result message to avoid issues
                try
                    validateInputMessage(obj, resultMsg, obj.ResultMessageType, 'callback');
                catch ex
                    % Exception will be used in warning
                end
                warning(message('ros:mlros2:actionserver:SendResponseError', ex.message));
                abortGoal(obj.InternalNode, ...
                          obj.ActionServerHandle, ...
                          goalStruct.goalUUID,...
                          obj.GoalStatusAborted, ...
                          defaultResultMsg);
            end

            obj.LastGoalUUID = string.empty;
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

        function updateCancelStatus(obj,goalStruct)
            updateCancelStatus(obj.InternalNode, obj.ActionServerHandle,goalStruct.goalUUID,obj.CancelStatusEnum);
        end

        function createActionServer(obj, actionName, qosConfig)
        %createActionServer Establish action server on ROS network

        % Preemption will not require a callback
        % The user-provided callback should check if preemption occurred
            newGoalCallback = 'onHandleGoalReceivedCB';
            executeGoalCallback = 'onHandleGoalAcceptedCB';
            preemptGoalCallback = 'onHandleGoalCancelCB';

            % Paths for loading libraries
            dependentPkgs = {'action_msgs', 'builtin_interfaces', 'unique_identifier_msgs'};
            dependentLibNameMap = containers.Map({'win64','maci64','maca64','glnxa64'}, ...
                                                 { ...
                                                     strcat(dependentPkgs,'.dll'), ...
                                                     strcat('libmw',dependentPkgs,'.dylib'),...
                                                     strcat('libmw',dependentPkgs,'.dylib'),...
                                                     strcat('libmw',dependentPkgs,'.so')...
                                                  });
            commonPaths = fullfile(matlabroot,'toolbox','ros','bin',computer('arch'),dependentLibNameMap(computer('arch')));
            dllPathGoal = ros.internal.utilities.getPathOfDependentDlls([obj.ActionType 'Goal'], 'ros2');
            dllPathFeedback = ros.internal.utilities.getPathOfDependentDlls([obj.ActionType 'Feedback'],'ros2');
            dllPathResult = ros.internal.utilities.getPathOfDependentDlls([obj.ActionType 'Result'], 'ros2');
            dllPaths = unique([commonPaths dllPathGoal dllPathFeedback dllPathResult]);

            try
                returnCall = addActServer(obj.InternalNode, ...
                                          obj.ServerNodeHandle, ...
                                          actionName, ...
                                          obj.ActionInfo.path, ...
                                          obj.ActionInfo.cppFactoryClass, ...
                                          newGoalCallback, ...
                                          executeGoalCallback, ...
                                          preemptGoalCallback,...
                                          dllPaths, ...
                                          qosConfig);
                if isempty(returnCall) || ~isstruct(returnCall)
                    error(message('ros:mlros2:node:InvalidReturnCallError'));
                elseif ~isfield(returnCall, 'handle') || ...
                        isempty(returnCall.handle) || ...
                        ~isfield(returnCall, 'actionName') || ...
                        isempty(returnCall.actionName)
                    error(message('ros:mlros2:node:InvalidReturnCallHandleError'));
                end
                obj.ActionServerHandle = returnCall.handle;
                % Initialize callback to process goals
                initActServerCallback(obj.InternalNode, ...
                                      returnCall.handle, ...
                                      obj.ExecuteGoalCallbackHandler, ...
                                      obj.MaxConcurrentCallbacks);
                % No need to check reply - should error on failure
            catch ex
                newEx = MException(message('ros:mlros2:actionserver:CreateError', ...
                                            obj.ActionName, obj.ActionType));
                throw(newEx.addCause(ex));
            end
        end
    end

    methods (Access = ?matlab.unittest.TestCase)
        function [parser, qosStructParser] = getConstructorParser(obj)
        %getConstructorParser parser for ros2actionserver
        
            parser = inputParser;
            qosStructParser = inputParser;

            addRequired(parser, 'node', @(x) ...
                        validateattributes(x, {'ros2node'}, ...
                                           {'scalar','nonempty'}, ...
                                           'ros2actionserver', 'node'));
            addRequired(parser, 'actionName', @(x) ...
                        validateattributes(x,{'char','string'}, ...
                                           {'scalartext','nonempty'}, ...
                                           'ros2actionserver', 'actionName'));
            addRequired(parser, 'actionType', @(x) ...
                        validateattributes(x, {'char','string'}, ...
                                           {'scalartext','nonempty'}, ...
                                           'ros2actionserver', 'actionType'));
            addParameter(parser, 'ReceiveGoalFcn', @(~,~){});
            addParameter(parser, 'ExecuteGoalFcn', function_handle.empty);
            addParameter(parser, 'CancelGoalFcn', @(~,~){});
            addParameter(parser, 'MultiGoalMode', 'on', ...
                         @(x) ~isempty(validatestring(x, ...
                             {'on','off'},...
                             'ros2actionserver','MultiGoalMode')));

            % QoS parsing
            addParameter(parser, 'GoalServiceQoS', struct, ...
                @(x) validateattributes(x, ...
                {'struct'},{'scalar','nonempty'}, ...
                'ros2actionserver','GoalServiceQoS'));
            addParameter(parser,'ResultServiceQoS', struct, ...
                @(x) validateattributes(x, ...
                {'struct'}, {'nonempty','scalar'}, ...
                'ros2actionserver', ...
                'ResultServiceQoS'));
            addParameter(parser,'CancelServiceQoS', struct, ...
                @(x) validateattributes(x, ...
                {'struct'}, {'nonempty','scalar'}, ...
                'ros2actionserver', ...
                'CancelServiceQoS'));
            addParameter(parser,'FeedbackTopicQoS', struct, ...
                @(x) validateattributes(x, ...
                {'struct'}, {'nonempty','scalar'}, ...
                'ros2actionserver', ...
                'FeedbackTopicQoS'));
            addParameter(parser,'StatusTopicQoS', struct, ...
                @(x) validateattributes(x, ...
                {'struct'}, {'nonempty','scalar'}, ...
                'ros2actionserver', ...
                'StatusTopicQoS'));

            qosStructParser = addQoSToParser(obj,qosStructParser,'ros2actionserver');
        end

        function validateInputMessage(~, msg, msgType, fcnName)
        %validateInputMessage Do error checking on message type
        %   This is intended for use on user-provided messages within a
        %   try-catch block (as the validation may be too slow for checking
        %   the message under normal functionality).
        %   msgType may be a char array or cellstr of acceptable message
        %   type(s).

            validateattributes(msg, {'struct'},{'scalar'},fcnName, 'msg');
            if ~isfield(msg, 'MessageType') || ~any(strcmp(msg.MessageType, msgType))
                if iscell(msgType)
                    msgType = strjoin(msgType, ', ');
                end
                error(message('ros:mlros2:actionserver:InputTypeMismatch', msgType));
            end
        end
    end

    methods (Static = true, Access = private)
        function name = matlabCodegenRedirect(~)
            name = 'ros.internal.codegen.ros2actionserver';
        end
    end
end
