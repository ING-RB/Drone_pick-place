classdef SendActionGoal < ros.slros2.internal.block.ROS2SendActionGoalBase & ...
        ros.internal.mixin.InternalAccess
    %This class is for internal use only. It may be removed in the future.

    %SendActionGoal send an action goal over a ROS 2 network to action server
    %
    %   H = ros.slros2.internal.block.SendActionGoal creates a system
    %   object, H, that sends a goal message available at Goal input
    %   port to an action server on the ROS 2 network and outputs the goal
    %   UUID message of type unique_identifier_msgs/UUID. The output message
    %   contains unique id for each goal that is sent to an action server.
    %
    %   A new goal message will be sent under two conditions:
    %   1. If there is no outstanding goal with the "Enable port" set to true.
    %   2. If there is an outstanding goal with the "Enable port" set to true,
    %      but it is in a terminal state.
    %
    %   This system object is intended for use with the MATLAB System
    %   block. In order to access the ROS 2 functionality from MATLAB, see
    %   ROS2ACTIONCLIENT.
    %
    %   See also ros2actionclient.

    %   Copyright 2023-2024 The MathWorks, Inc.

    %#codegen

    % The following should ideally not show up in the MATLAB System block
    % dialog. However, setting them as 'Hidden' will prevent them from
    % being accessible via set_param & get_param
    properties (Constant,Access=private)
        % MessageCatalogName - Name of this block used in message catalogs
        MessageCatelogName = message("ros:slros2:blockmask:SendActionGoalMaskTitle").getString
    end

    properties(Nontunable)
        %ActionType Type of the action
        ActionType = 'example_interfaces/Fibonacci'

        %OutputROSMessageType Type of the ROS 2 message for goal uuid
        OutputROSMessageType = 'unique_identifier_msgs/UUID'

        %SLUUIDOutputBusName - Simulink Bus Name for output (goal uuid)
        SLUUIDOutputBusName = 'SL_Bus_unique_identifier_msgs_UUID'
    end

    properties (Access=private, Transient)
        % pActClient - Handle to object that implements ros2actionclient
        pActClient = []

        % pGoalHandle - Goal handle for outstanding goal that contains UUID
        pGoalHandle = []

        % CallbackOpts - Callback options used when sending a goal
        CallbackOpts = []

        % OutputConverter - Handle to object that encapsulates converting a
        % Simulink bus struct to a MATLAB ROS 2 message. It is initialized to
        % indicate the class of the object
        OutputConverter = ros.slros2.internal.sim.ROSMsgToBusStructConverter.empty
    end

    properties (Access = protected)
        % GoalInputConversionFcn Conversion function for input message
        GoalInputConversionFcn

        % EmptySeedGoalInputMsg Empty Seed Input ROS2 Message
        EmptySeedGoalInputMsg

        % EmptySeedUUIDOutputMsg Empty Seed Output ROS2 Message
        EmptySeedUUIDOutputMsg
    end

    methods
        function obj = SendActionGoal(varargin)
            % Enable code to be generated even if this file is p-coded
            coder.allowpcode('plain');
            obj = obj@ros.slros2.internal.block.ROS2SendActionGoalBase(varargin{:});
        end

        function set.ActionType(obj, val)
            validateattributes(val, {'char'}, {'nonempty'}, '', 'ActionType');
            if coder.target('MATLAB')
                ros.internal.Namespace.canonicalizeName(val); % throws error
            end
            obj.ActionType = val;
        end
    end

    methods (Access = protected)
        %% Common functions
        function num = getNumInputsImpl(~)
            num = 3;
        end

        function num = getNumOutputsImpl(~)
            num = 2;
        end

        function varargout = getOutputSizeImpl(~)
            varargout = {[1 1], [1 1]};
        end

        function varargout = isOutputFixedSizeImpl(~)
            varargout =  {true, true};
        end

        function varargout = getOutputDataTypeImpl(obj)
            varargout =  {obj.SLUUIDOutputBusName, 'uint8'};
        end

        function varargout = isOutputComplexImpl(~)
            varargout = {false, false};
        end
    end

    methods (Access = protected, Static)
        function header = getHeaderImpl
            % Define header panel for System block dialog
            header = matlab.system.display.Header(mfilename("class"), ...
                                                  'ShowSourceLink', false, ...
                                                  'Title', message('ros:slros2:blockmask:SendActionGoalMaskTitle').getString, ...
                                                  'Text', message('ros:slros2:blockmask:SendActionGoalDescription').getString);
        end

        function throwSimStateError()
            coder.internal.errorIf(true, 'ros:slros:sysobj:BlockSimStateNotSupported', 'ROS 2 Send Action Goal');
        end
    end

    methods (Access = protected)
        function sts = getSampleTimeImpl(obj)
        % Enable this system object to inherit constant ('inf') sample
        % times
            sts = createSampleTime(obj,'Type','Inherited','Allow','Constant');
        end

        function setupImpl(obj)
            % setupImpl is called when model is being initialized at the
            % start of a simulation

            GoalServiceQoS=struct('History',obj.qosReg(obj.GoalServiceQoSHistory), ...
                'Depth',obj.GoalServiceQoSDepth,...
                'Reliability',obj.qosReg(obj.GoalServiceQoSReliability), ...
                'Durability',obj.qosReg(obj.GoalServiceQoSDurability), ...
                'Deadline',obj.GoalServiceQoSDeadline, ...
                'Lifespan',obj.GoalServiceQoSLifespan, ...
                'Liveliness',obj.qosReg(obj.GoalServiceQoSLiveliness), ...
                'LeaseDuration',obj.GoalServiceQoSLeaseDuration, ...
                'AvoidROSNamespaceConventions',logical(obj.GoalServiceQoSAvoidROSNamespaceConventions));
            ResultServiceQoS=struct('History',obj.qosReg(obj.ResultServiceQoSHistory), ...
                'Depth',obj.ResultServiceQoSDepth,...
                'Reliability',obj.qosReg(obj.ResultServiceQoSReliability), ...
                'Durability',obj.qosReg(obj.ResultServiceQoSDurability), ...
                'Deadline',obj.ResultServiceQoSDeadline, ...
                'Lifespan',obj.ResultServiceQoSLifespan, ...
                'Liveliness',obj.qosReg(obj.ResultServiceQoSLiveliness), ...
                'LeaseDuration',obj.ResultServiceQoSLeaseDuration, ...
                'AvoidROSNamespaceConventions',logical(obj.ResultServiceQoSAvoidROSNamespaceConventions));
            CancelServiceQoS=struct('History',obj.qosReg(obj.CancelServiceQoSHistory), ...
                'Depth',obj.CancelServiceQoSDepth,...
                'Reliability',obj.qosReg(obj.CancelServiceQoSReliability), ...
                'Durability',obj.qosReg(obj.CancelServiceQoSDurability), ...
                'Deadline',obj.CancelServiceQoSDeadline, ...
                'Lifespan',obj.CancelServiceQoSLifespan, ...
                'Liveliness',obj.qosReg(obj.CancelServiceQoSLiveliness), ...
                'LeaseDuration',obj.CancelServiceQoSLeaseDuration, ...
                'AvoidROSNamespaceConventions',logical(obj.CancelServiceQoSAvoidROSNamespaceConventions));
            FeedbackTopicQoS=struct('History',obj.qosReg(obj.FeedbackTopicQoSHistory), ...
                'Depth',obj.FeedbackTopicQoSDepth,...
                'Reliability',obj.qosReg(obj.FeedbackTopicQoSReliability), ...
                'Durability',obj.qosReg(obj.FeedbackTopicQoSDurability), ...
                'Deadline',obj.FeedbackTopicQoSDeadline, ...
                'Lifespan',obj.FeedbackTopicQoSLifespan, ...
                'Liveliness',obj.qosReg(obj.FeedbackTopicQoSLiveliness), ...
                'LeaseDuration',obj.FeedbackTopicQoSLeaseDuration, ...
                'AvoidROSNamespaceConventions',logical(obj.FeedbackTopicQoSAvoidROSNamespaceConventions));
            StatusTopicQoS=struct('History',obj.qosReg(obj.StatusTopicQoSHistory), ...
                'Depth',obj.StatusTopicQoSDepth,...
                'Reliability',obj.qosReg(obj.StatusTopicQoSReliability), ...
                'Durability',obj.qosReg(obj.StatusTopicQoSDurability), ...
                'Deadline',obj.StatusTopicQoSDeadline, ...
                'Lifespan',obj.StatusTopicQoSLifespan, ...
                'Liveliness',obj.qosReg(obj.StatusTopicQoSLiveliness), ...
                'LeaseDuration',obj.StatusTopicQoSLeaseDuration, ...
                'AvoidROSNamespaceConventions',logical(obj.StatusTopicQoSAvoidROSNamespaceConventions));

            if coder.target('MATLAB')
                % Only run simulation setup if it is not in code generation
                % process
                isCodegen = ros.codertarget.internal.isCodegen;
                if ~isCodegen
                    % Executing in MATLAB interpreted mode
                    modelState = ros.slros.internal.sim.ModelStateManager.getState(obj.ModelName, 'create');
                    % The following could be a separate method, but system
                    % object infrastructure doesn't appear to allow it.
                    % If the node context goes into bad state, recreate the node.
                    if isempty(modelState.ROSNode) || ~isValidNode(modelState.ROSNode)
                        uniqueName = obj.makeUniqueName(obj.ModelName);
                        modelState.ROSNode = ros2node(uniqueName, ...
                                                  ros.ros2.internal.NetworkIntrospection.getDomainIDForSimulink, ...
                                                  'RMWImplementation', ...
                                                  ros.ros2.internal.NetworkIntrospection.getRMWImplementationForSimulink);
                    end

                    % Create ros2actionclient object based on user provided
                    % action name, type and qos settings
                    obj.pActClient = ros2actionclient(modelState.ROSNode, obj.ActionName, obj.ActionType, ...
                        GoalServiceQoS, ResultServiceQoS, CancelServiceQoS, FeedbackTopicQoS, StatusTopicQoS);

                    % Increase node reference count
                    modelState.incrNodeRefCount();

                    % Setup message to bus conversion
                    obj.OutputConverter = ros.slros2.internal.sim.ROSMsgToBusStructConverter(...
                        obj.OutputROSMessageType, obj.ModelName);
                    obj.EmptySeedUUIDOutputMsg = ros.slros2.internal.bus.Util.newMessageFromSimulinkMsgType(obj.OutputROSMessageType);
                    obj.EmptySeedOutputBusStruct = obj.OutputConverter.convert(obj.EmptySeedUUIDOutputMsg);
                    obj.EmptySeedGoalInputMsg = ros.slros2.internal.bus.Util.newMessageFromSimulinkMsgType([obj.ActionType 'Goal']);
                    [emptyGoalUUIDMsg,info]= ros.internal.getEmptyMessage(obj.OutputROSMessageType,'ros2');
                    [emptyGoalInputMsg,goalInputMsgInfo]= ros.internal.getEmptyMessage([obj.ActionType 'Goal'],'ros2');

                    cachedMap = containers.Map();
                    % This map contains the values of empty message data which
                    % can be reused when required.
                    refCachedMapInStoragePath = fullfile(pwd, '+bus_conv_fcns','+ros2','+busToMsg','RefCachedMap.mat');
                    refCachedMapIn = ros.slros.internal.bus.Util.getDataFromCacheFile(refCachedMapInStoragePath);
                    refCachedMapOutStoragePath = fullfile(pwd, '+bus_conv_fcns','+ros2','+msgToBus','RefCachedMap.mat');
                    refCachedMapOut = ros.slros.internal.bus.Util.getDataFromCacheFile(refCachedMapOutStoragePath);
                    cachedMap(obj.OutputROSMessageType) = emptyGoalUUIDMsg;
                    cachedMap([obj.ActionType 'Goal']) = emptyGoalInputMsg;

                    [pkgNameIn,goalMsgNameIn] = fileparts([obj.ActionType 'Goal']);
                    obj.GoalInputConversionFcn = generateStaticConversionFunctions(obj,emptyGoalInputMsg,...
                        goalInputMsgInfo,'ros2','busToMsg',pkgNameIn,goalMsgNameIn,cachedMap,refCachedMapIn,refCachedMapInStoragePath);
                    [pkgNameOut,msgNameOut] = fileparts(obj.OutputROSMessageType);
                    obj.OutputConversionFcn = generateStaticConversionFunctions(obj,emptyGoalUUIDMsg,...
                        info,'ros2','msgToBus',pkgNameOut,msgNameOut,cachedMap,refCachedMapOut,refCachedMapOutStoragePath);

                    % Create optional callback functions only once in
                    % block initialization
                    obj.CallbackOpts = ros2ActionSendGoalOptions(FeedbackFcn=@executeFeedbackCb);
                end
            elseif coder.target('RtwForRapid')
                % Rapid Accelerator. In this mode, coder.target('Rtw')
                % returns true as well, so it is important to check for
                % 'RtwForRapid' before checking for 'Rtw'
                coder.internal.errorIf(true, 'ros:slros2:codegen:RapidAccelNotSupported', 'ROS2 Send Action Goal');
            elseif coder.target('Rtw')
                % Code generation
                coder.cinclude(obj.ROS2NodeConst.CommonHeader);
                % Append 0 to obj.ActionName, since MATLAB doesn't
                % automatically zero-terminate strings in generated code
                zeroDelimAction = [obj.ActionName 0]; % null-terminated topic name

                goalServiceQoSCpp = coder.opaque('rmw_qos_profile_t', ...
                    'rmw_qos_profile_default', 'HeaderFile', 'rmw/qos_profiles.h');
                resultServiceQoSCpp = coder.opaque('rmw_qos_profile_t', ...
                    'rmw_qos_profile_default', 'HeaderFile', 'rmw/qos_profiles.h');
                cancelServiceQoSCpp = coder.opaque('rmw_qos_profile_t', ...
                    'rmw_qos_profile_default', 'HeaderFile', 'rmw/qos_profiles.h');
                feedbackTopicQoSCpp = coder.opaque('rmw_qos_profile_t', ...
                    'rmw_qos_profile_default', 'HeaderFile', 'rmw/qos_profiles.h');
                statusTopicQoSCpp = coder.opaque('rmw_qos_profile_t', ...
                    'rmw_qos_profile_default', 'HeaderFile', 'rmw/qos_profiles.h');

                mProps = {GoalServiceQoS, ResultServiceQoS, CancelServiceQoS, FeedbackTopicQoS, StatusTopicQoS};
                qosProfilesCpp = {goalServiceQoSCpp, resultServiceQoSCpp, cancelServiceQoSCpp, feedbackTopicQoSCpp, statusTopicQoSCpp};
                for val = 1:5
                    obj.setQOSProfile(qosProfilesCpp{val}, mProps{val}.History, mProps{val}.Depth, ...
                        mProps{val}.Reliability, mProps{val}.Durability, ...
                        mProps{val}.Deadline, mProps{val}.Lifespan, ...
                        mProps{val}.Liveliness, mProps{val}.LeaseDuration, ...
                        mProps{val}.AvoidROSNamespaceConventions);
                end

                coder.ceval([obj.BlockId, '.createActionClient'], ...
                    zeroDelimAction, qosProfilesCpp{1}, qosProfilesCpp{2}, ...
                    qosProfilesCpp{3}, qosProfilesCpp{4}, qosProfilesCpp{5});
            elseif  coder.target('Sfun')
                % 'Sfun'  - Simulation through CodeGen target
                % Do nothing. MATLAB System block first does a pre-codegen
                % compile with 'Sfun' target, & then does the "proper"
                % codegen compile with Rtw or RtwForRapid, as appropriate.
            else
                % 'RtwForSim' - ModelReference SIM target
                % 'MEX', 'HDL', 'Custom' - Not applicable to MATLAB System block
                coder.internal.errorIf(true, 'ros:slros:sysobj:UnsupportedCodegenMode', coder.target);
            end

            function executeFeedbackCb(goalHandle,feedback)
                % Feedback Callback function to store the latest feedback message
                % in the LatestInfoMapForFeedbackCB for specific goal handle
                goalHandle.LatestInfoMapForFeedbackCB('FeedbackFcn') = feedback;
            end
        end

        function [UUIDMsg, errorCode] = stepImpl(obj, inputbusstruct, enablesignal, outputbusstruct)
            % stepImpl - Send an Action Goal Message and output goal UUID
            % message. Buses are treated as structures

            errorCode = uint8(ros.slros.internal.block.SendGoalErrorCode.SLSendGoalSuccess);
            if coder.target('MATLAB')
                UUIDMsg = outputbusstruct; %return empty bus if ErrorCode ~= 0
                isCodegen = ros.codertarget.internal.isCodegen;
                if ~isCodegen
                    % Execute in interpreted mode
                    if ~obj.pActClient.IsServerConnected
                        % Show ErrorCode if action server is not available
                        % Show UUID output as default message
                        errorCode = uint8(ros.slros.internal.block.SendGoalErrorCode.SLSendGoalServerUnavailable);
                        return
                    end
    
                    isTerminalState = false;
                    if ~isempty(obj.pGoalHandle)
                        statusCode = obj.pGoalHandle.Status;
                        if ~enablesignal && isequal(statusCode, ros.slros2.internal.block.GoalTerminalStates.SLRejected)
                            % Check if the outstanding goal is in rejected state
                            % Show ErrorCode for the rejected goal
                            % Show UUID output as default message, as UUID is
                            % empty for rejected goal. New goal is ignored
                            errorCode = uint8(ros.slros.internal.block.SendGoalErrorCode.SLSendGoalRejected);
                            return
                        end
    
                        % Check if the outstanding goal is in terminal state
                        terminalStates = {ros.slros2.internal.block.GoalTerminalStates.SLSucceeded, ...
                            ros.slros2.internal.block.GoalTerminalStates.SLCanceled, ...
                            ros.slros2.internal.block.GoalTerminalStates.SLAborted, ...
                            ros.slros2.internal.block.GoalTerminalStates.SLRejected};
    
                        if any(cellfun(@(x) isequal(x, statusCode), terminalStates))
                            isTerminalState = true;
                        end
    
                        obj.EmptySeedUUIDOutputMsg.uuid = obj.pGoalHandle.GoalUUIDInUint8;
    
                        if ~all(obj.EmptySeedUUIDOutputMsg.uuid==0)
                            UUIDMsg = obj.OutputConversionFcn(obj.EmptySeedUUIDOutputMsg, obj.EmptySeedOutputBusStruct,'',obj.ModelName,obj.Cast64BitIntegersToDouble);
                        end
    
                        if (~enablesignal && isTerminalState)
                            % Show UUID output of the outstanding goal that is
                            % in terminal state, when Enable port is false. New goal is ignored.
                            return
                        end
                    end
    
                    % Show default UUID output if there is no outstanding goal
                    % and when Enable port is false. New goal is ignored.
                    if enablesignal
                        if ~isempty(obj.pGoalHandle) && ~isTerminalState
                            % When there is an outstanding goal in progress and if
                            % Enable port is true, show its UUID. New goal is ignored.
                            % This condition does not get executed if there is
                            % no outstanding goal(empty goal handle)
                            return
                        end
    
                        % send an action goal only in following two conditions:
                        % 1. When there is no outstanding goal(empty goal handle)
                        %    and Enable port is true
                        % 2. When there is an outstanding goal which is in
                        %    terminal state and Enable port is true
                        thisMsg = obj.GoalInputConversionFcn(inputbusstruct, obj.EmptySeedGoalInputMsg);
    
                        % Fetch the map containing UUID as key and goal handle
                        % as value. If there is a outstanding goal UUID available
                        % in the map, remove it and fill it with new UUID and new goal handle
                        % when new goal is sent.
                        goalUUIDAndHandleMap = ros.ros2.internal.getGoalUUIDAndHandleMap;
                        if ~isempty(obj.pGoalHandle) && isKey(goalUUIDAndHandleMap,obj.pGoalHandle.GoalUUID)
                            goalUUIDAndHandleMap.remove(obj.pGoalHandle.GoalUUID);
                        end
    
                        try
                            % Send a goal with customized callback functions to the server.
                            % The goal will be sent only if there is no goal running.
                            %
                            % sendGoal will return immediately.
                            obj.pGoalHandle = obj.pActClient.sendGoal(thisMsg, obj.CallbackOpts);
                            obj.EmptySeedUUIDOutputMsg.uuid = obj.pGoalHandle.GoalUUIDInUint8;
                            goalUUIDAndHandleMap(obj.pGoalHandle.GoalUUID) = obj.pGoalHandle; %#ok<NASGU>
                        catch
                            % If there is any error when sending the goal, show
                            % the default UUID message bus and error code
                            errorCode = uint8(ros.slros.internal.block.SendGoalErrorCode.SLSendGoalFailure);
                            UUIDMsg = outputbusstruct;
                            return
                        end
    
                        if isequal(obj.pGoalHandle.Status, ros.slros2.internal.block.GoalTerminalStates.SLRejected)
                            errorCode = uint8(ros.slros.internal.block.SendGoalErrorCode.SLSendGoalRejected);
                            return
                        end
    
                        % Show Outstanding goal UUID only if the goal UUID is
                        % not empty. If the goal is rejected UUID is empty,
                        % so show the default message
                        UUIDMsg = obj.OutputConversionFcn(obj.EmptySeedUUIDOutputMsg, obj.EmptySeedOutputBusStruct,'',obj.ModelName,obj.Cast64BitIntegersToDouble);
                    end
                end
            elseif coder.target('Rtw')
                % Code generation
                UUIDMsg = outputbusstruct;

                isServerConnected = false;
                isServerConnected = coder.ceval([obj.BlockId,'.isServerConnected']);
                if ~isServerConnected
                    % Show ErrorCode if action server is not available
                    % Show UUID output as default message
                    errorCode = uint8(ros.slros.internal.block.SendGoalErrorCode.SLSendGoalServerUnavailable);
                    return
                end

                isTerminalState = false;
                statusCode = int8(-1);
                isGoalHandleAvailable = false;
                isGoalHandleAvailable = coder.ceval([obj.BlockId, '.isGoalHandleAvailable']);
                if isGoalHandleAvailable
                    statusCode = coder.ceval([obj.BlockId, '.getStatus']);
                    if ~enablesignal && isequal(statusCode, ros.slros2.internal.block.GoalTerminalStates.SLRejected)
                        % Check if the outstanding goal is in rejected state
                        % Show ErrorCode for the rejected goal
                        % Show UUID output as default message, as UUID is
                        % empty for rejected goal. New goal is ignored
                        errorCode = uint8(ros.slros.internal.block.SendGoalErrorCode.SLSendGoalRejected);
                        return
                    end

                    % Check if the outstanding goal is in terminal state
                    terminalStates = {ros.slros2.internal.block.GoalTerminalStates.SLSucceeded, ...
                        ros.slros2.internal.block.GoalTerminalStates.SLCanceled, ...
                        ros.slros2.internal.block.GoalTerminalStates.SLAborted, ...
                        ros.slros2.internal.block.GoalTerminalStates.SLRejected};

                    if any(cellfun(@(x) isequal(x, statusCode), terminalStates))
                        isTerminalState = true;
                    end

                    coder.ceval([obj.BlockId, '.getGoalUUID'], coder.wref(UUIDMsg));

                    if (~enablesignal && isTerminalState)
                        % Show UUID output of the outstanding goal that is
                        % in terminal state, when Enable port is false. New goal is ignored.
                        return
                    end
                end

                if enablesignal
                    if isGoalHandleAvailable && ~isTerminalState
                        % When there is an outstanding goal in progress and if
                        % Enable port is true, show its UUID. New goal is ignored.
                        % This condition does not get executed if there is
                        % no outstanding goal(empty goal handle)
                        return
                    end
                    % Call sendGoal in SimulinkActionClient to send the goal to
                    % server.
                    coder.ceval([obj.BlockId, '.sendGoal'], coder.rref(inputbusstruct), coder.wref(errorCode));
                    if(errorCode == uint8(ros.slros.internal.block.SendGoalErrorCode.SLSendGoalFailure))
                        UUIDMsg = outputbusstruct;
                        return
                    end
                    coder.ceval([obj.BlockId, '.waitUntilGoalReady']);
                    statusCode = coder.ceval([obj.BlockId, '.getStatus']);
                    if isequal(statusCode, ros.slros2.internal.block.GoalTerminalStates.SLRejected)
                        errorCode = uint8(ros.slros.internal.block.SendGoalErrorCode.SLSendGoalRejected);
                        return
                    end
                    coder.ceval([obj.BlockId, '.getGoalUUID'], coder.wref(UUIDMsg));
                end
            end
        end

        function releaseImpl(obj)
            if coder.target('MATLAB')
                % release implementation is only required for simulation
                isCodegen = ros.codertarget.internal.isCodegen;
                if ~isCodegen
                    st = ros.slros.internal.sim.ModelStateManager.getState(obj.ModelName);
                    st.decrNodeRefCount();
                    try
                        % Fetch the map and if there is a outstanding goal UUID available
                        % remove it during cleanup.
                        goalUUIDAndHandleMap = ros.ros2.internal.getGoalUUIDAndHandleMap;
                        if ~isempty(obj.pGoalHandle) && isKey(goalUUIDAndHandleMap,obj.pGoalHandle.GoalUUID)
                            goalUUIDAndHandleMap.remove(obj.pGoalHandle.GoalUUID);
                        end
                        delete(obj.pActClient);
                    catch
                        obj.pGoalHandle = [];
                        obj.pActClient = [];
                    end
                    if  ~st.nodeHasReferrers()
                        ros.slros.internal.sim.ModelStateManager.clearState(obj.ModelName);
                    end
                end
            elseif coder.target('Rtw')
                % Reset action client pointer
                coder.ceval([obj.BlockId, '.resetActClientPtr(); //']);
            end
        end
    end
end
