classdef ros2actionclient < ros.internal.mixin.InternalAccess & ...
        coder.ExternalDependency
%This class is for internal use only. It may be removed in the future.
%ros2actionclient Codegen implementation for ros2actionclient
%   See more information in ros2actionclient

%   Copyright 2022-2023 The MathWorks, Inc.
%#codegen

    properties (SetAccess = immutable)
        %ActionName - Name of action associated with this client
        ActionName
        %ActionType - Type of action associated with this client
        ActionType
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

    properties (Access = private)
        %GoalMsgStruct - Goal message in action client
        GoalMsgStruct
        %FeedbackMsgStruct - Feedback message in action client
        FeedbackMsgStruct
        %ResultMsgStruct - Result message in action client
        ResultMsgStruct
        %CancelRespMsgStruct - Cancel response message in action client
        CancelRespMsgStruct
        %IsInitialized - Identifier to determine whether action client has been initialized
        IsInitialized = false
        %CurrentGoalIndex - Index of current goal
        CurrentGoalIndex = int32(0)
        %SendGoalOptionMap - Cache to save send goal options
        SendGoalOptionMap = zeros(1,1000)'
        %ClientUniqueID - Unique ID to identify action client
        ClientUniqueID
        %runCancelFcn - Identifier to determine whether to run CancelFcn
        RunCancelFcn = false
        %RunCancelAllFcn - Identifier to determine whether to run CancelAllFcn
        RunCancelAllFcn = false
        %RunCancelBeforeFcn - Identifier to determine whether to run RunCancelBeforeFcn
        RunCancelBeforeFcn = false
    end

    properties
        %ActionClientHelperPtr - Pointer to MATLABROS2ActClient
        ActionClientHelperPtr
        %sendGoalOptsHandles - Registered send goal callback functions
        sendGoalOptsHandles
        %CancelFcn - Cancel goal callback function
        CancelFcn
        %CancelBeforeFcn - Cancel goals before callback function
        CancelBeforeFcn
        %CancelAllFcn - Cancel all goals callback function
        CancelAllFcn
        %CancelFcnArg - Optional argument for CancelFcn
        CancelFcnArg
        %CancelBeforeFcnArg - Optional argument for CancelBeforeFcn
        CancelBeforeFcnArg
        %CancelAllFcnArg - Optional argument for CancelAllFcn
        CancelAllFcnArg
    end

    properties (Constant, Access = private)
        %DefaultTimeout - The default timeout for server connection
        DefaultTimeout = Inf
    end

    methods
        function obj = ros2actionclient(node, actionName, actionType, varargin)
        %ros2actionclient Create a ROS 2 action client object
        %   Attach a new action client to the given ROS 2 node. The "name"
        %   and "type" arguments are required and specifies the action to
        %   which this client should connect. Please see the class
        %   documentation (help ros2actionclient) for more details.

        % Declare extrinsic functions
            coder.inline('never');
            coder.extrinsic('ros.codertarget.internal.getCodegenInfo');
            coder.extrinsic('ros.codertarget.internal.ROSMATLABCgenInfo');
            coder.extrinsic('ros.codertarget.internal.ROSMATLABCgenInfo.getInstance');
            coder.extrinsic('ros.codertarget.internal.getEmptyCodegenMsg');

            % Check number of input arguments
            coder.internal.narginchk(3,21,nargin);

            % Validate input ros2node
            validateattributes(node,{'ros2node'},{'scalar'}, ...
                               'ros2actionclient','node');
            % Action name and type
            actname = convertStringsToChars(actionName);
            validateattributes(actname, {'char'},{'nonempty'}, ...
                               'ros2actionclient','actionName');
            acttype = convertStringsToChars(actionType);
            validateattributes(acttype, {'char'},{'nonempty'}, ...
                               'ros2actionclient','actionType');
            % Write to property
            obj.ActionName = actname;
            obj.ActionType = acttype;

            % Parse NV pairs
            % This contains five customizable QoS settings and callback 
            % functions for action client
            nvPairs = struct('GoalServiceQoS',uint32(0),...
                'ResultServiceQoS',uint32(0),...
                'CancelServiceQoS',uint32(0),...
                'FeedbackTopicQoS',uint32(0),...
                'StatusTopicQoS',uint32(0),...
                'SendGoalOptions',uint32(0),...
                'CancelFcn',uint32(0),...
                'CancelAllFcn',uint32(0),...
                'CancelBeforeFcn',uint32(0));
            pOpts = struct('PartialMatching',true,'CaseSensitivity',false);
            pOuterStruct = coder.internal.parseParameterInputs(nvPairs,pOpts,varargin{:});
            goalServiceQoS = coder.internal.getParameterValue(pOuterStruct.GoalServiceQoS,struct,varargin{:});
            resultServiceQoS = coder.internal.getParameterValue(pOuterStruct.ResultServiceQoS,struct,varargin{:});
            cancelServiceQoS = coder.internal.getParameterValue(pOuterStruct.CancelServiceQoS,struct,varargin{:});
            feedbackTopicQoS = coder.internal.getParameterValue(pOuterStruct.FeedbackTopicQoS,struct,varargin{:});
            statusTopicQoS = coder.internal.getParameterValue(pOuterStruct.StatusTopicQoS,struct,varargin{:});
            sendGoalOptions = coder.internal.getParameterValue(pOuterStruct.SendGoalOptions,{},varargin{:});
            cancelFcn = coder.internal.getParameterValue(pOuterStruct.CancelFcn,{},varargin{:});
            cancelAllFcn = coder.internal.getParameterValue(pOuterStruct.CancelAllFcn,{},varargin{:});
            cancelBeforeFcn = coder.internal.getParameterValue(pOuterStruct.CancelBeforeFcn,{},varargin{:});

            % Parse sendGoalOptions
            if ~isempty(sendGoalOptions)
                validateattributes(sendGoalOptions,{'cell'},{'nonempty'},'ros2actionclient','SendGoalOptions');
                obj.sendGoalOptsHandles = sendGoalOptions;
            end

            % Parse cancelFcn, cancelAllFcn, cancelAfterFcn
            if ~isempty(cancelFcn)
                validateattributes(cancelFcn,{'function_handle','cell'},{'nonempty'},'ros2actionclient','CancelFcn');
                if isa(cancelFcn, 'function_handle')
                    obj.CancelFcn = cancelFcn;
                elseif iscell(cancelFcn)
                    obj.CancelFcn = cancelFcn{1};
                    obj.CancelFcnArg = cancelFcn{2:end};
                end
            end
            if ~isempty(cancelAllFcn)
                validateattributes(cancelAllFcn,{'function_handle','cell'},{'nonempty'},'ros2actionclient','CancelAllFcn');
                if isa(cancelAllFcn, 'function_handle')
                    obj.CancelAllFcn = cancelAllFcn;
                elseif iscell(cancelAllFcn)
                    obj.CancelAllFcn = cancelAllFcn{1};
                    obj.CancelAllFcnArg = cancelAllFcn{2:end};
                end
            end
            if ~isempty(cancelBeforeFcn)
                validateattributes(cancelBeforeFcn,{'function_handle','cell'},{'nonempty'},'ros2actionclient','CancelBeforeFcn');
                if isa(cancelBeforeFcn, 'function_handle')
                    obj.CancelBeforeFcn = cancelBeforeFcn;
                elseif iscell(cancelBeforeFcn)
                    obj.CancelBeforeFcn = cancelBeforeFcn{1};
                    obj.CancelBeforeFcnArg = cancelBeforeFcn{2:end};
                end
            end

            % Parse QoS settings
            validateattributes(goalServiceQoS,{'struct'},{'scalar','nonempty'},'ros2actionclient','GoalServiceQoS');
            validateattributes(resultServiceQoS,{'struct'},{'scalar','nonempty'},'ros2actionclient','ResultServiceQoS');
            validateattributes(cancelServiceQoS,{'struct'},{'scalar','nonempty'},'ros2actionclient','CancelServiceQoS');
            validateattributes(feedbackTopicQoS,{'struct'},{'scalar','nonempty'},'ros2actionclient','FeedbackTopicQoS');
            validateattributes(statusTopicQoS,{'struct'},{'scalar','nonempty'},'ros2actionclient','StatusTopicQoS');

            mProps = {'GoalServiceQoS', 'ResultServiceQoS', 'CancelServiceQoS', 'FeedbackTopicQoS', 'StatusTopicQoS'};
            nvPairsInner = struct('History',uint32(0),...
                'Depth',uint32(0),...
                'Reliability',uint32(0),...
                'Durability',uint32(0), ...
                'Deadline',double(0), ...
                'Lifespan',double(0), ...
                'Liveliness',uint32(0), ...
                'LeaseDuration',double(0), ...
                'AvoidROSNamespaceConventions',false);

            goalServiceQoSCpp = coder.opaque('rmw_qos_profile_t', ...
                'rmw_qos_profile_services_default', 'HeaderFile', 'rmw/qos_profiles.h');
            resultServiceQoSCpp = coder.opaque('rmw_qos_profile_t', ...
                'rmw_qos_profile_services_default', 'HeaderFile', 'rmw/qos_profiles.h');
            cancelServiceQoSCpp = coder.opaque('rmw_qos_profile_t', ...
                'rmw_qos_profile_services_default', 'HeaderFile', 'rmw/qos_profiles.h');
            feedbackTopicQoSCpp = coder.opaque('rmw_qos_profile_t', ...
                'rmw_qos_profile_default', 'HeaderFile', 'rmw/qos_profiles.h');
            statusTopicQoSCpp = coder.opaque('rmw_qos_profile_t', ...
                'rmw_qos_profile_default', 'HeaderFile', 'rmw/qos_profiles.h');

            fs = {goalServiceQoS,resultServiceQoS,cancelServiceQoS,feedbackTopicQoS,statusTopicQoS};
            qosProfilesCpp = {goalServiceQoSCpp, resultServiceQoSCpp, cancelServiceQoSCpp, feedbackTopicQoSCpp, statusTopicQoSCpp};
            % length must be greater than 0
            fslen = length(fs);
            for val = 1:fslen
                pInnerStruct = coder.internal.parseParameterInputs(nvPairsInner,pOpts,fs{val});
                if ~isfield(fs{val},'History')
                    qosHistory = 'keeplast';
                else
                    qosHistory = convertStringsToChars(coder.internal.getParameterValue(pInnerStruct.History,'keeplast',fs{val}));
                end
                validateStringParameter(qosHistory,{'keeplast', 'keepall'},'ros2actionclient','History');

                if ~isfield(fs{val},'Depth')
                    if val<5
                        qosDepth = 10;
                    else
                        % Default Depth for statusTopicQoS is 1
                        qosDepth = 1;
                    end
                else
                    qosDepth = coder.internal.getParameterValue(pInnerStruct.Depth,1,fs{val});
                end
                validateattributes(qosDepth,{'numeric'},...
                    {'scalar','nonempty','integer','nonnegative'},...
                    'ros2actionclient','Depth');

                if ~isfield(fs{val},'Reliability')
                    qosReliability = 'reliable';
                else
                    qosReliability = convertStringsToChars(coder.internal.getParameterValue(pInnerStruct.Reliability,'reliable',fs{val}));
                end
                validateStringParameter(qosReliability,{'reliable', 'besteffort'},'ros2actionclient','Reliability');

                if ~isfield(fs{val},'Durability')
                    if val<5
                        qosDurability = 'volatile';
                    else
                        qosDurability = 'transientlocal';
                    end
                else
                    qosDurability = convertStringsToChars(coder.internal.getParameterValue(pInnerStruct.Durability,'volatile',fs{val}));
                end
                validateStringParameter(qosDurability,{'transientlocal', 'volatile'},'ros2actionclient','Durability');

                if ~isfield(fs{val}, 'Deadline')
                    qosDeadline = 0;
                else
                    qosDeadline = coder.internal.getParameterValue(pInnerStruct.Deadline,0,fs{val});
                end
                if qosDeadline==Inf
                    qosDeadline=0;
                end
                validateattributes(qosDeadline,{'double'},{'scalar', 'nonnegative', 'nonnan'},'ros2actionclient','Deadline');

                if ~isfield(fs{val}, 'Lifespan')
                    qosLifespan = 0;
                else
                    qosLifespan = coder.internal.getParameterValue(pInnerStruct.Lifespan,0,fs{val});
                end
                if qosLifespan==Inf
                    qosLifespan=0;
                end
                validateattributes(qosLifespan,{'double'},{'scalar', 'nonnegative', 'nonnan'},'ros2actionclient','Lifespan');

                if ~isfield(fs{val},'Liveliness')
                    qosLiveliness = 'automatic';
                else
                    qosLiveliness = convertStringsToChars(coder.internal.getParameterValue(pInnerStruct.Liveliness,'automatic',fs{val}));
                end
                validateStringParameter(qosLiveliness,{'automatic','default','manual'},'ros2actionclient','Liveliness');

                if ~isfield(fs{val}, 'LeaseDuration')
                    qosLeaseDuration = 0;
                else
                    qosLeaseDuration = coder.internal.getParameterValue(pInnerStruct.LeaseDuration,0,fs{val});
                end
                if qosLeaseDuration==Inf
                    qosLeaseDuration=0;
                end
                validateattributes(qosLeaseDuration,{'double'},{'scalar', 'nonnegative', 'nonnan'},'ros2actionclient','LeaseDuration');

                if ~isfield(fs{val}, 'AvoidROSNamespaceConventions')
                    qosAvoidROSNamespaceConventions = false;
                else
                    qosAvoidROSNamespaceConventions = coder.internal.getParameterValue(pInnerStruct.AvoidROSNamespaceConventions,false,fs{val});
                end
                validateattributes(qosAvoidROSNamespaceConventions,{'logical'},{'nonempty'},'ros2actionclient','AvoidROSNamespaceConventions');

                qosProfilesCpp{val} = ros.ros2.internal.setQOSProfile(qosProfilesCpp{val}, ...
                    qosHistory, ...
                    qosDepth, ...
                    qosReliability, ...
                    qosDurability, ...
                    qosDeadline, ...
                    qosLifespan, ...
                    qosLiveliness, ...
                    qosLeaseDuration, ...
                    qosAvoidROSNamespaceConventions);

                % allocate qos settings fields for each qos property
                obj.(mProps{val}) = struct('History', qosHistory, 'Depth', qosDepth, 'Reliability', qosReliability, 'Durability', qosDurability, 'Deadline', qosDeadline, ...
                    'Lifespan', qosLifespan, 'Liveliness', qosLiveliness, 'LeaseDuration', qosLeaseDuration, 'AvoidROSNamespaceConventions', qosAvoidROSNamespaceConventions);
            end

            % Store input arguments
            obj.GoalServiceQoS = obj.(mProps{1});
            obj.ResultServiceQoS = obj.(mProps{2});
            obj.CancelServiceQoS = obj.(mProps{3});
            obj.FeedbackTopicQoS = obj.(mProps{4});
            obj.StatusTopicQoS = obj.(mProps{5});

            % Get and register code generation information
            cgGoalInfo = coder.const(@ros.codertarget.internal.getCodegenInfo, actname, [acttype 'Goal'], 'actclient', 'ros2');
            
            goalMsgStructGenFcn = str2func(cgGoalInfo.MsgStructGen);
            obj.GoalMsgStruct = goalMsgStructGenFcn();
            cgGoalInfo.ActionCppType;

            cgFeedbackInfo = coder.const(@ros.codertarget.internal.getCodegenInfo, actname, [acttype 'Feedback'], 'actclient', 'ros2');
            feedbackMsgStructGenFcn = str2func(cgFeedbackInfo.MsgStructGen);
            obj.FeedbackMsgStruct = feedbackMsgStructGenFcn();

            cgResultInfo = coder.const(@ros.codertarget.internal.getCodegenInfo, actname, [acttype 'Result'], 'actclient', 'ros2');
            resultMsgStructGenFcn = str2func(cgResultInfo.MsgStructGen);
            obj.ResultMsgStruct = resultMsgStructGenFcn();

            % This is required since cancel response is needed for
            % canceling goals
            cgRespInfo = coder.const(@ros.codertarget.internal.getCodegenInfo, actname, 'action_msgs/CancelGoalResponse', 'actclient', 'ros2');
            respMsgStructGenFcn = str2func(cgRespInfo.MsgStructGen);
            obj.CancelRespMsgStruct = respMsgStructGenFcn();

            % Create pointer to MATLABROS2ActClient object
            coder.ceval('auto goalStructPtr = ', coder.wref(obj.GoalMsgStruct));
            coder.ceval('auto feedbackStructPtr = ', coder.wref(obj.FeedbackMsgStruct));
            coder.ceval('auto resultStructPtr = ', coder.wref(obj.ResultMsgStruct));
            coder.ceval('auto cancelRespStructPtr = ', coder.wref(obj.CancelRespMsgStruct));

            TemplateTypeStr = ['MATLABROS2ActClient<',cgGoalInfo.ActionCppType,...
                               ',' cgGoalInfo.MsgClass ',' cgFeedbackInfo.MsgClass ',' cgResultInfo.MsgClass ',' cgRespInfo.MsgClass ...
                               ',' cgGoalInfo.MsgStructGen '_T,' cgFeedbackInfo.MsgStructGen '_T,' ...
                               cgResultInfo.MsgStructGen '_T,' cgRespInfo.MsgStructGen '_T>'];

            obj.ActionClientHelperPtr = coder.opaque(['std::unique_ptr<', TemplateTypeStr, '>'], 'HeaderFile', 'mlros2_actclient.h');
            if ros.internal.codegen.isCppPreserveClasses
                % Create SimpleActionClient by passing in class method as
                % callback
                obj.ActionClientHelperPtr = coder.ceval(...
                    ['std::unique_ptr<', TemplateTypeStr, ...
                    '>(new ', TemplateTypeStr, '([this](){this->goalResponseCallback();},[this](){this->feedbackCallback();},',...
                    '[this](){this->resultCallback();},[this](){this->cancelCallback();},',...
                    '[this](){this->cancelBeforeCallback();},[this](){this->cancelAllCallback();},', ...
                    'goalStructPtr,feedbackStructPtr,resultStructPtr, cancelRespStructPtr));//']);
            else
                % Create SimpleActionClient by passing in static function
                % as callback
                obj.ActionClientHelperPtr = coder.ceval( ...
                    ['std::unique_ptr<', TemplateTypeStr, ...
                    '>(new ', TemplateTypeStr, '([obj](){ros2actionclient_goalResponseCallback(obj);},[obj](){ros2actionclient_feedbackCallback(obj);},',...
                    '[obj](){ros2actionclient_resultCallback(obj);},[obj](){ros2actionclient_cancelCallback(obj);},',...
                    '[obj](){ros2actionclient_cancelBeforeCallback(obj),[obj](){ros2actionclient_cancelAllCallback(obj);},', ...
                    'goalStructPtr,feedbackStructPtr,resultStructPtr,cancelRespStructPtr);//']);
            end

            coder.ceval('MATLABROS2ActClient_createActClient',obj.ActionClientHelperPtr, ...
                node.NodeHandle, coder.rref(obj.ActionName), size(obj.ActionName, 2), ...
                qosProfilesCpp{1}, qosProfilesCpp{2}, qosProfilesCpp{3}, ...
                qosProfilesCpp{4}, qosProfilesCpp{5});

            % Ensure callback is not optimized away by making an explicit
            % call here
            obj.goalResponseCallback();
            obj.feedbackCallback();
            obj.resultCallback();
            obj.cancelCallback();
            obj.cancelBeforeCallback();
            obj.cancelAllCallback();
            obj.generateUniqueID();

            % Update IsInitialized so that callback functions will get
            % executed next time they get triggered.
            obj.IsInitialized = true;
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

        function varargout = waitForServer(obj, varargin)
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

            coder.inline('never');

            % Warning if no status output
            if nargout < 1
                coder.internal.compileWarning('ros:mlros2:codegen:MissingStatusOutput','waitForServer');
            end

            % Initialize status as false
            status = false;
            % Parse input arguments
            nvPairs = struct('Timeout', uint32(0));
            pOpts = struct('PartialMatching',true,'CaseSensitivity',false);
            pStruct = coder.internal.parseParameterInputs(nvPairs, pOpts, varargin{:});
            timeout = coder.internal.getParameterValue(pStruct.Timeout, ...
                obj.DefaultTimeout, varargin{:});

            % Runtime verification for input timeout, return right away if
            % user request output and the input timeout is invalid
            if timeout < 0 && nargout > 0
                statusText = 'input';
                varargout = {status, statusText};
                return;
            end
            % Validate timeout
            validateattributes(timeout, {'numeric'}, ...
                {'scalar','nonempty','positive','nonnan'},'waitForServer','Timeout');
            
            % Address syntax: waitForServer(client,Timeout=inf)
            % Since MATLAB Interpretation mode does not allow "0" as input
            % timeout, "0" will be passed to C++ class representing
            % infinite case.
            if isinf(timeout)
                timeout = 0;
            end

            timeoutMS = floor(timeout * 1000);
            coder.ceval('MATLABROS2ActClient_waitForServer', obj.ActionClientHelperPtr, ...
                timeoutMS, coder.ref(status));

            statusIndicator = status;
            if ~statusIndicator && nargout < 1
                % Throw runtime error if runtime error check is on 
                % Writing this separately to avoid optimizing away
                % statusText assignment when RunTimeCheck is off
                coder.internal.error('ros:mlros2:actionclient:WaitServerTimeout', obj.ActionName, sprintf('%.2f', double(timeout)));
            end

            if status
                % This can be reached since the value will be updated with
                % coder.ceval
                statusText = 'success'; %#ok<UNRCH>
            else
                statusText = 'timeout';
            end

            % Only return output if requested
            if nargout > 0
                varargout = {status, statusText};
            end
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

            coder.inline('never');
            narginchk(2,3);
            validateattributes(goalMsg, {'struct'}, {'scalar'}, ...
                               'sendGoal', 'goalMsg');
            % Set goal message in this object.
            obj.GoalMsgStruct = goalMsg;

            % Ensure the specified send goal option has been registered in
            % constructor. This helps to capture issues in early stage.
            callbackFound = false;
            if nargin > 2
                % Update SendGoalOptionMap table
                % First goal starts from index 0
                coder.unroll();
                for i=1:numel(obj.sendGoalOptsHandles)
                    if strcmp(obj.sendGoalOptsHandles{i}.OptionID, varargin{1}.OptionID)
                        % MATLAB indexing starts from 1
                        obj.SendGoalOptionMap(obj.CurrentGoalIndex+1) = i;
                        callbackFound = true;
                        break;
                    end
                end
            end
            
            if nargin > 2
                coder.internal.assert(callbackFound,'ros:mlros2:actionclient:UnknownCallback','sendGoal','SendGoalOptions','ros2actionclient');
            end

            % Call sendGoal in MATLABROS2ActClient to send the goal to
            % server.
            coder.ceval('MATLABROS2ActClient_sendGoal', obj.ActionClientHelperPtr);
            
            % Return an action client goal handle containing GoalUUID,
            % TimeStamp. This goal handle can be use as an inspection
            % utility to query information about the goal.
            goalHandleInfo = getGoalHandleInfo(obj, obj.CurrentGoalIndex);
            goalHandle = ros.internal.codegen.ActionClientGoalHandle(...
                obj, ...
                obj.CurrentGoalIndex, ...
                goalHandleInfo.GoalUUID, ...
                goalHandleInfo.TimeStamp);
            
            % Increase current goal index
            obj.CurrentGoalIndex = obj.CurrentGoalIndex + 1;
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

            goalIndex = goalHandle.GoalIndex;
            status = int8(0);
            if ~isequal(goalHandle.ActionClientHandle.ClientUniqueID, obj.ClientUniqueID) || ...
                isempty(goalHandle.GoalUUID)
                % return unknown if input goal was not sent from this
                % client
                return;
            end
            status = coder.ceval(...
                                 'MATLABROS2ActClient_getStatus', ...
                                 obj.ActionClientHelperPtr, ...
                                 goalIndex);
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

            coder.inline('never');

            % Warning if no status output
            if nargout < 2
                coder.internal.compileWarning('ros:mlros2:codegen:MissingStatusOutput','getResult');
            end

            % Default outputs
            resultMsg = ros2message([obj.ActionType 'Result']);
            status = false;

            % Parse timeout
            nvPairs = struct('Timeout',uint32(0));
            pOpts = struct('PartialMatching',true,'CaseSensitivity',false);
            pStruct = coder.internal.parseParameterInputs(nvPairs,pOpts,varargin{:});
            getResultTimeout = coder.internal.getParameterValue(pStruct.Timeout,inf,varargin{:});

            % Ensure the goal was sent from this client
            isGoalQualify = isequal(goalHandle.ActionClientHandle.ClientUniqueID, obj.ClientUniqueID) ...
                && ~isempty(goalHandle.GoalUUID);

            % Runtime verification for input
            if ((getResultTimeout < 0) || ~isGoalQualify) && (nargout > 1)
                statusText = 'input';
                return;
            end

            % Compile time error check
            validateattributes(goalHandle,...
                {'ros.internal.codegen.ActionClientGoalHandle'},...
                {'scalar'},'getResult','goalHandle');
            validateattributes(getResultTimeout,{'numeric'},...
                               {'scalar','nonempty','real','positive'},'getResult','Timeout');
            if ~isGoalQualify
                coder.internal.error('ros:mlros2:actionclient:HandleMismatchError');
            end

            % Address syntax: getResult(client,goalHandle,Timeout=inf)
            % Since MATLAB Interpretation mode does not allow "0" as input
            % timeout, "0" will be passed to C++ class representing
            % infinite case.
            if isinf(getResultTimeout)
                getResultTimeout = 0;
            end
            
            timeoutMS = floor(getResultTimeout * 1000);
            resultCode = int8(0);
            isTimeout = false;
            isTimeout = coder.ceval('MATLABROS2ActClient_getResult', ...
                            obj.ActionClientHelperPtr, ...
                            goalHandle.GoalIndex, ...
                            timeoutMS);
            if ~isTimeout
                resultMsg = obj.ResultMsgStruct;
                coder.ceval('MATLABROS2ActClient_getResultInfo', ...
                            obj.ActionClientHelperPtr, ...
                            goalHandle.GoalIndex, ...
                            coder.wref(resultCode));
                status = true;
                if isequal(resultCode,int8(4))
                    statusText = 'succeeded';
                elseif isequal(resultCode, int8(5))
                    statusText = 'canceled';
                elseif isequal(resultCode, int8(6))
                    statusText = 'aborted';
                else
                    statusText = 'unknown';
                end
            else
                % Timeout occurred
                statusText = 'timeout'; 
            end
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

            % Parse input name value pairs
            nvPairs = struct('CancelFcn', uint32(0));
            pOpts = struct('PartialMatching',true,'CaseSensitivity',false);
            pStruct = coder.internal.parseParameterInputs(nvPairs, pOpts, varargin{:});
            cancelFcn = coder.internal.getParameterValue(pStruct.CancelFcn, ...
                [], varargin{:});

            % Ensure cancel function callback has been registered in
            % constructor if there is one passed as input to this function.
            if ~isempty(cancelFcn)
                if isempty(obj.CancelFcn)
                    coder.internal.assert(false,'ros:mlros2:actionclient:UnknownCallback','cancelGoal','CancelFcn','ros2actionclient');
                end
                obj.RunCancelFcn = true;
            else
                obj.RunCancelFcn = false;
            end

            if ~isempty(goalHandle.GoalUUID)
                coder.ceval('MATLABROS2ActClient_cancelGoal', ...
                            obj.ActionClientHelperPtr, ...
                            goalHandle.GoalIndex);
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

            coder.inline('never');
            % Warning if no status output
            if nargout < 1
                coder.internal.compileWarning('ros:mlros2:codegen:MissingStatusOutput','cancelGoalAndWait');
            end

            % Default return status and cancel response message
            status = false;
            cancelResponse = ros2message('action_msgs/CancelGoalResponse');
            % Parse input name value pairs
            nvPairs = struct('Timeout', uint32(0));
            pOpts = struct('PartialMatching',true,'CaseSensitivity',false);
            pStruct = coder.internal.parseParameterInputs(nvPairs, pOpts, varargin{:});
            timeout = coder.internal.getParameterValue(pStruct.Timeout, ...
                obj.DefaultTimeout, varargin{:});
            % Runtime verification for input timeout, return right away if
            % user request output and the input timeout is invalid
            if timeout < 0 && nargout > 0
                statusText = 'input';
                return;
            end
            % Validate timeout
            validateattributes(timeout, {'numeric'}, ...
                {'scalar','real','positive'},'cancelGoalAndWait','Timeout');

            % Address syntax: cancelGoalAndWait(client,goalHandle,Timeout=inf)
            % Since MATLAB Interpretation mode does not allow "0" as input
            % timeout, "0" will be passed to C++ class representing
            % infinite case.
            if isinf(timeout)
                timeout = 0;
            end
            
            timeoutMS = floor(timeout * 1000);
            isTimeout = false;
            isTimeout = coder.ceval('MATLABROS2ActClient_cancelGoalAndWait', ...
                            obj.ActionClientHelperPtr, ...
                            goalHandle.GoalIndex, ...
                            timeoutMS);
            if ~isTimeout
                status = true;
                statusText = 'success';
                cancelResponse = obj.CancelRespMsgStruct;
            else
                % Timeout occurred
                statusText = 'timeout'; 
            end
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
        
            % Parse input name value pairs
            nvPairs = struct('CancelFcn', uint32(0));
            pOpts = struct('PartialMatching',true,'CaseSensitivity',false);
            pStruct = coder.internal.parseParameterInputs(nvPairs, pOpts, varargin{:});
            cancelAllFcn = coder.internal.getParameterValue(pStruct.CancelFcn, ...
                [], varargin{:});

            % Ensure cancel function callback has been registered in
            % constructor if there is one passed as input to this function.
            if ~isempty(cancelAllFcn)
                if isempty(obj.CancelAllFcn)
                    coder.internal.assert(false,'ros:mlros2:actionclient:UnknownCallback','cancelAllGoals','CancelAllFcn','ros2actionclient');
                end
                obj.RunCancelAllFcn = true;
            else
                obj.RunCancelAllFcn = false;
            end

            coder.ceval('MATLABROS2ActClient_cancelAllGoals', ...
                            obj.ActionClientHelperPtr);
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

            coder.inline('never');
            % Warning if no status output
            if nargout < 1
                coder.internal.compileWarning('ros:mlros2:codegen:MissingStatusOutput','cancelAllGoalsAndWait');
            end

            % Default return status and cancel response message
            status = false;
            cancelResponse = ros2message('action_msgs/CancelGoalResponse');
            % Parse input name value pairs
            nvPairs = struct('Timeout', uint32(0));
            pOpts = struct('PartialMatching',true,'CaseSensitivity',false);
            pStruct = coder.internal.parseParameterInputs(nvPairs, pOpts, varargin{:});
            timeout = coder.internal.getParameterValue(pStruct.Timeout, ...
                obj.DefaultTimeout, varargin{:});
            % Runtime verification for input timeout, return right away if
            % user request output and the input timeout is invalid
            if timeout < 0 && nargout > 0
                statusText = 'input';
                return;
            end
            % Validate timeout
            validateattributes(timeout, {'numeric'}, ...
                {'scalar','real','positive'},'cancelGoalAndWait','Timeout');

            % Address syntax: cancelGoalAndWait(client,goalHandle,Timeout=inf)
            % Since MATLAB Interpretation mode does not allow "0" as input
            % timeout, "0" will be passed to C++ class representing
            % infinite case.
            if isinf(timeout)
                timeout = 0;
            end
            
            timeoutMS = floor(timeout * 1000);
            isTimeout = false;
            isTimeout = coder.ceval('MATLABROS2ActClient_cancelAllGoalsAndWait', ...
                            obj.ActionClientHelperPtr, ...
                            timeoutMS);
            if ~isTimeout
                status = true;
                statusText = 'success';
                cancelResponse = obj.CancelRespMsgStruct;
            else
                % Timeout occurred
                statusText = 'timeout'; 
            end
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

            % Ensure timestamp contains sec and nanosec
            if ~(isfield(timestamp, 'sec') && isfield(timestamp,'nanosec') ...
                    && isa(timestamp.sec, 'int32') && isa(timestamp.nanosec,'uint32'))
                coder.internal.assert(false,'ros:mlros2:actionclient:CancelGoalTimeError');
            end
            % Parse input name value pairs
            nvPairs = struct('CancelFcn', uint32(0));
            pOpts = struct('PartialMatching',true,'CaseSensitivity',false);
            pStruct = coder.internal.parseParameterInputs(nvPairs, pOpts, varargin{:});
            cancelBeforeFcn = coder.internal.getParameterValue(pStruct.CancelFcn, ...
                [], varargin{:});

            % Ensure cancel function callback has been registered in
            % constructor if there is one passed as input to this function.
            if ~isempty(cancelBeforeFcn)
                if isempty(obj.CancelBeforeFcn)
                    coder.internal.assert(false,'ros:mlros2:actionclient:UnknownCallback','cancelGoalsBefore','CancelBeforeFcn','ros2actionclient');
                end
                obj.RunCancelBeforeFcn = true;
            else
                obj.RunCancelBeforeFcn = false;
            end

            coder.ceval('MATLABROS2ActClient_cancelGoalsBefore', ...
                            obj.ActionClientHelperPtr, ...
                            timestamp.sec,...
                            timestamp.nanosec);
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

            coder.inline('never');
            
            % Warning if no status output
            if nargout < 1
                coder.internal.compileWarning('ros:mlros2:codegen:MissingStatusOutput','cancelGoalAndWait');
            end

            % Ensure timestamp contains sec and nanosec
            if ~(isfield(timestamp, 'sec') && isfield(timestamp,'nanosec') ...
                    && isa(timestamp.sec, 'int32') && isa(timestamp.nanosec,'uint32'))
                coder.internal.assert(false,'ros:mlros2:actionclient:CancelGoalTimeError');
            end

            % Default return status and cancel response message
            status = false;
            cancelResponse = ros2message('action_msgs/CancelGoalResponse');
            % Parse input name value pairs
            nvPairs = struct('Timeout', uint32(0));
            pOpts = struct('PartialMatching',true,'CaseSensitivity',false);
            pStruct = coder.internal.parseParameterInputs(nvPairs, pOpts, varargin{:});
            timeout = coder.internal.getParameterValue(pStruct.Timeout, ...
                obj.DefaultTimeout, varargin{:});
            % Runtime verification for input timeout, return right away if
            % user request output and the input timeout is invalid
            if timeout < 0 && nargout > 0
                statusText = 'input';
                return;
            end
            % Validate timeout
            validateattributes(timeout, {'numeric'}, ...
                {'scalar','real','positive'},'cancelGoalAndWait','Timeout');

            % Address syntax: cancelGoalAndWait(client,goalHandle,Timeout=inf)
            % Since MATLAB Interpretation mode does not allow "0" as input
            % timeout, "0" will be passed to C++ class representing
            % infinite case.
            if isinf(timeout)
                timeout = 0;
            end
            
            timeoutMS = floor(timeout * 1000);
            isTimeout = false;
            isTimeout = coder.ceval('MATLABROS2ActClient_cancelGoalsBeforeAndWait', ...
                            obj.ActionClientHelperPtr, ...
                            timestamp.sec,...
                            timestamp.nanosec, ...
                            timeoutMS);
            if ~isTimeout
                status = true;
                statusText = 'success';
                cancelResponse = obj.CancelRespMsgStruct;
            else
                % Timeout occurred
                statusText = 'timeout'; 
            end
        end

        function isConnected = get.IsServerConnected(obj)
        %getter function to return property IsServerConnected
            isConnected = false;
            isConnected = coder.ceval('MATLABROS2ActClient_isServerConnected', ...
                                       obj.ActionClientHelperPtr);
        end


        %% Callback functions
        function goalResponseCallback(obj)
        %GOALRESPONSECALLBACK Goal response callback function
            coder.inline('never');
            ros.internal.codegen.doNotOptimizeROS2(obj.ActionClientHelperPtr);
            goalIndex = int32(0);
            goalIndex = coder.ceval('MATLABROS2ActClient_getGoalIndex', obj.ActionClientHelperPtr);
            % MATLAB indexing starts from 1
            sendGoalOptIndex = obj.SendGoalOptionMap(goalIndex+1);

            if obj.IsInitialized && sendGoalOptIndex>0
                goalHandle = getGoalHandleInfo(obj, goalIndex);
                coder.unroll();
                for idex = 1:numel(obj.sendGoalOptsHandles)
                    if idex == sendGoalOptIndex
                        obj.sendGoalOptsHandles{idex}.GoalRespFcn(goalHandle);
                    end
                end
            end
        end

        function feedbackCallback(obj)
        %FEEDBACKCALLBACK Feedback callback function
            coder.inline('never');
            ros.internal.codegen.doNotOptimizeROS2(obj.FeedbackMsgStruct);
            goalIndex = int32(0);
            goalIndex = coder.ceval('MATLABROS2ActClient_getGoalIndex', obj.ActionClientHelperPtr);
            % MATLAB indexing starts from 1
            sendGoalOptIndex = obj.SendGoalOptionMap(goalIndex+1);

            if obj.IsInitialized && sendGoalOptIndex>0
                goalHandle = getGoalHandleInfo(obj, goalIndex);
                coder.unroll();
                for idex = 1:numel(obj.sendGoalOptsHandles)
                    if idex == sendGoalOptIndex
                        obj.sendGoalOptsHandles{idex}.FeedbackFcn(...
                            goalHandle, ...
                            obj.FeedbackMsgStruct);
                    end
                end
            end
        end

        function resultCallback(obj)
            coder.inline('never');
            ros.internal.codegen.doNotOptimizeROS2(obj.ResultMsgStruct);
            goalIndex = int32(0);
            goalIndex = coder.ceval('MATLABROS2ActClient_getGoalIndex', obj.ActionClientHelperPtr);
            % MATLAB indexing starts from 1
            sendGoalOptIndex = obj.SendGoalOptionMap(goalIndex+1);

            if obj.IsInitialized && sendGoalOptIndex>0
                goalHandle = getGoalHandleInfo(obj, goalIndex);
                % Get result code
                isResultReady = false;
                while ~isResultReady
                    isResultReady = coder.ceval('MATLABROS2ActClient_isResultReady', ...
                                                obj.ActionClientHelperPtr, ...
                                                goalIndex);
                    pause(0.1);
                end
                resultCode = int8(0);
                coder.ceval('MATLABROS2ActClient_getResultInfo', ...
                            obj.ActionClientHelperPtr, ...
                            goalIndex, ...
                            coder.wref(resultCode));
                wrappedResult = struct('result',obj.ResultMsgStruct,...
                                       'code',resultCode,...
                                       'goalUUID',goalHandle.GoalUUID);
                coder.unroll();
                for idex = 1:numel(obj.sendGoalOptsHandles)
                    if idex == sendGoalOptIndex
                        obj.sendGoalOptsHandles{idex}.ResultFcn(...
                            goalHandle, ...
                            wrappedResult);
                    end
                end
            end
        end

        function cancelCallback(obj)
            coder.inline('never');
            ros.internal.codegen.doNotOptimizeROS2(obj.RunCancelFcn);
            goalIndex = int32(0);
            goalIndex = coder.ceval('MATLABROS2ActClient_getCurrentCancelGoalIndex', ...
                                    obj.ActionClientHelperPtr);
            if obj.IsInitialized && obj.RunCancelFcn && ~isempty(obj.CancelFcn)
                goalHandle = getGoalHandleInfo(obj, goalIndex);
                if isempty(obj.CancelFcnArg)
                    obj.CancelFcn(goalHandle, ...
                                  obj.CancelRespMsgStruct);
                else
                    obj.CancelFcn(goalHandle, ...
                                  obj.CancelRespMsgStruct, ...
                                  obj.CancelFcnArg);
                end
            end
        end

        function cancelBeforeCallback(obj)
            coder.inline('never');
            ros.internal.codegen.doNotOptimizeROS2(obj.RunCancelBeforeFcn);
            if obj.IsInitialized && obj.RunCancelBeforeFcn && ~isempty(obj.CancelBeforeFcn)
                if isempty(obj.CancelBeforeFcnArg)
                    obj.CancelBeforeFcn(obj.CancelRespMsgStruct);
                else
                    obj.CancelBeforeFcn(obj.CancelRespMsgStruct, ...
                                        obj.CancelBeforeFcnArg);
                end
            end
        end

        function cancelAllCallback(obj)
            coder.inline('never');
            ros.internal.codegen.doNotOptimizeROS2(obj.RunCancelAllFcn);
            if obj.IsInitialized && obj.RunCancelAllFcn && ~isempty(obj.CancelAllFcn)
                if isempty(obj.CancelAllFcnArg)
                    obj.CancelAllFcn(obj.CancelRespMsgStruct);
                else
                    obj.CancelAllFcn(obj.CancelRespMsgStruct, ...
                                     obj.CancelAllFcnArg);
                end
            end
        end
    end

    methods (Access = private)
        function localGoalHandle = getGoalHandleInfo(obj, goalIndex)
            coder.inline('never');
            goalUUID = char(zeros(1,16));
            timestampSec = int32(0);
            timestampNanosec = uint32(0);
            isGoalUUIDValid = false;

            coder.ceval('MATLABROS2ActClient_getGoalInfo', ...
                        obj.ActionClientHelperPtr, ...
                        goalIndex, ...
                        coder.wref(goalUUID), ...
                        coder.wref(timestampSec), ...
                        coder.wref(timestampNanosec), ...
                        coder.wref(isGoalUUIDValid));
            timestampMsg = ros2message('builtin_interfaces/Time');
            timestampMsg.sec = timestampSec;
            timestampMsg.nanosec = timestampNanosec;
            if isGoalUUIDValid
                localGoalHandle = struct('GoalUUID',goalUUID,'TimeStamp',timestampMsg); %#ok<UNRCH>
            else
                localGoalHandle = struct('GoalUUID','','TimeStamp',timestampMsg);
            end
        end

        function generateUniqueID(obj)
            strOpts = ['A':'Z' 'a':'z'];
            obj.ClientUniqueID = strOpts(randi([1,52],1,8));
        end
    end


    methods (Static)
        function props = matlabCodegenNontunableProperties(~)
            props = {'ActionType'};
        end

        function ret = getDescriptiveName(~)
            ret = 'ROS 2 ActClient';
        end

        function ret = isSupportedContext(bldCtx)
            ret = bldCtx.isCodeGenTarget('rtw');
        end

        function updateBuildInfo(buildInfo, bldCtx)
            if bldCtx.isCodeGenTarget('rtw')
                srcFolder = ros.slros.internal.cgen.Constants.PredefinedCode.Location;
                addIncludeFiles(buildInfo,'mlros2_actclient.h',srcFolder);
                addIncludeFiles(buildInfo,'mlros2_qos.h',srcFolder);
            end
        end
    end

    methods (Static, Access = ?ros.internal.mixin.ROSInternalAccess)
        function props = getImmutableProps()
            props = {'ActionName','ActionType'};
        end
    end
end
function validateStringParameter(value, options, funcName, varName)
% Separate function to suppress output and just validate
    validatestring(value, options, funcName, varName);
end