classdef GetTransform < ros.slros.internal.block.ROSTransformBase & ...
        ros.internal.mixin.ROSInternalAccess
    %GetTransform Get transform from ROS network
    %
    %   H = ros.slroscpp.internal.block.GetTransform createsd a system
    %   object, H, that maintain a ROS transform tree and return
    %   geometry_msgs/TransformStamped message on give frames.
    %
    %   This system object is intended for use with the MATLAB System
    %   block. In order to access the ROS functionality from MATLAB, see
    %   ROSTF.
    %
    %   See also ROSTF.

    %   Copyright 2023 The MathWorks, Inc.
    %#codegen

    properties(Nontunable)
        %SLBusName Simulink Bus Name for message type
        SLBusName = 'SL_Bus'
    end

    properties (Access=private, Transient)
        %pTfTree - Maintain the rostf object
        pTfTree = []

        % Converter - Handle to object that encapsulates converting a
        % Simulink bus struct to a MATLAB ROS message. It is initialized to
        % indicate the class of the object
        Converter = ros.slroscpp.internal.sim.ROSMsgToBusStructConverter.empty

        % ROSMaster - Handle to an object that encapsulates interaction
        % with the ROS master. It is initialized to indicate the class of
        % the object.
        ROSMaster = ros.slros.internal.sim.ROSMaster.empty
    end

    properties (Constant, Access=?ros.slros.internal.block.mixin.NodeDependent)
        %MessageCatalogName - Name of this block used in message catalog
        %   This property is used by the NodeDependent base class to
        %   customize error messages with the block name.
         
        %   Due a limitation in Embedded MATLAB code-generation with UTF-8 characters,
        %   use English text instead
        MessageCatalogName = 'ROS Get Transform'
    end

    properties(Constant,Access=protected)
        % Name of header file with declarations for variables and types
        % referred to in code emitted by setupImpl and stepImpl.
        HeaderFile = ros.slros.internal.cgen.Constants.InitCode.HeaderFile;
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
                                                  'Title', message('ros:slros:blockmask:GetTransformMaskTitle').getString, ...
                                                  'Text', message('ros:slros:blockmask:GetTransformDescription').getString);
        end

        function throwSimStateError()
            coder.internal.errorIf(true, 'ros:slros:sysobj:BlockSimStateNotSupported', 'ROS Get Transform');
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
                    modelHasPriorState = ros.slros.internal.sim.ModelStateManager.hasState(obj.ModelName);
                    nodeRefCountIncremented = false;
    
                    try
                        % Executing in MATLAB interpreted mode
                        modelState = ros.slros.internal.sim.ModelStateManager.getState(obj.ModelName, 'create');
                        % The following could be a separate method, but system
                        % object infrastructure doesn't appear to allow it
                        if isempty(modelState.ROSNode) || ~isValidNode(modelState.ROSNode)
                            obj.ROSMaster = ros.slros.internal.sim.ROSMaster();
                            %  verifyReachable() errors if ROS master is unreachable
                            obj.ROSMaster.verifyReachable();
                            % createNode() errors if unable to create node
                            % (e.g., if node with same name already exists)
                            uniqueName = obj.ROSMaster.makeUniqueName(obj.ModelName);
                            modelState.ROSNode = obj.ROSMaster.createNode(uniqueName);
                        end
                        obj.pTfTree = ros.TransformationTree(modelState.ROSNode, ...
                            "DataFormat","struct");
                        %pause 0.5 second for registering TransformationTree
                        pause(0.5);
                        modelState.incrNodeRefCount();
                        nodeRefCountIncremented = true;
                        obj.Converter = ros.slroscpp.internal.sim.ROSMsgToBusStructConverter(...
                            obj.ROSMessageType, obj.ModelName);
                        obj.EmptySeedBusStruct = obj.Converter.convert(rosmessage(obj.ROSMessageType,"DataFormat","struct"));
                        [emptyMsg,info]= ros.internal.getEmptyMessage(obj.ROSMessageType,'ros');
                        cachedMap = containers.Map();                    
                        % This map contains the values of empty message data
                        % which can be reused when required.
                        refCachedMapStoragePath = fullfile(pwd,'+bus_conv_fcns','+ros','+msgToBus','RefCachedMap.mat');
                        refCachedMap = ros.slros.internal.bus.Util.getDataFromCacheFile(refCachedMapStoragePath);
                        cachedMap(obj.ROSMessageType) = emptyMsg;
                        [pkgName,msgName] = fileparts(obj.ROSMessageType);
                        obj.ConversionFcn = generateStaticConversionFunctions(obj,emptyMsg,...
                            info,'ros','msgToBus',pkgName,msgName,cachedMap,refCachedMap,refCachedMapStoragePath);
                    catch ME
                        if nodeRefCountIncremented
                            modelState.decrNodeRefCount();
                        end
                        if ~modelHasPriorState || ~modelState.nodeHasReferrers()
                            ros.slros.internal.sim.ModelStateManager.clearState(obj.ModelName);
                        end
                        % RETHROW will generate a hard-to-read stack trace, so
                        % use THROW instead.
                        throw(ME);
                    end
                end
            elseif coder.target('RtwForRapid')
                % Rapid Accelerator. In this mode, coder.target('Rtw')
                % returns true as well, so it is important to check for
                % 'RtwForRapid' before checking for 'Rtw'
                coder.internal.errorIf(true, 'ros:slros:sysobj:RapidAccelNotSupported', 'ROS Get Transform');
            elseif coder.target('Rtw')
                coder.cinclude(obj.HeaderFile);
                coder.ceval([obj.BlockId, '.createTfTree']);
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
        end

        function [isAvail, value] = stepImpl(obj, busstruct)
        %stepImpl Retrieve and output TransformStamped message

            isAvail = false;
            if coder.target('MATLAB')
                % Check transform availability
                if canTransform(obj.pTfTree, obj.TargetFrame, obj.SourceFrame)
                    isAvail = true;
                    tfMsg = getTransform(obj.pTfTree, obj.TargetFrame, obj.SourceFrame);
                    msg = obj.ConversionFcn(tfMsg, obj.EmptySeedBusStruct, {}, obj.ModelName, obj.Cast64BitIntegersToDouble);
                else
                    msg = busstruct;
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
                rData = msg.Transform.Rotation;
                tData = msg.Transform.Translation;
                quat = [rData.W, rData.X, rData.Y, rData.Z];
                rMat = quat2rotm(quat);
                tVec = [tData.X, tData.Y, tData.Z];
                value = eye(4);
                if isAvail
                    value(1:3,1:3) = rMat;
                    value(1:3,4) = tVec;
                end
            else
                % Output as a TransformStamped message
                % Assign frame_id for source and target frames
                msg.Header.FrameId(1:length(obj.TargetFrame)) = uint8(obj.TargetFrame);
                msg.ChildFrameId(1:length(obj.SourceFrame)) = uint8(obj.SourceFrame);
                msg.Header.FrameId_SL_Info.CurrentLength = uint32(length(obj.TargetFrame));
                msg.ChildFrameId_SL_Info.CurrentLength = uint32(length(obj.SourceFrame));
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
end