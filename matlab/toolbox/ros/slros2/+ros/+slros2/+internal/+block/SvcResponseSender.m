classdef SvcResponseSender < ros.internal.mixin.InternalAccess & ...
    matlab.System
%SvcResponseSender send service response to ROS 2 network
%
%   H = ros.slros2.internal.block.SvcResponseSender creates a system
%   object, H, that send out a response to a service client on the ROS 2
%   network. The input is expected to be a Simulink response bus.
%
%   This system object is intended for use with the MATLAB System block. In
%   order to access the ROS 2 functionality from MATLAB, see ROS2SVCSERVER.
%
%   See also ros2svcserver.

%   Copyright 2023-2024 The MathWorks, Inc.
%#codegen

properties(Nontunable)
    %ModelName Name of Simulink model
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
    % InputConversionFcn Conversion function for input message
    InputConversionFcn
    % EmptySeedInputMsg Empty Seed Input ROSMessage
    EmptySeedInputMsg
end

properties (Access=private)
    %ServerObj - Service server object associated with the block
    ServerObj
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
    
                % Setup bus to message conversion
                obj.EmptySeedInputMsg = ros.slros2.internal.bus.Util.newMessageFromSimulinkMsgType([obj.ServiceType 'Response']);
                [emptyInputMsg,inputMsgInfo]= ros.internal.getEmptyMessage([obj.ServiceType 'Response'],'ros2');
                cachedMap = containers.Map();
                % This map contains the values of empty message data which
                % can be reused when required.
                refCachedMapStoragePath = fullfile(pwd,'+bus_conv_fcns','+ros2','+busToMsg','RefCachedMap.mat');
                refCachedMap = ros.slros.internal.bus.Util.getDataFromCacheFile(refCachedMapStoragePath);
                cachedMap([obj.ServiceType 'Response']) = emptyInputMsg;
                [pkgNameIn,msgNameIn] = fileparts([obj.ServiceType 'Response']);
                obj.InputConversionFcn = generateStaticConversionFunctions(obj,emptyInputMsg,...
                                                                           inputMsgInfo,'ros2','busToMsg',pkgNameIn,msgNameIn,cachedMap,refCachedMap,refCachedMapStoragePath);
            end
        elseif coder.target('RtwForRapid')
            % Rapid Accelerator. In this mode, coder.target('Rtw')
            % returns true as well, so it is importatn to check for
            % 'RtwForRapid' before checking for 'Rtw'
            coder.internal.errorIf(true, 'ros:slros2:codegen:RapidAccelNotSupported', 'ROS2 Send Service Response');
        elseif coder.target('Rtw')
            % Header files has been included in Receive Request block
            % Do nothing
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

    function stepImpl(obj, respIn)
        if coder.target('MATLAB')
            isCodegen = ros.codertarget.internal.isCodegen;
            if ~isCodegen
                respToSend = obj.InputConversionFcn(respIn, obj.EmptySeedInputMsg);
                sendResponse(obj.ServerObj, respToSend);
            end
        elseif coder.target('Rtw')
            coder.ceval([obj.BlockId, '.sendResponse'], coder.rref(respIn));
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
end
end
