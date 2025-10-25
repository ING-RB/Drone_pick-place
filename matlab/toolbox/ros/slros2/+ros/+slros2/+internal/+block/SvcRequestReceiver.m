classdef SvcRequestReceiver < ros.internal.mixin.InternalAccess & ...
    ros.slros2.internal.block.ROS2QOSBase
%SvcRequestReceiver receive service request from a ROS 2 network
%
%   H = ros.slros2.internal.block.SvcRequestReceiver creates a system object,
%   H, that receive a request from a service client on the ROS 2 network and
%   outputs the request message received.
%
%   This system object is intended for use with the MATLAB System block. In
%   order to access the ROS 2 functionality from MATLAB, see ROS2SVCSERVER.
%
%   See also ros2svcserver.

%   Copyright 2023-2024 The MathWorks, Inc.
%#codegen

properties(Nontunable)
    %SLBusName - Simulink Bus Name for service request
    SLBusName = ''

    %ModelName - Name of Simulink model
    %   Used for managing node instance
    ModelName = 'untitled'

    %ServiceName - Name of the service
    %   This system object will use ServiceName as specified in both
    %   simulation and code generation. In particular, it will not add
    %   a "/" in front of topic, as that forces the topic to be in the
    %   absolute namespace.
    ServiceName = '/my_service'

    %ServiceType - Type of the service
    ServiceType = 'std_srvs/Empty'

    %BlockId Simulink Block Identifier
    %  Used to generate unique identifier for the block during code
    %  generation. This should be obtained using Simulink.ID.getSID()
    %  on the library block (*not* the MATLAB system block). The
    %  SID has the format '<modelName>:<blocknum>'
    BlockId = 'serv1'
end

properties (Access=protected)
    %Cast64BitIntegersToDouble - Cast 64-bit integers to double (true
    % by default)
    Cast64BitIntegersToDouble = true;
    %OutputConversionFcn - Conversion function for output message
    OutputConversionFcn
    %EmptySeedOutputBusStruct Empty Seed output ROSMessage
    EmptySeedOutputBusStruct
end

properties (Access=private, Transient)
    % OutputConverter - Conversion for service response bus
    OutputConverter = ros.slros2.internal.sim.ROSMsgToBusStructConverter.empty
end

properties (Access=private)
    %ServerObj - Service server object associated with the block
    ServerObj
end

% public setter/getter methods
methods
    function obj = SvcRequestReceiver(varargin)
        coder.allowpcode('plain');
        % Support name-value pair arguments when constructing object
        setProperties(obj,nargin,varargin{:})
    end
end

