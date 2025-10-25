classdef GetTransform < ros.slros.internal.block.ROSTransformBase & ... 
        ros.internal.mixin.InternalAccess
    %GetTransform Get transform from ROS 2 network
    %
    %   H = ros.slros2.internal.block.GetTransform creates a system object,
    %   H, that maintain a ROS 2 transformation tree and return
    %   geometry_msgs/TransformStamped message on given frames.
    %
    %   This system object is intended for use with the MATLAB System
    %   block. In order to access the ROS functionality from MATLAB, see
    %   ROS2TF.
    %
    %   See also ROS2TF

    %   Copyright 2023-2024 The MathWorks, Inc.
    %#codegen
    
    % ROS 2 TF Specific QoS settings and Options
    properties(Nontunable)
        %SLBusName - Simulink Bus Name for message type
        SLBusName = 'SL_Bus_geometry_msgs_TransformStamped'

        %DynamicQoSHistory - Dynamic Listener History
        DynamicQoSHistory = getString(message('ros:slros2:blockmask:QOSKeepLast'));
        %DynamicQoSDepth - Dynamic Listener Depth
        DynamicQoSDepth = 1;
        %DynamicQoSReliability - Dynamic Listener Reliability
        DynamicQoSReliability = getString(message('ros:slros2:blockmask:QOSBesetEffort'));
        %DynamicQoSDurability - Dynamic Listener Durability
        DynamicQoSDurability = getString(message('ros:slros2:blockmask:QOSVolatile'));
        %DynamicQOSDeadline - Dynamic Listener Deadline
        DynamicQOSDeadline = Inf;
        %DynamicQOSLifespan - Dynamic Listener Lifespan
        DynamicQOSLifespan = Inf;
        %DynamicQOSLiveliness - Dynamic Listener Liveliness
        DynamicQOSLiveliness = getString(message('ros:slros2:blockmask:QOSAutomatic'));
        %DynamicQOSLeaseDuration - Dynamic Listener Lease Duration
        DynamicQOSLeaseDuration = Inf;

        %StaticQoSHistory - Static Listener History
        StaticQoSHistory = getString(message('ros:slros2:blockmask:QOSKeepLast'));
        %StaticQoSDepth - Static Listener Depth
        StaticQoSDepth = 1;
        %StaticQoSReliability - Static Listener Reliability
        StaticQoSReliability = getString(message('ros:slros2:blockmask:QOSBesetEffort'));
        %StaticQoSDurability - Static Listener Durability
        StaticQoSDurability = getString(message('ros:slros2:blockmask:QOSVolatile'));
        %StaticQOSDeadline - Static Listener Deadline
        StaticQOSDeadline = Inf;
        %StaticQOSLifespan - Static Listener Lifespan
        StaticQOSLifespan = Inf;
        %StaticQOSLiveliness - Static Listener Liveliness
        StaticQOSLiveliness = getString(message('ros:slros2:blockmask:QOSAutomatic'));
        %StaticQOSLeaseDuration - Static Listener Lease Duration
        StaticQOSLeaseDuration = Inf;
    end

    properties(Hidden)
        %DynamicQOSAvoidROSNamespaceConventions - Dynamic Listener Avoid ROS Namespace Conventions
        DynamicQOSAvoidROSNamespaceConventions (1, 1) logical = false;

        %StaticQOSAvoidROSNamespaceConventions - Static Listener Avoid ROS Namespace Conventions
        StaticQOSAvoidROSNamespaceConventions (1, 1) logical = false;
    end

    properties(Constant, Hidden)
        %DynamicQoSHistorySet - Valid drop-down choices for DynamicQoSHistory
        DynamicQoSHistorySet = matlab.system.StringSet({message('ros:slros2:blockmask:QOSKeepLast').getString...
                            message('ros:slros2:blockmask:QOSKeepAll').getString});
        %DynamicQoSReliabilitySet - Valid drop-down choices for DynamicQoSReliability
        DynamicQoSReliabilitySet = matlab.system.StringSet({message('ros:slros2:blockmask:QOSBesetEffort').getString...
                            message('ros:slros2:blockmask:QOSReliable').getString});
        %DynamicQoSDurabilitySet - Valid drop-down choices for DynamicQoSDurability
        DynamicQoSDurabilitySet = matlab.system.StringSet({message('ros:slros2:blockmask:QOSTransient').getString...
                            message('ros:slros2:blockmask:QOSVolatile').getString});
        DynamicQOSLivelinessSet =  matlab.system.StringSet({message('ros:slros2:blockmask:QOSAutomatic').getString...
                            message('ros:slros2:blockmask:QOSManual').getString});

        %StaticQoSHistorySet - Valid drop-down choices for StaticQoSHistory
        StaticQoSHistorySet = matlab.system.StringSet({message('ros:slros2:blockmask:QOSKeepLast').getString...
                            message('ros:slros2:blockmask:QOSKeepAll').getString});
        %StaticQoSReliabilitySet - Valid drop-down choices for StaticQoSReliability
        StaticQoSReliabilitySet = matlab.system.StringSet({message('ros:slros2:blockmask:QOSBesetEffort').getString...
                            message('ros:slros2:blockmask:QOSReliable').getString});
        %StaticQoSDurabilitySet - Valid drop-down choices for StaticQoSDurability
        StaticQoSDurabilitySet = matlab.system.StringSet({message('ros:slros2:blockmask:QOSTransient').getString...
                            message('ros:slros2:blockmask:QOSVolatile').getString});
        StaticQOSLivelinessSet =  matlab.system.StringSet({message('ros:slros2:blockmask:QOSAutomatic').getString...
                            message('ros:slros2:blockmask:QOSManual').getString});

        ROS2NodeConst = ros.slros2.internal.cgen.Constants.NodeInterface;
    end

    properties (Access=private, Transient)
        %pTfTree - Maintain the ros2tf object
        pTfTree = []

        % Converter - Handle to object that encapsulates converting a
        % Simulink bus struct to a MATLAB ROS message. It is initialized to
        % indicate the class of the object
        Converter = ros.slros2.internal.sim.ROSMsgToBusStructConverter.empty
    end

    properties (Constant, Access=?ros.slros.internal.block.mixin.NodeDependent)
        %MessageCatalogName - Name of this block used in message catalog
        %   This property is used by the NodeDependent base class to
        %   customize error messages with the block name.
         
        %   Due a limitation in Embedded MATLAB code-generation with UTF-8 characters,
        %   use English text instead
        MessageCatalogName = 'ROS 2 Get Transform'
    end

    methods
        function obj = GetTransform(varargin)
        % Enable code to be generated even if this file is p-coded
            coder.allowpcode('plain');
            obj = obj@ros.slros.internal.block.ROSTransformBase(varargin{:});
        end
    end

    methods (Access = protected)
        function num = getNumInputsImpl(~)
            num = 1;
        end

        function num = getNumOutputsImpl(~)
            num = 2;
        end

        function varargout = getOutputSizeImpl(obj)

            if obj.OutputFormat == "double"
                varargout = {[1,1],[4,4]};
            else
                varargout = {[1 1],[1 1]};
            end
        end

        function varargout = isOutputFixedSizeImpl(~)
            varargout =  {true, true};
        end

        function sts = getSampleTimeImpl(obj)
            % Define sample time type and parameters
            sts = createSampleTime(obj, 'Type', 'Inherited', 'Allow', 'Constant');

            % Example: specify discrete sample time
            % sts = obj.createSampleTime("Type", "Discrete", ...
            %     "SampleTime", 1);
        end

        function varargout = getOutputDataTypeImpl(obj)

            if obj.OutputFormat == "double"
                varargout = {'logical', 'double'};
            else
                varargout =  {'logical', obj.SLBusName};
            end
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
                                                  'Title', message('ros:slros2:blockmask:GetTransformMaskTitle').getString, ...
                                                  'Text', message('ros:slros2:blockmask:GetTransformDescription').getString);
        end

        function throwSimStateError()
            coder.internal.errorIf(true, 'ros:slros:sysobj:BlockSimStateNotSupported', 'ROS 2 Get Transform');
        end
    end

    methods (Access = protected)
        function setupImpl(obj)
        %setupImpl is called when model is being initialized at the start
        %of a simulation
            if coder.target('MATLAB')
                % Only run simulation setup if it is not in code generation
                % process
                isCodegen = ros.codertarget.internal.isCodegen;
                if ~isCodegen
                    % Executing in MATLAB interpreted mode
                    modelState = ros.slros.internal.sim.ModelStateManager.getState(obj.ModelName, 'create');
                    % The following could be a separate method, but system
                    % object infrastructure doesn't appear to allow it
                    if isempty(modelState.ROSNode) || ~isValidNode(modelState.ROSNode)
                        uniqueName = obj.makeUniqueName(obj.ModelName);
                        modelState.ROSNode = ros2node(uniqueName, ...
                                                      ros.ros2.internal.NetworkIntrospection.getDomainIDForSimulink, ...
                                                      'RMWImplementation', ...
                                                       ros.ros2.internal.NetworkIntrospection.getRMWImplementationForSimulink);
                    end
                    obj.pTfTree = ros2tf(modelState.ROSNode, ...
                                         DynamicListenerQoS=struct('History',obj.qosReg(obj.DynamicQoSHistory),'Depth',obj.DynamicQoSDepth,...
                                                            'Reliability',obj.qosReg(obj.DynamicQoSReliability),'Durability',obj.qosReg(obj.DynamicQoSDurability), ...
                                                            'Deadline',obj.DynamicQOSDeadline, ...
                                                            'Lifespan',obj.DynamicQOSLifespan, ...
                                                            'Liveliness',lower(regexprep(obj.DynamicQOSLiveliness, '\s','')), ...
                                                            'LeaseDuration',obj.DynamicQOSLeaseDuration, ...
                                                            'AvoidROSNamespaceConventions',logical(obj.DynamicQOSAvoidROSNamespaceConventions)), ...
                                         StaticListenerQoS=struct('History',obj.qosReg(obj.StaticQoSHistory),'Depth',obj.StaticQoSDepth,...
                                                           'Reliability',obj.qosReg(obj.StaticQoSReliability),'Durability',obj.qosReg(obj.StaticQoSDurability), ...
                                                           'Deadline',obj.StaticQOSDeadline, ...
                                                           'Lifespan',obj.StaticQOSLifespan, ...
                                                           'Liveliness',lower(regexprep(obj.StaticQOSLiveliness, '\s','')), ...
                                                           'LeaseDuration',obj.StaticQOSLeaseDuration, ...
                                                           'AvoidROSNamespaceConventions',logical(obj.StaticQOSAvoidROSNamespaceConventions)));
                    modelState.incrNodeRefCount();
                    obj.Converter = ros.slros2.internal.sim.ROSMsgToBusStructConverter(...
                        obj.ROSMessageType, obj.ModelName);
                    obj.EmptySeedBusStruct = obj.Converter.convert(ros2message(obj.ROSMessageType));
    
                    [emptyMsg, info] = ros.internal.getEmptyMessage(obj.ROSMessageType,'ros2');
                    cachedMap = containers.Map();
                    % This map contains the values of empty message data
                    % which can be reused when required.
                    refCachedMapStoragePath = fullfile(pwd, '+bus_conv_fcns','+ros2','+msgToBus','RefCachedMap.mat');
                    refCachedMap = ros.slros.internal.bus.Util.getDataFromCacheFile(refCachedMapStoragePath);
                    cachedMap(obj.ROSMessageType) = emptyMsg;
                    [pkgName,msgName] = fileparts(obj.ROSMessageType);
                    obj.ConversionFcn = generateStaticConversionFunctions(obj,emptyMsg,...
                        info,'ros2','msgToBus',pkgName,msgName,cachedMap,refCachedMap,refCachedMapStoragePath);
                end
            elseif coder.target('RtwForRapid')
                % Rapid Accelerator. In this mode, coder.target('Rtw')
                % returns true as well, so it is important to check for
                % 'RtwForRapid' before checking for 'Rtw'
                coder.internal.errorIf(true, 'ros:slros2:codegen:RapidAccelNotSupported', 'ROS 2 Get Transform');
            elseif coder.target('Rtw')
                coder.cinclude(obj.ROS2NodeConst.CommonHeader);
                dynamic_qos_profile = coder.opaque('rmw_qos_profile_t', ...
                                           'rmw_qos_profile_default', 'HeaderFile', 'rmw/qos_profiles.h');
                static_qos_profile = coder.opaque('rmw_qos_profile_t', ...
                                           'rmw_qos_profile_default', 'HeaderFile', 'rmw/qos_profiles.h');

                obj.setQOSProfile(dynamic_qos_profile, static_qos_profile, ...
                    obj.DynamicQoSHistory, obj.DynamicQoSDepth, obj.DynamicQoSReliability, obj.DynamicQoSDurability, ...
                    obj.DynamicQOSDeadline, obj.DynamicQOSLifespan, obj.DynamicQOSLiveliness, obj.DynamicQOSLeaseDuration, obj.DynamicQOSAvoidROSNamespaceConventions, ...
                    obj.StaticQoSHistory, obj.StaticQoSDepth, obj.StaticQoSReliability, obj.StaticQoSDurability, ...
                    obj.StaticQOSDeadline, obj.StaticQOSLifespan, obj.StaticQOSLiveliness, obj.StaticQOSLeaseDuration, obj.StaticQOSAvoidROSNamespaceConventions);

                coder.ceval([obj.BlockId,'.createTfTree'], ...
                            dynamic_qos_profile, static_qos_profile);
            elseif coder.target('Sfun')
                % 'Sfun'  - Simulation through CodeGen target
                % Do nothing. MATLAB System block first does a pre-codegen
                % compile with 'Sfun' target, & then does the "proper"
                % codegen compile with Rtw or RtwForRapid, as appropriate.
            else
                % 'RtwForSim' - ModelReference SIM target
                % 'MEX', 'HDL', 'Custom' - Not applicable to MATLAB System block
                coder.internal.errorIf(true, 'ros:slros:sysobj:UnsupportedCodegenMode', coder.target);
            end
        end

        function [isAvail, value] = stepImpl(obj, busstruct)
        %stepImpl Retrieve and output TransformStamped message
            
            isAvail = false;
            if coder.target('MATLAB')
                msg = busstruct;
                isCodegen = ros.codertarget.internal.isCodegen;
                if ~isCodegen
                    % Check transform availability
                    if canTransform(obj.pTfTree,obj.TargetFrame,obj.SourceFrame)
                        isAvail = true;
                        tfMsg = getTransform(obj.pTfTree,obj.TargetFrame,obj.SourceFrame);
                        msg = obj.ConversionFcn(tfMsg, obj.EmptySeedBusStruct, {}, obj.ModelName, obj.Cast64BitIntegersToDouble);
                    end
                end
            elseif coder.target("Rtw")
                % Append 0 to obj.TargetFrame and obj.SourceFrame since
                % MATLAB doesn't automatically zero-terminate strings in
                % generated code
                isAvail = false;
                if ~isempty(obj.TargetFrame) && ~isempty(obj.SourceFrame)
                    targetFrame = [obj.TargetFrame char(0)]; % null-terminated frame name
                    sourceFrame = [obj.SourceFrame char(0)]; % null-terminated frame name
                    isAvail = coder.ceval([obj.BlockId,'.canTransform'], ...
                        targetFrame, sourceFrame);
                end
                msg = coder.nullcopy(busstruct);
                if isAvail
                    % Transform is available
                    coder.ceval([obj.BlockId,'.getTransform'], ...
                            coder.wref(msg), targetFrame, sourceFrame);
                end
            end

            % Return output value based on specified output format
            if strcmp(obj.OutputFormat,"double")
                % Output as a 4x4 transformation matrix
                rData = msg.transform.rotation;
                tData = msg.transform.translation;
                quat = [rData.w, rData.x, rData.y, rData.z];
                rMat = quat2rotm(quat);
                tVec = [tData.x, tData.y, tData.z];
                value = eye(4);
                if isAvail
                    value(1:3,1:3) = rMat;
                    value(1:3,4) = tVec;
                end
            else
                % Output as a TransformStamped message
                % Assign frame_id for source and target frames
                msg.header.frame_id(1:length(obj.TargetFrame)) = uint8(obj.TargetFrame);
                msg.child_frame_id(1:length(obj.SourceFrame)) = uint8(obj.SourceFrame);
                msg.header.frame_id_SL_Info.CurrentLength = uint32(length(obj.TargetFrame));
                msg.child_frame_id_SL_Info.CurrentLength = uint32(length(obj.SourceFrame));
                value = msg;
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
                        delete(obj.pTfTree);
                    catch
                        obj.pTfTree = [];
                    end
                    if  ~st.nodeHasReferrers()
                        ros.slros.internal.sim.ModelStateManager.clearState(obj.ModelName);
                    end
                end
            end
        end 
    end

    methods(Static, Hidden)
        function outStr = qosReg(inStr)
        % qosReg Replace QOS text using regular expression

            outStr = lower(regexprep(inStr, '\s',''));
        end

        function setQOSProfile(dynamicQosProfile, staticQosProfile, ...
                dynamicQosHist, dynamicQosDepth, dynamicQosReliability, dynamicQosDurability, ...
                dynamicQosDeadline, dynamicQosLifespan, dynamicQosLiveliness, dynamicQosLeaseDuration, dynamicQosAvoidROSNamespaceConventions, ...
                staticQosHist, staticQosDepth, staticQosReliability, staticQosDurability, ...
                staticQosDeadline, staticQosLifespan, staticQosLiveliness, staticQosLeaseDuration, staticQosAvoidROSNamespaceConventions)
        % setQOSProfile Set the QoS profile values as specified in the Get
        % Transform block

                setSingleQOSProfile(dynamicQosProfile,dynamicQosHist,dynamicQosDepth,dynamicQosReliability,dynamicQosDurability, ...
                    dynamicQosDeadline, dynamicQosLifespan, dynamicQosLiveliness, dynamicQosLeaseDuration, dynamicQosAvoidROSNamespaceConventions);
                setSingleQOSProfile(staticQosProfile,staticQosHist,staticQosDepth,staticQosReliability,staticQosDurability, ...
                    staticQosDeadline, staticQosLifespan, staticQosLiveliness, staticQosLeaseDuration, staticQosAvoidROSNamespaceConventions);
            
            function setSingleQOSProfile(rmwProfile, qosHist, qosDepth, qosReliability, qosDurability, ...
                qosDeadline, qosLifespan, qosLiveliness, qosLeaseDuration, qosAvoidROSNamespaceConventions)
            % setSingleQOSProfile Set one single QoS profile values as
            % specified in the Get Transform block
            % This method uses the enumerations for history, durability, and
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
