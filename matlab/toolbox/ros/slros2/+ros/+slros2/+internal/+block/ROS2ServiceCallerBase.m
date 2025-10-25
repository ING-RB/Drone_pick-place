classdef (Abstract) ROS2ServiceCallerBase < ros.slros.internal.block.ROSServiceCallerBase
%#codegen

%   Copyright 2021-2023 The MathWorks, Inc.

    properties (Nontunable)
        %QOSHistory ros:slros2:blockmask:QOSHistoryPrompt
        QOSHistory = getString(message('ros:slros2:blockmask:QOSKeepLast'));

        % QOSDepth ros:slros2:blockmask:QOSDepthPrompt
        QOSDepth = 1;

        % QOSReliability ros:slros2:blockmask:QOSReliabilityPrompt
        QOSReliability = getString(message('ros:slros2:blockmask:QOSReliable'));

        % QOSDurability ros:slros2:blockmask:QOSDurabilityPrompt
        QOSDurability = getString(message('ros:slros2:blockmask:QOSVolatile'));

        % QOSDeadline ros:slros2:blockmask:QOSDeadlinePrompt
        QOSDeadline = Inf;

        % QOSLifespan ros:slros2:blockmask:QOSLifespanPrompt
        QOSLifespan = Inf;

        % QOSLiveliness ros:slros2:blockmask:QOSLivelinessPrompt
        QOSLiveliness = getString(message('ros:slros2:blockmask:QOSAutomatic'));

        % QOSLeaseDuration ros:slros2:blockmask:QOSLeaseDurationPrompt
        QOSLeaseDuration = Inf;
    end

    properties(Hidden)
        % QOSAvoidROSNamespaceConventions ros:slros2:blockmask:QOSAvoidROSNamespaceConventionsPrompt
        QOSAvoidROSNamespaceConventions (1, 1) logical = false;
    end

    % properties(Constant, Nontunable) % for future use
    %   QOSProfiles : Predefined QOS Profiles
    % end

    properties (Constant, Hidden)
        ROSVersion = 'ROS2';
        QOSHistorySet =  matlab.system.StringSet({message('ros:slros2:blockmask:QOSKeepLast').getString...
                                                  message('ros:slros2:blockmask:QOSKeepAll').getString});
        QOSReliabilitySet =  matlab.system.StringSet({message('ros:slros2:blockmask:QOSBesetEffort').getString...
                                                      message('ros:slros2:blockmask:QOSReliable').getString});
        QOSDurabilitySet =  matlab.system.StringSet({message('ros:slros2:blockmask:QOSTransient').getString...
                                                     message('ros:slros2:blockmask:QOSVolatile').getString});
        QOSLivelinessSet =  matlab.system.StringSet({message('ros:slros2:blockmask:QOSAutomatic').getString...
                            message('ros:slros2:blockmask:QOSManual').getString});

        ROS2NodeConst = ros.slros2.internal.cgen.Constants.NodeInterface;
    end

    properties(Constant,Access=protected)
        % Name of header file with declarations for variables and types
        % referred to in code emitted by setupImpl and stepImpl.
        HeaderFile = 'slros2_generic_service.h'
    end

    methods (Hidden, Access = protected)
        function flag = isInactivePropertyImpl(obj,propertyName)
            switch(propertyName)
              case 'QOSDepth'
                if strcmp(obj.QOSHistory, coder.const(DAStudio.message('ros:slros2:blockmask:QOSKeepAll')))
                    obj.QOSDepth = inf;
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

        function ret = getQOSArguments(obj)
            ret = {'History', lower(regexprep(obj.QOSHistory, '\s','')), ...
                   'Depth', getDepth(obj), ...
                   'Reliability', lower(regexprep(obj.QOSReliability, '\s','')), ...
                   'Durability',lower(regexprep(obj.QOSDurability, '\s','')), ...
                   'Deadline',obj.QOSDeadline, ...
                   'Lifespan',obj.QOSLifespan, ...
                   'Liveliness',lower(regexprep(obj.QOSLiveliness, '\s','')), ...
                   'LeaseDuration',obj.QOSLeaseDuration, ...
                   'AvoidROSNamespaceConventions',logical(obj.QOSAvoidROSNamespaceConventions)};
        end

        function ret = getDepth(obj)
            coder.extrinsic("message");
            coder.extrinsic("getString");
            if strcmp(obj.QOSHistory, coder.const(getString(message('ros:slros2:blockmask:QOSKeepAll'))))
                ret = double(intmax('int32'));
            else
                ret = obj.QOSDepth;
            end
        end

        function obj = ROS2ServiceCallerBase(varargin)
            coder.allowpcode('plain');
            % Support name-value pair arguments when constructing object
            setProperties(obj,nargin,varargin{:})
        end

        function set.QOSDepth(obj, val)
            validateattributes(val, ...
                               {'numeric'}, {'nonnegative', 'scalar'}, '', 'QOSDepth');
            obj.QOSDepth = val;
        end

        function set.QOSDeadline(obj, val)
            validateattributes(val, ...
                               {'numeric','double'}, {'positive','scalar','nonnan'}, '', 'QOSDeadline');
            obj.QOSDeadline = val;
        end

        function set.QOSLifespan(obj, val)
            validateattributes(val, ...
                               {'numeric','double'}, {'positive','scalar','nonnan'}, '', 'QOSLifespan');
            obj.QOSLifespan = val;
        end

        function set.QOSLeaseDuration(obj, val)
            validateattributes(val, ...
                               {'numeric','double'}, {'positive','scalar','nonnan'}, '', 'QOSLeaseDuration');
            obj.QOSLeaseDuration = val;
        end
    end

    methods(Static, Hidden)
        function setQOSProfile(rmwProfile, qosHist, qosDepth, qosReliability, qosDurability, ...
                qosDeadline, qosLifespan, qosLiveliness, qosLeaseDuration, qosAvoidROSNamespaceConventions)
        % SETQOSPROFILE Set the QoS profile values as specified in the
        % Publish/Subscribe block
        % This method uses the enumerations for history, durability and
        % reliability values as specified in 'rmw/types.h' header.
            coder.extrinsic("message");
            coder.extrinsic("getString");

            opaqueHeader = {'HeaderFile', 'rmw/types.h'};
            if isequal(qosHist, coder.const(getString(message('ros:slros2:blockmask:QOSKeepAll'))))
                history = coder.opaque('rmw_qos_history_policy_t', ...
                                       'RMW_QOS_POLICY_HISTORY_KEEP_ALL', opaqueHeader{:});
            else
                history = coder.opaque('rmw_qos_history_policy_t', ...
                                       'RMW_QOS_POLICY_HISTORY_KEEP_LAST', opaqueHeader{:});
            end
            if isequal(qosReliability, coder.const(getString(message('ros:slros2:blockmask:QOSReliable'))))
                reliability = coder.opaque('rmw_qos_reliability_policy_t', ...
                                           'RMW_QOS_POLICY_RELIABILITY_RELIABLE', opaqueHeader{:});
            else
                reliability = coder.opaque('rmw_qos_reliability_policy_t', ...
                                           'RMW_QOS_POLICY_RELIABILITY_BEST_EFFORT', opaqueHeader{:});
            end
            if isequal(qosDurability, coder.const(getString(message('ros:slros2:blockmask:QOSTransient'))))
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
            if coder.target('Rtw')
                coder.ceval('SET_QOS_VALUES', rmwProfile, history, depth, ...
                            durability, reliability, deadline, lifespan, liveliness, ...
                            liveliness_lease_duration, avoid_ros_namespace_conventions);
            end

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