methods (Access = protected)
    function setupImpl(obj)
        if coder.target('MATLAB')
            % Only run simulation setup if it is not in code generation
            % process
            isCodegen = ros.codertarget.internal.isCodegen;
            if ~isCodegen
                % Get server object from dictionary
                mgr = ros.internal.block.SharedObjectManager.getInstance;
                obj.ServerObj = mgr.getSvcServer(obj.BlockId);
    
                % Increase node reference count
                modelState = ros.slros.internal.sim.ModelStateManager.getState(obj.ModelName);
                modelState.incrNodeRefCount();
    
                % Setup message to bus conversion
                obj.OutputConverter = ros.slros2.internal.sim.ROSMsgToBusStructConverter(...
                        strcat(obj.ServiceType, 'Request'), obj.ModelName);
                emptySeedOutputMsg = ros.slros2.internal.bus.Util.newMessageFromSimulinkMsgType([obj.ServiceType 'Request']);
                obj.EmptySeedOutputBusStruct = obj.OutputConverter.convert(emptySeedOutputMsg);
                [emptyOutputMsg,outputMsgInfo]= ros.internal.getEmptyMessage([obj.ServiceType 'Request'],'ros2');
                cachedMap = containers.Map();
                % This map contains the values of empty message data which
                % can be reused when required.
                refCachedMapStoragePath = fullfile(pwd,'+bus_conv_fcns','+ros2','+msgToBus','RefCachedMap.mat');
                    refCachedMap = ros.slros.internal.bus.Util.getDataFromCacheFile(refCachedMapStoragePath);
                cachedMap([obj.ServiceType 'Request']) = emptyOutputMsg;
                [pkgNameOut,msgNameOut] = fileparts([obj.ServiceType 'Request']);
                obj.OutputConversionFcn = generateStaticConversionFunctions(obj,emptyOutputMsg,...
                                                                            outputMsgInfo,'ros2','msgToBus',pkgNameOut,msgNameOut,cachedMap,refCachedMap,refCachedMapStoragePath);
            end
        elseif coder.target('RtwForRapid')
            % Rapid Accelerator. In this mode, coder.target('Rtw')
            % returns true as well, so it is important to check for
            % 'RtwForRapid' before checking for 'Rtw'
            coder.internal.errorIf(true, 'ros:slros2:codegen:RapidAccelNotSupported', 'ROS2 Receive Service Request');
        elseif coder.target('Rtw')
            coder.cinclude(obj.ROS2NodeConst.CommonHeader);
            % Append 0 to obj.ServiceName, since MATLAB doesn't
            % automatically zero-terminate strings in generated code
            zeroDelimTopic = [obj.ServiceName 0]; % null-terminated service name

            qos_profile = coder.opaque('rmw_qos_profile_t', ...
                                           'rmw_qos_profile_default', 'HeaderFile', 'rmw/qos_profiles.h');

            obj.setQOSProfile(qos_profile, obj.QOSHistory, obj.QOSDepth, ...
                                           obj.QOSReliability, obj.QOSDurability, ...
                                           obj.QOSDeadline, obj.QOSLifespan, ...
                                           obj.QOSLiveliness, obj.QOSLeaseDuration, ...
                                           obj.QOSAvoidROSNamespaceConventions);
            coder.ceval([obj.BlockId, '.createServiceServer'], ...
                        zeroDelimTopic, qos_profile);
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

    function [reqOut, isNew] = stepImpl(obj, reqIn)
    % stepImpl - Return request message and isNew output

        isNew = false;
        if coder.target('MATLAB')
            reqOut = reqIn;
            isCodegen = ros.codertarget.internal.isCodegen;
            if ~isCodegen
                [newRequest,isNew] = obj.ServerObj.getCurrentRequest;
    
                if isNew
                    reqOut = obj.OutputConversionFcn(newRequest, obj.EmptySeedOutputBusStruct,'',obj.ModelName,obj.Cast64BitIntegersToDouble);
                end
            end
        elseif coder.target('Rtw')
            % Service Server has been created in setupImpl, so there is
            % no need to create again.

            % Ensure that output is always assigned
            reqOut = coder.nullcopy(reqIn);
            % Get current request from server
            isNew = coder.ceval([obj.BlockId, '.getCurrentRequest'], coder.wref(reqOut));
        end
    end

    function releaseImpl(obj)
        if coder.target('MATLAB')
            % release implementation is only required for simulation
            isCodegen = ros.codertarget.internal.isCodegen;
            if ~isCodegen
                st = ros.slros.internal.sim.ModelStateManager.getState(obj.ModelName);
                st.decrNodeRefCount();
                if  ~st.nodeHasReferrers()
                    ros.slros.internal.sim.ModelStateManager.clearState(obj.ModelName);
                end
            end
        elseif coder.target('Rtw')
            % Reset service server pointer
            coder.ceval([obj.BlockId, '.resetSvcServerPtr(); //']);
        end
    end
end

