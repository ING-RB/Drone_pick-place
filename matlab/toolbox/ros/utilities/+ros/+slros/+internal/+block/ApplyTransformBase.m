classdef ApplyTransformBase < matlab.System
%#codegen

%   Copyright 2023 The MathWorks, Inc.

    properties (Nontunable)
        %EntityMsgType Entity message type
        EntityMsgType = 'geometry_msgs/QuaternionStamped'
    end

    % The following should ideally not show up in the MATLAB System block
    % dialog. However, setting them as 'Hidden' will prevent them from
    % being accessible via set_param & get_param.
    %
    %   ModelName is needed for managing the node instance
    %   BlockId is needed to generate a unique identifier in codegen
    properties (Nontunable)
        %ModelName Name of Simulink model
        %   Used for managing node instance
        ModelName = 'untitled'

        %BlockId Simulink Block Identifier
        %  Used to generate unique identifier for the block during code
        %  generation. This should be obtained using Simulink.ID.getSID()
        %  on the library block (*not* the MATLAB system block). The
        %  SID has the format '<modelName>:<blocknum>'
        BlockId = 'applytf1'

        %SLOutputBusName - Simulink Bus Name for output
        SLOutputBusName = ''
    end

    properties (Constant, Hidden)
        %EntityMsgTypeSet - Valid drop-down choices for EntityMsgType
        EntityMsgTypeSet = matlab.system.StringSet({...
            'geometry_msgs/QuaternionStamped', ...
            'geometry_msgs/Vector3Stamped', ...
            'geometry_msgs/PointStamped', ...
            'geometry_msgs/PoseStamped'})
    end

    properties (Access=protected, Transient)
        % OutputConverter - Handle to object that encapsulates converting a
        % MATLAB ROS message to a Simulink bus struct. It is initialized to
        % indicate the class of the object
        OutputConverter
    end

    properties (Constant, Hidden)
        %TFMsgType Message Type of TFMsg input
        TFMsgType = 'geometry_msgs/TransformStamped'
    end

    properties (Access = protected)
        %TFInputConversionFcn Conversion function for TFMsg input
        TFInputConversionFcn

        %EntityInputConversionFcn Conversion function for Entity input
        EntityInputConversionFcn

        %EntityOutputConversionFcn Conversion function for TFEntity output
        EntityOutputConversionFcn

        %EmptyTFInputMsg Empty seed TFMsg input ROS/ROS 2 message
        EmptyTFInputMsg

        %EmptyEntityInputMsg Empty seed Entity input ROS/ROS 2 message
        EmptyEntityInputMsg

        %EmptySeedOutputBusStruct Empty seed TFEntity output ROS/ROS 2 message
        EmptySeedOutputBusStruct

        % Cast64BitIntegersToDouble Cast 64-bit integers to double (true
        % by default)
        Cast64BitIntegersToDouble = true;
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

    methods (Abstract, Static, Access = protected)
        throwSimStateError
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

    % public setter/getter methods
    methods
        function obj = ApplyTransformBase(varargin)
            coder.allowpcode('plain');
            % Support name-value pair arguments when constructing object
            setProperties(obj,nargin,varargin{:})
        end

        function set.SLOutputBusName(obj, val)
            validateattributes(val, {'char'}, {}, '', 'SLOutputBusName');
            obj.SLOutputBusName = val;
        end

        function set.ModelName(obj, val)
            validateattributes(val, {'char'}, {'nonempty'}, '', 'ModelName');
            obj.ModelName = val;
        end

        function set.BlockId(obj, val)
            validateattributes(val, {'char'}, {'nonempty'}, '', 'BlockId');
            obj.BlockId = val;
        end
    end
end