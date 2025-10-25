classdef (Abstract) ROS2SendActionGoalBase < ros.slros.internal.block.ROSSendActionGoalBase
%This class is for internal use only. It may be removed in the future.

%#codegen

%   Copyright 2023 The MathWorks, Inc.

    % Public, Nontunable properties
    properties(Nontunable)
        %GoalServiceQoSHistory ros:slros2:blockmask:QOSHistoryPrompt
        GoalServiceQoSHistory = getString(message('ros:slros2:blockmask:QOSKeepLast'));
        %GoalServiceQoSDepth ros:slros2:blockmask:QOSDepthPrompt
        GoalServiceQoSDepth = 1;
        %GoalServiceQoSReliability ros:slros2:blockmask:QOSReliabilityPrompt
        GoalServiceQoSReliability = getString(message('ros:slros2:blockmask:QOSReliable'));
        %GoalServiceQoSDurability ros:slros2:blockmask:QOSDurabilityPrompt
        GoalServiceQoSDurability = getString(message('ros:slros2:blockmask:QOSVolatile'));
        %GoalServiceQoSDeadline ros:slros2:blockmask:QOSDeadlinePrompt
        GoalServiceQoSDeadline = Inf;
        %GoalServiceQoSLifespan ros:slros2:blockmask:QOSLifespanPrompt
        GoalServiceQoSLifespan = Inf;
        %GoalServiceQoSLiveliness ros:slros2:blockmask:QOSLivelinessPrompt
        GoalServiceQoSLiveliness = getString(message('ros:slros2:blockmask:QOSAutomatic'));
        %GoalServiceQoSLeaseDuration ros:slros2:blockmask:QOSLeaseDurationPrompt
        GoalServiceQoSLeaseDuration = Inf;

        %ResultServiceQoSHistory ros:slros2:blockmask:QOSHistoryPrompt
        ResultServiceQoSHistory = getString(message('ros:slros2:blockmask:QOSKeepLast'));
        %ResultServiceQoSDepth ros:slros2:blockmask:QOSDepthPrompt
        ResultServiceQoSDepth = 1;
        %ResultServiceQoSReliability ros:slros2:blockmask:QOSReliabilityPrompt
        ResultServiceQoSReliability = getString(message('ros:slros2:blockmask:QOSReliable'));
        %ResultServiceQoSDurability ros:slros2:blockmask:QOSDurabilityPrompt
        ResultServiceQoSDurability = getString(message('ros:slros2:blockmask:QOSVolatile'));
        %ResultServiceQoSDeadline ros:slros2:blockmask:QOSDeadlinePrompt
        ResultServiceQoSDeadline = Inf;
        %ResultServiceQoSLifespan ros:slros2:blockmask:QOSLifespanPrompt
        ResultServiceQoSLifespan = Inf;
        %ResultServiceQoSLiveliness ros:slros2:blockmask:QOSLivelinessPrompt
        ResultServiceQoSLiveliness = getString(message('ros:slros2:blockmask:QOSAutomatic'));
        %ResultServiceQoSLeaseDuration ros:slros2:blockmask:QOSLeaseDurationPrompt
        ResultServiceQoSLeaseDuration = Inf;

        %CancelServiceQoSHistory ros:slros2:blockmask:QOSHistoryPrompt
        CancelServiceQoSHistory = getString(message('ros:slros2:blockmask:QOSKeepLast'));
        %CancelServiceQoSDepth ros:slros2:blockmask:QOSDepthPrompt
        CancelServiceQoSDepth = 1;
        %CancelServiceQoSReliability ros:slros2:blockmask:QOSReliabilityPrompt
        CancelServiceQoSReliability = getString(message('ros:slros2:blockmask:QOSReliable'));
        %CancelServiceQoSDurability ros:slros2:blockmask:QOSDurabilityPrompt
        CancelServiceQoSDurability = getString(message('ros:slros2:blockmask:QOSVolatile'));
        %CancelServiceQoSDeadline ros:slros2:blockmask:QOSDeadlinePrompt
        CancelServiceQoSDeadline = Inf;
        %CancelServiceQoSLifespan ros:slros2:blockmask:QOSLifespanPrompt
        CancelServiceQoSLifespan = Inf;
        %CancelServiceQoSLiveliness ros:slros2:blockmask:QOSLivelinessPrompt
        CancelServiceQoSLiveliness = getString(message('ros:slros2:blockmask:QOSAutomatic'));
        %CancelServiceQoSLeaseDuration ros:slros2:blockmask:QOSLeaseDurationPrompt
        CancelServiceQoSLeaseDuration = Inf;

        %FeedbackTopicQoSHistory ros:slros2:blockmask:QOSHistoryPrompt
        FeedbackTopicQoSHistory = getString(message('ros:slros2:blockmask:QOSKeepLast'));
        %FeedbackTopicQoSDepth ros:slros2:blockmask:QOSDepthPrompt
        FeedbackTopicQoSDepth = 1;
        %FeedbackTopicQoSReliability ros:slros2:blockmask:QOSReliabilityPrompt
        FeedbackTopicQoSReliability = getString(message('ros:slros2:blockmask:QOSReliable'));
        %FeedbackTopicQoSDurability ros:slros2:blockmask:QOSDurabilityPrompt
        FeedbackTopicQoSDurability = getString(message('ros:slros2:blockmask:QOSVolatile'));
        %FeedbackTopicQoSDeadline ros:slros2:blockmask:QOSDeadlinePrompt
        FeedbackTopicQoSDeadline = Inf;
        %FeedbackTopicQoSLifespan ros:slros2:blockmask:QOSLifespanPrompt
        FeedbackTopicQoSLifespan = Inf;
        %FeedbackTopicQoSLiveliness ros:slros2:blockmask:QOSLivelinessPrompt
        FeedbackTopicQoSLiveliness = getString(message('ros:slros2:blockmask:QOSAutomatic'));
        %FeedbackTopicQoSLeaseDuration ros:slros2:blockmask:QOSLeaseDurationPrompt
        FeedbackTopicQoSLeaseDuration = Inf;

        %StatusTopicQoSHistory ros:slros2:blockmask:QOSHistoryPrompt
        StatusTopicQoSHistory = getString(message('ros:slros2:blockmask:QOSKeepLast'));
        %StatusTopicQoSDepth ros:slros2:blockmask:QOSDepthPrompt
        StatusTopicQoSDepth = 1;
        %StatusTopicQoSReliability ros:slros2:blockmask:QOSReliabilityPrompt
        StatusTopicQoSReliability = getString(message('ros:slros2:blockmask:QOSReliable'));
        %StatusTopicQoSDurability ros:slros2:blockmask:QOSDurabilityPrompt
        StatusTopicQoSDurability = getString(message('ros:slros2:blockmask:QOSTransient'));
        %StatusTopicQoSDeadline ros:slros2:blockmask:QOSDeadlinePrompt
        StatusTopicQoSDeadline = Inf;
        %StatusTopicQoSLifespan ros:slros2:blockmask:QOSLifespanPrompt
        StatusTopicQoSLifespan = Inf;
        %StatusTopicQoSLiveliness ros:slros2:blockmask:QOSLivelinessPrompt
        StatusTopicQoSLiveliness = getString(message('ros:slros2:blockmask:QOSAutomatic'));
        %StatusTopicQoSLeaseDuration ros:slros2:blockmask:QOSLeaseDurationPrompt
        StatusTopicQoSLeaseDuration = Inf;
    end

    properties(Hidden)
        % GoalServiceQoSAvoidROSNamespaceConventions ros:slros2:blockmask:QOSAvoidROSNamespaceConventionsPrompt
        GoalServiceQoSAvoidROSNamespaceConventions (1, 1) logical = false;
        % ResultServiceQoSAvoidROSNamespaceConventions ros:slros2:blockmask:QOSAvoidROSNamespaceConventionsPrompt
        ResultServiceQoSAvoidROSNamespaceConventions (1, 1) logical = false;
        % CancelServiceQoSAvoidROSNamespaceConventions ros:slros2:blockmask:QOSAvoidROSNamespaceConventionsPrompt
        CancelServiceQoSAvoidROSNamespaceConventions (1, 1) logical = false;
        % FeedbackTopicQoSAvoidROSNamespaceConventions ros:slros2:blockmask:QOSAvoidROSNamespaceConventionsPrompt
        FeedbackTopicQoSAvoidROSNamespaceConventions (1, 1) logical = false;
        % StatusTopicQoSAvoidROSNamespaceConventions ros:slros2:blockmask:QOSAvoidROSNamespaceConventionsPrompt
        StatusTopicQoSAvoidROSNamespaceConventions (1, 1) logical = false;
    end

    properties(Constant, Hidden)
        ROSVersion = 'ROS2';

        %GoalServiceQoSHistorySet - Valid drop-down choices for GoalServiceQoSHistory
        GoalServiceQoSHistorySet = matlab.system.StringSet({message('ros:slros2:blockmask:QOSKeepLast').getString...
                            message('ros:slros2:blockmask:QOSKeepAll').getString});
        %GoalServiceQoSReliabilitySet - Valid drop-down choices for GoalServiceQoSReliability
        GoalServiceQoSReliabilitySet = matlab.system.StringSet({message('ros:slros2:blockmask:QOSBesetEffort').getString...
                            message('ros:slros2:blockmask:QOSReliable').getString});
        %GoalServiceQoSDurabilitySet - Valid drop-down choices for GoalServiceQoSDurability
        GoalServiceQoSDurabilitySet = matlab.system.StringSet({message('ros:slros2:blockmask:QOSTransient').getString...
                            message('ros:slros2:blockmask:QOSVolatile').getString});
        %GoalServiceQoSLivelinessSet - Valid drop-down choices for GoalServiceQoSLiveliness
        GoalServiceQoSLivelinessSet = matlab.system.StringSet({message('ros:slros2:blockmask:QOSAutomatic').getString...
                            message('ros:slros2:blockmask:QOSManual').getString});

        %ResultServiceQoSHistorySet - Valid drop-down choices for ResultServiceQoSHistory
        ResultServiceQoSHistorySet = matlab.system.StringSet({message('ros:slros2:blockmask:QOSKeepLast').getString...
                            message('ros:slros2:blockmask:QOSKeepAll').getString});
        %ResultServiceQoSReliabilitySet - Valid drop-down choices for ResultServiceQoSReliability
        ResultServiceQoSReliabilitySet = matlab.system.StringSet({message('ros:slros2:blockmask:QOSBesetEffort').getString...
                            message('ros:slros2:blockmask:QOSReliable').getString});
        %ResultServiceQoSDurabilitySet - Valid drop-down choices for ResultServiceQoSDurability
        ResultServiceQoSDurabilitySet = matlab.system.StringSet({message('ros:slros2:blockmask:QOSTransient').getString...
                            message('ros:slros2:blockmask:QOSVolatile').getString});
        %ResultServiceQoSLivelinessSet - Valid drop-down choices for ResultServiceQoSLiveliness
        ResultServiceQoSLivelinessSet = matlab.system.StringSet({message('ros:slros2:blockmask:QOSAutomatic').getString...
                            message('ros:slros2:blockmask:QOSManual').getString});
        
        %CancelServiceQoSHistorySet - Valid drop-down choices for CancelServiceQoSHistory
        CancelServiceQoSHistorySet = matlab.system.StringSet({message('ros:slros2:blockmask:QOSKeepLast').getString...
                            message('ros:slros2:blockmask:QOSKeepAll').getString});
        %CancelServiceQoSReliabilitySet - Valid drop-down choices for CancelServiceQoSReliability
        CancelServiceQoSReliabilitySet = matlab.system.StringSet({message('ros:slros2:blockmask:QOSBesetEffort').getString...
                            message('ros:slros2:blockmask:QOSReliable').getString});
        %CancelServiceQoSDurabilitySet - Valid drop-down choices for CancelServiceQoSDurability
        CancelServiceQoSDurabilitySet = matlab.system.StringSet({message('ros:slros2:blockmask:QOSTransient').getString...
                            message('ros:slros2:blockmask:QOSVolatile').getString});
        %CancelServiceQoSLivelinessSet - Valid drop-down choices for CancelServiceQoSLiveliness
        CancelServiceQoSLivelinessSet = matlab.system.StringSet({message('ros:slros2:blockmask:QOSAutomatic').getString...
                            message('ros:slros2:blockmask:QOSManual').getString});

        %FeedbackTopicQoSHistorySet - Valid drop-down choices for FeedbackTopicQoSHistory
        FeedbackTopicQoSHistorySet = matlab.system.StringSet({message('ros:slros2:blockmask:QOSKeepLast').getString...
                            message('ros:slros2:blockmask:QOSKeepAll').getString});
        %FeedbackTopicQoSReliabilitySet - Valid drop-down choices for FeedbackTopicQoSReliability
        FeedbackTopicQoSReliabilitySet = matlab.system.StringSet({message('ros:slros2:blockmask:QOSBesetEffort').getString...
                            message('ros:slros2:blockmask:QOSReliable').getString});
        %FeedbackTopicQoSDurabilitySet - Valid drop-down choices for FeedbackTopicQoSDurability
        FeedbackTopicQoSDurabilitySet = matlab.system.StringSet({message('ros:slros2:blockmask:QOSTransient').getString...
                            message('ros:slros2:blockmask:QOSVolatile').getString});
        %FeedbackTopicQoSLivelinessSet - Valid drop-down choices for FeedbackTopicQoSLiveliness
        FeedbackTopicQoSLivelinessSet = matlab.system.StringSet({message('ros:slros2:blockmask:QOSAutomatic').getString...
                            message('ros:slros2:blockmask:QOSManual').getString});

        %StatusTopicQoSHistorySet - Valid drop-down choices for StatusTopicQoSHistory
        StatusTopicQoSHistorySet = matlab.system.StringSet({message('ros:slros2:blockmask:QOSKeepLast').getString...
                            message('ros:slros2:blockmask:QOSKeepAll').getString});
        %StatusTopicQoSReliabilitySet - Valid drop-down choices for StatusTopicQoSReliability
        StatusTopicQoSReliabilitySet = matlab.system.StringSet({message('ros:slros2:blockmask:QOSBesetEffort').getString...
                            message('ros:slros2:blockmask:QOSReliable').getString});
        %StatusTopicQoSDurabilitySet - Valid drop-down choices for StatusTopicQoSDurability
        StatusTopicQoSDurabilitySet = matlab.system.StringSet({message('ros:slros2:blockmask:QOSTransient').getString...
                            message('ros:slros2:blockmask:QOSVolatile').getString});
        %StatusTopicQoSLivelinessSet - Valid drop-down choices for StatusTopicQoSLiveliness
        StatusTopicQoSLivelinessSet = matlab.system.StringSet({message('ros:slros2:blockmask:QOSAutomatic').getString...
                            message('ros:slros2:blockmask:QOSManual').getString});

        ROS2NodeConst = ros.slros2.internal.cgen.Constants.NodeInterface;
    end

    properties(Constant,Access=protected)
        % Name of header file with declarations for variables and types
        % referred to in code emitted by setupImpl and stepImpl.
        HeaderFile = 'slros2_generic_action.h'
    end

    methods (Hidden, Access = protected)
        function flag = isInactivePropertyImpl(obj,propertyName)
            switch(propertyName)
                case {'GoalServiceQoSDepth', ...
                      'ResultServiceQoSDepth', ...
                      'CancelServiceQoSDepth', ...
                      'FeedbackTopicQoSDepth', ...
                      'StatusTopicQoSDepth'}
                    QosType = strsplit(propertyName,'QoS');
                    if strcmp(obj.([QosType{1} 'QoSHistory']), coder.const(DAStudio.message('ros:slros2:blockmask:QOSKeepAll')))
                        obj.([QosType{1} 'QoSDepth']) = inf;
                        flag = true;
                    else
                        flag = false;
                    end
                otherwise
                    flag = false;
            end
        end
    end

    % public setter/getter methods
    methods
        function obj = ROS2SendActionGoalBase(varargin)
            coder.allowpcode('plain');
            % Support name-value pair arguments when constructing object
            setProperties(obj,nargin,varargin{:})
        end

        function set.GoalServiceQoSDepth(obj, val)
            validateattributes(val, ...
                               {'numeric'}, {'nonnegative', 'scalar'}, '', 'GoalServiceQoSDepth');
            obj.GoalServiceQoSDepth = val;
        end

        function set.GoalServiceQoSDeadline(obj, val)
            validateattributes(val, ...
                               {'numeric','double'}, {'positive','scalar','nonnan'}, '', 'GoalServiceQoSDeadline');
            obj.GoalServiceQoSDeadline = val;
        end

        function set.GoalServiceQoSLifespan(obj, val)
            validateattributes(val, ...
                               {'numeric','double'}, {'positive','scalar','nonnan'}, '', 'GoalServiceQoSLifespan');
            obj.GoalServiceQoSLifespan = val;
        end

        function set.GoalServiceQoSLeaseDuration(obj, val)
            validateattributes(val, ...
                               {'numeric','double'}, {'positive','scalar','nonnan'}, '', 'GoalServiceQoSLeaseDuration');
            obj.GoalServiceQoSLeaseDuration = val;
        end

        function set.ResultServiceQoSDepth(obj, val)
            validateattributes(val, ...
                {'numeric'}, {'nonnegative', 'scalar'}, '', 'ResultServiceQoSDepth');
            obj.ResultServiceQoSDepth = val;
        end

        function set.ResultServiceQoSDeadline(obj, val)
            validateattributes(val, ...
                               {'numeric','double'}, {'positive','scalar','nonnan'}, '', 'ResultServiceQoSDeadline');
            obj.ResultServiceQoSDeadline = val;
        end

        function set.ResultServiceQoSLifespan(obj, val)
            validateattributes(val, ...
                               {'numeric','double'}, {'positive','scalar','nonnan'}, '', 'ResultServiceQoSLifespan');
            obj.ResultServiceQoSLifespan = val;
        end

        function set.ResultServiceQoSLeaseDuration(obj, val)
            validateattributes(val, ...
                               {'numeric','double'}, {'positive','scalar','nonnan'}, '', 'ResultServiceQoSLeaseDuration');
            obj.ResultServiceQoSLeaseDuration = val;
        end

        function set.CancelServiceQoSDepth(obj, val)
            validateattributes(val, ...
                {'numeric'}, {'nonnegative', 'scalar'}, '', 'CancelServiceQoSDepth');
            obj.CancelServiceQoSDepth = val;
        end

        function set.CancelServiceQoSDeadline(obj, val)
            validateattributes(val, ...
                               {'numeric','double'}, {'positive','scalar','nonnan'}, '', 'CancelServiceQoSDeadline');
            obj.CancelServiceQoSDeadline = val;
        end

        function set.CancelServiceQoSLifespan(obj, val)
            validateattributes(val, ...
                               {'numeric','double'}, {'positive','scalar','nonnan'}, '', 'CancelServiceQoSLifespan');
            obj.CancelServiceQoSLifespan = val;
        end

        function set.CancelServiceQoSLeaseDuration(obj, val)
            validateattributes(val, ...
                               {'numeric','double'}, {'positive','scalar','nonnan'}, '', 'CancelServiceQoSLeaseDuration');
            obj.CancelServiceQoSLeaseDuration = val;
        end

        function set.FeedbackTopicQoSDepth(obj, val)
            validateattributes(val, ...
                {'numeric'}, {'nonnegative', 'scalar'}, '', 'FeedbackTopicQoSDepth');
            obj.FeedbackTopicQoSDepth = val;
        end

        function set.FeedbackTopicQoSDeadline(obj, val)
            validateattributes(val, ...
                               {'numeric','double'}, {'positive','scalar','nonnan'}, '', 'FeedbackTopicQoSDeadline');
            obj.FeedbackTopicQoSDeadline = val;
        end

        function set.FeedbackTopicQoSLifespan(obj, val)
            validateattributes(val, ...
                               {'numeric','double'}, {'positive','scalar','nonnan'}, '', 'FeedbackTopicQoSLifespan');
            obj.FeedbackTopicQoSLifespan = val;
        end

        function set.FeedbackTopicQoSLeaseDuration(obj, val)
            validateattributes(val, ...
                               {'numeric','double'}, {'positive','scalar','nonnan'}, '', 'FeedbackTopicQoSLeaseDuration');
            obj.FeedbackTopicQoSLeaseDuration = val;
        end

        function set.StatusTopicQoSDepth(obj, val)
            validateattributes(val, ...
                {'numeric'}, {'nonnegative', 'scalar'}, '', 'StatusTopicQoSDepth');
            obj.StatusTopicQoSDepth = val;
        end

        function set.StatusTopicQoSDeadline(obj, val)
            validateattributes(val, ...
                               {'numeric','double'}, {'positive','scalar','nonnan'}, '', 'StatusTopicQoSDeadline');
            obj.StatusTopicQoSDeadline = val;
        end

        function set.StatusTopicQoSLifespan(obj, val)
            validateattributes(val, ...
                               {'numeric','double'}, {'positive','scalar','nonnan'}, '', 'StatusTopicQoSLifespan');
            obj.StatusTopicQoSLifespan = val;
        end

        function set.StatusTopicQoSLeaseDuration(obj, val)
            validateattributes(val, ...
                               {'numeric','double'}, {'positive','scalar','nonnan'}, '', 'StatusTopicQoSLeaseDuration');
            obj.StatusTopicQoSLeaseDuration = val;
        end
    end

     methods(Access = protected)
        function outStr = qosReg(obj,inStr)
        % qosReg Replace QOS text using regular expression
 
            outStr = lower(strrep(inStr, ' ', ''));
        end
 
        function setQOSProfile(obj,rmwProfile, qosHist, qosDepth, qosReliability, qosDurability, ...
                qosDeadline, qosLifespan, qosLiveliness, qosLeaseDuration, qosAvoidROSNamespaceConventions)
            % setSingleQOSProfile Set one single QoS profile values as
            % specified in the Send Action Goal block
            % This method uses the enumerations for history, durability, and
            % reliability values as specified in 'rmw/types.h' header.
 
            coder.extrinsic("message");
            coder.extrinsic("getString");
 
            opaqueHeader = {'HeaderFile', 'rmw/types.h'};
            if isequal(qosHist, obj.qosReg(coder.const(getString(message('ros:slros2:blockmask:QOSKeepAll')))))
                history = coder.opaque('rmw_qos_history_policy_t', ...
                    'RMW_QOS_POLICY_HISTORY_KEEP_ALL', opaqueHeader{:});
            else
                history = coder.opaque('rmw_qos_history_policy_t', ...
                    'RMW_QOS_POLICY_HISTORY_KEEP_LAST', opaqueHeader{:});
            end
            if isequal(qosReliability,  obj.qosReg(coder.const(getString(message('ros:slros2:blockmask:QOSReliable')))))
                reliability = coder.opaque('rmw_qos_reliability_policy_t', ...
                    'RMW_QOS_POLICY_RELIABILITY_RELIABLE', opaqueHeader{:});
            else
                reliability = coder.opaque('rmw_qos_reliability_policy_t', ...
                    'RMW_QOS_POLICY_RELIABILITY_BEST_EFFORT', opaqueHeader{:});
            end
            if isequal(qosDurability,  obj.qosReg(coder.const(getString(message('ros:slros2:blockmask:QOSTransient')))))
                durability = coder.opaque('rmw_qos_durability_policy_t', ...
                    'RMW_QOS_POLICY_DURABILITY_TRANSIENT_LOCAL', opaqueHeader{:});
            else
                durability = coder.opaque('rmw_qos_durability_policy_t', ...
                    'RMW_QOS_POLICY_DURABILITY_VOLATILE', opaqueHeader{:});
            end
            if isequal(coder.internal.toLower(qosLiveliness), 'automatic')
                liveliness = coder.opaque('rmw_qos_liveliness_policy_t', ...
                    'RMW_QOS_POLICY_LIVELINESS_AUTOMATIC', opaqueHeader{:});
            else
                liveliness = coder.opaque('rmw_qos_liveliness_policy_t', ...
                    'RMW_QOS_POLICY_LIVELINESS_MANUAL_BY_TOPIC', opaqueHeader{:});
            end
            depth = cast(qosDepth,'like',coder.opaque('size_t','0'));
            deadline = preprocessQos(qosDeadline);
            lifespan = preprocessQos(qosLifespan);
            liveliness_lease_duration = preprocessQos(qosLeaseDuration);
            avoid_ros_namespace_conventions = cast(qosAvoidROSNamespaceConventions,'like',coder.opaque('bool','false'));
 
            % Use SET_QOS_VALUES macro in <model name>_common.h to set the
            % structure members of rmw_qos_profile_t structure, The macro takes in
            % the rmw_qos_profile_t structure and assigns the history, depth,
            % durability, reliability, deadline, lifespan, liveliness,
            % liveliness_lease_duration and avoid_ros_namespace_conventions values
            % specified on system block to the qos_profile variable in generated
            % C++ code.
            coder.ceval('SET_QOS_VALUES', rmwProfile, history, depth, ...
                durability, reliability, deadline, lifespan, liveliness, ...
                liveliness_lease_duration, avoid_ros_namespace_conventions);
 
            function output = preprocessQos(input)
                % preprocessQos Preprocess duration-based qos settings to convert
                % infinite values to 0 for codegen and convert from double to
                % struct format to assign values to the rmw_time_t structure
 
                if(input == Inf)
                    input = 0;
                end
 
                sec = floor(input);
                nsec = (input - sec) * 1e9;
                output = struct('sec', sec, 'nsec', nsec);
            end
        end
     end

end
