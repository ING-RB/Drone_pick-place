classdef ros2actionserver < ros.internal.mixin.InternalAccess & ...
        coder.ExternalDependency
%This class is for internal use only. It may be removed in the future.
%ros2actionserver Codegen Implementation for ros2actionserver
%   See more information in ros2actionserver

%   Copyright 2023-2024 The MathWorks, Inc.
%#codegen

    properties (Dependent, SetAccess = private)
        %GoalMessage - goal message struct for safe access
        GoalMessage

        %FeedbackMessage - feedback message struct for safe access
        FeedbackMessage

        %ResultMessage - result message struct for safe access
        ResultMessage
    end

    properties (SetAccess = immutable)
        %ActionName - Name of action associated with this server
        ActionName

        %ActionType - Type of action associated with this server
        ActionType = ''

        %MultiGoalMode - Action mode of accepting multiple goal
        MultiGoalMode = 'on'

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

        %GoalMessageType - Message type of goal message
        GoalMessageType

        %FeedbackMessageType - Message type of feedback message
        FeedbackMessageType

        %ResultMessageType - Message type of result message
        ResultMessageType
    end

    properties (Access = private)
        %ExecuteGoalFcnUserData - User data for execute goal callback
        ExecuteGoalFcnUserData
        
        %ReceiveGoalFcnUserData - User data for receive goal callback
        ReceiveGoalFcnUserData

        %CancelGoalFcnUserData - User data for cancel goal callback
        CancelGoalFcnUserData

        %GoalMsgStruct - private goal message struct
        GoalMsgStruct

        %FeedbackMsgStruct - private feedback message struct
        FeedbackMsgStruct

        %ResultMsgStruct - private result message struct
        ResultMsgStruct

        %IsInitialized - indication of object initialization
        IsInitialized = false;
    end

    properties
        %ActionServerHelperPtr - Pointer to MATLABROS2ActServer
        ActionServerHelperPtr

        %ExecuteGoalFcn - execute goal callback function
        ExecuteGoalFcn

        %ReceiveGoalFcn - receive goal callback function
        ReceiveGoalFcn

        %CancelGoalFcn - cancel goal callback function
        CancelGoalFcn
    end

    methods
        function obj = ros2actionserver(node, actionName, actionType, varargin)
        
            % Declare extrinsic functions
            coder.inline('never');
            coder.extrinsic('ros.codertarget.internal.getCodegenInfo');
            coder.extrinsic('ros.codertarget.internal.ROSMATLABCgenInfo');
            coder.extrinsic('ros.codertarget.internal.ROSMATLABCgenInfo.getInstance');
            coder.extrinsic('ros.codertarget.internal.getEmptyCodegenMsg');

            % Check number of input arguments
            coder.internal.narginchk(5, 21, nargin);

            % Validate input ros2node
            validateattributes(node, {'ros2node'}, {'scalar'}, ...
                               'ros2actionserver','node');

            % Action name and type
            actname = convertStringsToChars(actionName);
            validateattributes(actname, {'char'},{'nonempty'}, ...
                               'ros2actionserver','actionName');
            acttype = convertStringsToChars(actionType);
            validateattributes(acttype, {'char'},{'nonempty'}, ...
                               'ros2actionserver','actionType');
            % Write to property
            obj.ActionName = actname;
            obj.ActionType = acttype;

            % Parse NV pairs
            % This contains five customizable QoS settings, three callback
            % functions, and on MultiGoalMode setting for action server
            nvPairs = struct('GoalServiceQoS', uint32(0),...
                'ResultServiceQoS', uint32(0),...
                'CancelServiceQoS',uint32(0),...
                'FeedbackTopicQoS',uint32(0),...
                'StatusTopicQoS',uint32(0),...
                'ExecuteGoalFcn',uint32(0),...
                'ReceiveGoalFcn',uint32(0),...
                'CancelGoalFcn',uint32(0),...
                'MultiGoalMode',uint32(0));
            pOpts = struct('PartialMatching',true,'CaseSensitivity',false);
            pStruct = coder.internal.parseParameterInputs(nvPairs,pOpts,varargin{:});
            goalServiceQoS = coder.internal.getParameterValue(pStruct.GoalServiceQoS,struct,varargin{:});
            resultServiceQoS = coder.internal.getParameterValue(pStruct.ResultServiceQoS,struct,varargin{:});
            cancelServiceQoS = coder.internal.getParameterValue(pStruct.CancelServiceQoS,struct,varargin{:});
            feedbackTopicQoS = coder.internal.getParameterValue(pStruct.FeedbackTopicQoS,struct,varargin{:});
            statusTopicQoS = coder.internal.getParameterValue(pStruct.StatusTopicQoS,struct,varargin{:});
            executeGoalFcn = coder.internal.getParameterValue(pStruct.ExecuteGoalFcn,{},varargin{:});
            receiveGoalFcn = coder.internal.getParameterValue(pStruct.ReceiveGoalFcn,{},varargin{:});
            cancelGoalFcn = coder.internal.getParameterValue(pStruct.CancelGoalFcn,{},varargin{:});
            multiGoalMode = coder.internal.getParameterValue(pStruct.MultiGoalMode,'on',varargin{:});

            % Parse multi goal mode
            obj.MultiGoalMode = convertStringsToChars(validatestring(multiGoalMode,{'on','off'},'ros2actionserver','MultiGoalMode'));

            % Parse callback functions
            if ~isempty(executeGoalFcn)
                validateattributes(executeGoalFcn,{'function_handle','cell'},{'nonempty'},'ros2actionserver','ExecuteGoalFcn');
                if isa(executeGoalFcn, 'function_handle')
                    obj.ExecuteGoalFcn = executeGoalFcn;
                elseif iscell(executeGoalFcn)
                    obj.ExecuteGoalFcn = executeGoalFcn{1};
                    obj.ExecuteGoalFcnUserData = executeGoalFcn{2:end};
                end
            else
                % Execution callback function cannot be empty
                % Place validation here to provide immediate error message
                % during compile time
                validateattributes(executeGoalFcn,{'function_handle','cell'},{'nonempty'},'ros2actionserver','ExecuteGoalFcn');
            end

            if ~isempty(receiveGoalFcn)
                validateattributes(receiveGoalFcn,{'function_handle','cell'},{'nonempty'},'ros2actionserver','ReceiveGoalFcn');
                if isa(receiveGoalFcn, 'function_handle')
                    obj.ReceiveGoalFcn = receiveGoalFcn;
                elseif iscell(receiveGoalFcn)
                    obj.ReceiveGoalFcn = receiveGoalFcn{1};
                    obj.ReceiveGoalFcnUserData = receiveGoalFcn{2:end};
                end
            end

            if ~isempty(cancelGoalFcn)
                validateattributes(cancelGoalFcn,{'function_handle','cell'},{'nonempty'},'ros2actionserver','CancelGoalFcn');
                if isa(cancelGoalFcn, 'function_handle')
                    obj.CancelGoalFcn = cancelGoalFcn;
                elseif iscell(cancelGoalFcn)
                    obj.CancelGoalFcn = cancelGoalFcn{1};
                    obj.CancelGoalFcnUserData = cancelGoalFcn{2:end};
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
                'Durability',uint32(0),...
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
                validateattributes(qosDeadline,{'double'},{'scalar', 'nonnegative', 'nonnan'},'ros2actionserver','Deadline');

                if ~isfield(fs{val}, 'Lifespan')
                    qosLifespan = 0;
                else
                    qosLifespan = coder.internal.getParameterValue(pInnerStruct.Lifespan,0,fs{val});
                end
                if qosLifespan==Inf
                    qosLifespan=0;
                end
                validateattributes(qosLifespan,{'double'},{'scalar', 'nonnegative', 'nonnan'},'ros2actionserver','Lifespan');

                if ~isfield(fs{val},'Liveliness')
                    qosLiveliness = 'automatic';
                else
                    qosLiveliness = convertStringsToChars(coder.internal.getParameterValue(pInnerStruct.Liveliness,'automatic',fs{val}));
                end
                validateStringParameter(qosLiveliness,{'automatic','default','manual'},'ros2actionserver','Liveliness');

                if ~isfield(fs{val}, 'LeaseDuration')
                    qosLeaseDuration = 0;
                else
                    qosLeaseDuration = coder.internal.getParameterValue(pInnerStruct.LeaseDuration,0,fs{val});
                end
                if qosLeaseDuration==Inf
                    qosLeaseDuration=0;
                end
                validateattributes(qosLeaseDuration,{'double'},{'scalar', 'nonnegative', 'nonnan'},'ros2actionserver','LeaseDuration');

                if ~isfield(fs{val}, 'AvoidROSNamespaceConventions')
                    qosAvoidROSNamespaceConventions = false;
                else
                    qosAvoidROSNamespaceConventions = coder.internal.getParameterValue(pInnerStruct.AvoidROSNamespaceConventions,false,fs{val});
                end
                validateattributes(qosAvoidROSNamespaceConventions,{'logical'},{'nonempty'},'ros2actionserver','AvoidROSNamespaceConventions');

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

            % Store QoS settings
            obj.GoalServiceQoS = obj.(mProps{1});
            obj.ResultServiceQoS = obj.(mProps{2});
            obj.CancelServiceQoS = obj.(mProps{3});
            obj.FeedbackTopicQoS = obj.(mProps{4});
            obj.StatusTopicQoS = obj.(mProps{5});

            % Get and register code generation information
            cgGoalInfo = coder.const(@ros.codertarget.internal.getCodegenInfo, actname, [acttype 'Goal'], 'actserver', 'ros2');
            goalMsgStructGenFcn = str2func(cgGoalInfo.MsgStructGen);
            obj.GoalMsgStruct = goalMsgStructGenFcn();
            
            cgFeedbackInfo = coder.const(@ros.codertarget.internal.getCodegenInfo, actname, [acttype 'Feedback'], 'actserver', 'ros2');
            feedbackMsgStructGenFcn = str2func(cgFeedbackInfo.MsgStructGen);
            obj.FeedbackMsgStruct = feedbackMsgStructGenFcn();

            cgResultInfo = coder.const(@ros.codertarget.internal.getCodegenInfo, actname, [acttype 'Result'], 'actserver', 'ros2');
            resultMsgStructGenFcn = str2func(cgResultInfo.MsgStructGen);
            obj.ResultMsgStruct = resultMsgStructGenFcn();

            % Create pointer to MATLABROS2ActServer object
            coder.ceval('auto goalStructPtr = ', coder.wref(obj.GoalMsgStruct));
            coder.ceval('auto feedbackStructPtr = ', coder.wref(obj.FeedbackMsgStruct));
            coder.ceval('auto resultStructPtr = ', coder.wref(obj.ResultMsgStruct));

            templateTypeStr = ['MATLABROS2ActServer<', cgGoalInfo.ActionCppType, ...
                ',' cgGoalInfo.MsgClass ',' cgFeedbackInfo.MsgClass ',' cgResultInfo.MsgClass ...
                ',' cgGoalInfo.MsgStructGen '_T,' cgFeedbackInfo.MsgStructGen '_T,' ...
                cgResultInfo.MsgStructGen '_T>'];
            obj.ActionServerHelperPtr = coder.opaque(['std::unique_ptr<', templateTypeStr, '>'], 'HeaderFile', 'mlros2_actserver.h');
            if ros.internal.codegen.isCppPreserveClasses
                % Create action server by passing in class methods as
                % callbacks
                obj.ActionServerHelperPtr = coder.ceval( ...
                    ['std::unique_ptr<', templateTypeStr, ...
                    '>(new ', templateTypeStr, '([this](){this->executeGoalCallback();},[this](){this->receiveGoalCallback();},',...
                    '[this](){this->cancelGoalCallback();},',...
                    'goalStructPtr,feedbackStructPtr,resultStructPtr));//']);
            else
                % Create action server by passing in static functions as
                % callbacks
                obj.ActionServerHelperPtr = coder.ceval( ...
                    ['std::unique_ptr<',templateTypeStr,...
                    '>(new ', templateTypeStr, '([obj](){ros2actionserver_executeGoalCallback(obj);},[obj](){ros2actionserver_receiveGoalCallback(obj);},',...
                    '[obj](){ros2actionserver_cancelGoalCallback(obj);},',...
                    'goalStructPtr,feedbackStructPtr,resultStructPtr);//']);
            end

            coder.ceval('MATLABROS2ActServer_createActServer', obj.ActionServerHelperPtr, ...
                node.NodeHandle, coder.rref(obj.ActionName), size(obj.ActionName, 2), ...
                qosProfilesCpp{1}, qosProfilesCpp{2}, qosProfilesCpp{3}, ...
                qosProfilesCpp{4}, qosProfilesCpp{5});

            % Ensure callback is not optimized away by making an explicit
            % call here
            obj.executeGoalCallback();
            obj.receiveGoalCallback();
            obj.cancelGoalCallback();

            % Update IsInitialized so that callback functions will get
            % executed next time they get triggered.
            obj.IsInitialized = true;
        end

        function resultMsg = ros2message(obj)
            coder.inline('never');
            resultMsg = ros2message([obj.ActionType 'Result']);
        end

        function feedbackMsg = getFeedbackMessage(obj)
            coder.inline('never');
            feedbackMsg = ros2message([obj.ActionType 'Feedback']);
        end

        function sendFeedback(obj, goalStruct, feedbackMsg)
            ros.internal.codegen.doNotOptimizeROS2(obj.ActionServerHelperPtr);
            goaluuid = goalStruct.goalUUID;
            coder.ceval('MATLABROS2ActServer_mlSendFeedback', ...
                        obj.ActionServerHelperPtr, ...
                        feedbackMsg, ...
                        goaluuid, size(goaluuid,2));
        end
        function status = isPreemptRequested(obj, goalStruct)
            ros.internal.codegen.doNotOptimizeROS2(obj.ActionServerHelperPtr);
            status = false;
            goaluuid = goalStruct.goalUUID;
            coder.ceval('MATLABROS2ActServer_mlIsPreemptRequested', ...
                        obj.ActionServerHelperPtr, ...
                        goaluuid, size(goaluuid,2), coder.wref(status));
        end
        function status = isCanceling(obj, goalStruct)
            ros.internal.codegen.doNotOptimizeROS2(obj.ActionServerHelperPtr);
            status = false;
            goaluuid = goalStruct.goalUUID;
            coder.ceval('MATLABROS2ActServer_mlIsCanceling', ...
                        obj.ActionServerHelperPtr, ...
                        goaluuid, size(goaluuid,2), coder.wref(status));
        end
        function handleGoalResponse(obj, ~, action)
            ros.internal.codegen.doNotOptimizeROS2(obj.ActionServerHelperPtr);
            validateattributes(action,{'char','string'}, ...
                            {'scalartext','nonempty'},'handleGoalResponse','action');
            if ~any(strcmpi(action,{'REJECT','ACCEPT_AND_EXECUTE'}))
                coder.internal.error('ros:mlros2:actionserver:InvalidGoalResponseAction',action);
            end
            action = convertStringsToChars(action);
            % By default, we accept all goals, so there is no action
            % required if action is 'ACCEPT_AND_EXECUTE'
            if strcmp(action,'REJECT')
                coder.ceval('MATLABROS2ActServer_rejectGoal', ...
                            obj.ActionServerHelperPtr);
            end
        end

        %% Callback functions
        function executeGoalCallback(obj)
            coder.inline('never');
            ros.internal.codegen.doNotOptimizeROS2(obj.ActionServerHelperPtr);
            
            % No need to check whether it is empty since we've already
            % check this in object constructor
            if (obj.IsInitialized)
                % Call user defined callback function
                % Syntax: function [result,success] = ...
                % handleAccepted(src,goalStruct,defaultFeedback,defaultResult)
                goalUUIDSize = int32(0);
                goalUUIDSize = coder.ceval('MATLABROS2ActServer_getCurrentUUIDSize', ...
                                obj.ActionServerHelperPtr);
                goalUUID = char(zeros(1,goalUUIDSize));
                msg = coder.nullcopy(obj.GoalMessage);
                coder.ceval('MATLABROS2ActServer_getCurrentGoalHandle', ...
                            obj.ActionServerHelperPtr, ...
                            coder.wref(goalUUID), ...
                            coder.wref(msg));
                coder.ceval('MATLABROS2ActServer_unlock', ...
                            obj.ActionServerHelperPtr);
                % Abort other goals if MultiGoalMode is set to 'off'
                if strcmp(obj.MultiGoalMode,'off')
                    goalGetsAborted = false;
                    coder.ceval('MATLABROS2ActServer_abortActiveGoalIfAny', ...
                                obj.ActionServerHelperPtr, ...
                                coder.wref(goalGetsAborted), ...
                                goalUUID,size(goalUUID,2));
                    if goalGetsAborted
                        coder.internal.warning('ros:mlros2:actionserver:SingleModeAbortingWarn'); %#ok<UNRCH>
                    end
                end
                % Create goalStruct and execute custom callback function
                goalStruct = struct('goal',msg,'goalUUID',goalUUID);
                defaultFeedbackMsg = obj.getFeedbackMessage;
                defaultResultMsg = obj.ros2message;
                if isempty(obj.ExecuteGoalFcnUserData)
                    [resultMsg, success] = obj.ExecuteGoalFcn(obj, ...
                                              goalStruct, ...
                                              defaultFeedbackMsg, ...
                                              defaultResultMsg);
                else
                    [resultMsg, success] = obj.ExecuteGoalFcn(obj, ...
                                              goalStruct, ...
                                              defaultFeedbackMsg, ...
                                              defaultResultMsg, ...
                                              obj.ExecuteGoalFcnUserData);
                end
                % Send the result back over the network
                if success
                    coder.ceval('MATLABROS2ActServer_sendGoalTerminalStatus', ...
                        obj.ActionServerHelperPtr, coder.rref(resultMsg), ...
                        goalUUID, goalUUIDSize, ['succeed' char(0)]);
                elseif isPreemptRequested(obj,goalStruct)
                    % Preempt but not cancel means the goal has been
                    % aborted, no additional actions required.
                    if isCanceling(obj,goalStruct)
                        coder.ceval('MATLABROS2ActServer_sendGoalTerminalStatus', ...
                            obj.ActionServerHelperPtr, coder.rref(resultMsg), ...
                            goalUUID, goalUUIDSize, ['canceled' char(0)]);
                    end
                else
                    coder.ceval('MATLABROS2ActServer_sendGoalTerminalStatus', ...
                        obj.ActionServerHelperPtr, coder.rref(resultMsg), ...
                        goalUUID, goalUUIDSize, ['aborted' char(0)]);
                end
            end
        end

        function receiveGoalCallback(obj)
            coder.inline('never');
            ros.internal.codegen.doNotOptimizeROS2('receiveGoalCallback');

            if obj.IsInitialized
                % Call user defined callback function
                % Syntax: function handleGoal(src,goalStruct)
                goalUUIDSize = int32(0);
                goalUUIDSize = coder.ceval('MATLABROS2ActServer_getCurrentUUIDSize', ...
                                obj.ActionServerHelperPtr);
                goalUUID = char(zeros(1,goalUUIDSize));
                msg = coder.nullcopy(obj.GoalMessage);
                coder.ceval('MATLABROS2ActServer_getCurrentGoalHandle', ...
                            obj.ActionServerHelperPtr, ...
                            coder.wref(goalUUID), ...
                            coder.wref(msg));
                coder.ceval('MATLABROS2ActServer_unlock', ...
                            obj.ActionServerHelperPtr);
                goalStruct = struct('goal',msg,'goalUUID',goalUUID);
                if ~isempty(obj.ReceiveGoalFcn)
                    if isempty(obj.ReceiveGoalFcnUserData)
                        obj.ReceiveGoalFcn(obj, ...
                                           goalStruct);
                    else
                        obj.ReceiveGoalFcn(obj, ...
                                           goalStruct, ...
                                           obj.ReceiveGoalFcnUserData);
                    end
                end
            end
        end

        function cancelGoalCallback(obj)
            coder.inline('never');
            ros.internal.codegen.doNotOptimizeROS2('cancelGoalCallback');
            
            if obj.IsInitialized
                % Call user defined callback function
                % Syntax: function handleCancel(src,goalStruct)
                goalUUIDSize = int32(0);
                goalUUIDSize = coder.ceval('MATLABROS2ActServer_getCurrentUUIDSize', ...
                                obj.ActionServerHelperPtr);
                goalUUID = char(zeros(1,goalUUIDSize));
                msg = coder.nullcopy(obj.GoalMessage);
                coder.ceval('MATLABROS2ActServer_getCurrentGoalHandle', ...
                            obj.ActionServerHelperPtr, ...
                            coder.wref(goalUUID), ...
                            coder.wref(msg));
                coder.ceval('MATLABROS2ActServer_unlock', ...
                            obj.ActionServerHelperPtr);
                goalStruct = struct('goal',msg,'goalUUID',goalUUID);
                if ~isempty(obj.CancelGoalFcn)
                    if isempty(obj.CancelGoalFcnUserData)
                        obj.CancelGoalFcn(obj, ...
                                          goalStruct);
                    else
                        obj.CancelGoalFcn(obj, ...
                                          goalStruct, ...
                                          obj.CancelGoalFcnUserData);
                    end
                end
            end
        end

        %% Getter functions
        function msg = get.GoalMessage(obj)
            msg = obj.GoalMsgStruct;
        end
        
        function msg = get.FeedbackMessage(obj)
            msg = obj.FeedbackMsgStruct;
        end

        function msg = get.ResultMessage(obj)
            msg = obj.ResultMsgStruct;
        end
    end

    methods (Static)
        function props = matlabCodegenNontunableProperties(~)
            props = {'ActionType'};
        end

        function ret = getDescriptiveName(~)
            ret = 'ROS 2 ActServer';
        end

        function ret = isSupportedContext(bldCtx)
            ret = bldCtx.isCodeGenTarget('rtw');
        end

        function updateBuildInfo(buildInfo, bldCtx)
            if bldCtx.isCodeGenTarget('rtw')
                srcFolder = ros.slros.internal.cgen.Constants.PredefinedCode.Location;
                addIncludeFiles(buildInfo,'mlros2_actserver.h',srcFolder);
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