%% Helper functions
methods (Access = protected)
    function conversionFcn = generateStaticConversionFunctions(obj,emptyMsg,info,rosver,simDirection,...
                                                               pkgName,msgName,cachedMap,refCachedMap,refCachedMapStoragePath)
        %Generate the conversion functions for required message types.
        fcnName = ['bus_conv_fcns.' [rosver '.'] [simDirection '.'] [pkgName '.'] msgName];
        fcnFileName = fullfile(pwd,'+bus_conv_fcns',['+' rosver],['+' simDirection],['+' pkgName],msgName);
        msgType = [pkgName '/' msgName];
        if ~isKey(refCachedMap, msgType)
            % If a new message type is found that is not
            % existing in map, then generate the converter for it.
            conversionFcn = getStaticConversionFcn(obj,emptyMsg,info,rosver,simDirection,pkgName,msgName,cachedMap,refCachedMap);
            refCachedMap(msgType) = emptyMsg;
            save(refCachedMapStoragePath,'refCachedMap');
            rehash;
        elseif ~isequal(refCachedMap(msgType),emptyMsg)
            % If there is a change in the message definition,
            % then regenerate its converter.
            conversionFcn = getStaticConversionFcn(obj,emptyMsg,info,rosver,simDirection,pkgName,msgName,cachedMap,refCachedMap);
            refCachedMap(msgType) = emptyMsg;
            save(refCachedMapStoragePath,'refCachedMap');
            rehash;
        elseif ~isequal(exist(fcnFileName,'file'),2)
            % If the generated converter file was deleted, then
            % regenerate it.
            conversionFcn = getStaticConversionFcn(obj,emptyMsg,info,rosver,simDirection,pkgName,msgName,cachedMap,refCachedMap);
            rehash;
        else
            % If the message type already exists in map and
            % there is no change in message definition then
            % just re-use the existing converter file.
            conversionFcn = str2func(fcnName);
        end
        obj.Cast64BitIntegersToDouble = ~ros.slros.internal.bus.Util.isInt64Enabled(obj.ModelName);
    end

    function ret = getStaticConversionFcn(~,emptyMsg,info,rosver,simDirection,pkgName,msgName,cachedMap,refCachedMap)
        validatestring(simDirection,{'busToMsg','msgToBus'},'getStaticConversionFcn','simDirection',2);
        ret = ros.slros.internal.bus.generateConversionFunction(emptyMsg,info,rosver,pkgName,msgName,cachedMap,refCachedMap,simDirection,fullfile(pwd,'+bus_conv_fcns'));
    end
end

methods
    function set.ServiceName(obj,val)
        validateattributes(val,{'char'},{'nonempty'},'','ServiceName');
        if coder.target('MATLAB')
            ros.internal.Namespace.canonicalizeName(val); % throws error
        end
        obj.ServiceName = val;
    end

    function set.ServiceType(obj,val)
        validateattributes(val, {'char'}, {'nonempty'}, '', 'ServiceType');
        if coder.target('MATLAB')
            ros.internal.Namespace.canonicalizeName(val); % throws error
        end
        obj.ServiceType = val;
    end

    function set.SLBusName(obj, val)
        validateattributes(val, {'char'}, {}, '', 'SLBusName');
        obj.SLBusName = val;
    end

    function set.ModelName(obj, val)
        validateattributes(val, {'char'}, {'nonempty'}, '', 'ModelName');
        obj.ModelName = val;
    end
end

%% Setup execution mode
methods (Hidden, Static, Access = protected)
    function flag = showSimulateUsingImpl
        flag = false;
    end
    function simMode = getSimulateUsingImpl
        simMode = 'Interpreted execution';
    end
end

methods (Access = protected)
    %% Common functions
    function sts = getSampleTimeImpl(obj)
    %getSampleTimeImpl Enable this system object to inherit
    %constant ('inf') sample times
        sts = createSampleTime(obj,'Type','Inherited','Allow','Constant');
    end

    % We don't save SimState, since there is no way save & restore the
    % Service Client object. However, saveObjectImpl and loadObjectImpl
    % are required since we have private properties.
    function s = saveObjectImpl(obj)
        obj.throwSimStateError();
        s = saveObjectImpl@matlab.System(obj);
    end

    function loadObjectImpl(obj,s,wasLocked)
        loadObjectImpl@matlab.System(obj,s,wasLocked);
    end

    function num = getNumInputsImpl(~)
        num = 1;
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
        varargout =  {obj.SLBusName, 'logical'};
    end

    function varargout = isOutputComplexImpl(~)
        varargout = {false, false};
    end
end

methods (Access = protected, Static)
    function throwSimStateError()
        coder.internal.errorIf(true, 'ros:slros:sysobj:BlockSimStateNotSupported', 'ROS 2 Receive Request');
    end
end

end
