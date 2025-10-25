classdef (Abstract) ROSTransformBase < matlab.System
%

%   Copyright 2023 The MathWorks, Inc.

%#codegen

    properties (Constant, Access = protected)
        %ROSMessageType Message type of GetTransform block is always
        %'geometry_msgs/TransformStamped'
        ROSMessageType = 'geometry_msgs/TransformStamped'
    end

    properties (Nontunable)
        %TargetFrame - Target coordinate frame
        TargetFrame = "robot_base"

        %SourceFrame - Source coordinate frame
        SourceFrame = "camera_center"

        %OutputFormat - Output format
        %   The output format for the "Value" output
        %   Default: 'bus'
        OutputFormat = 'bus'

        %SampleTime - Sample time
        %   Default: -1 (inherited)
        SampleTime = -1
    end

    properties(Constant, Hidden)
        %OutputFormatSet - Valid drop-down choices for OutputFormat
        OutputFormatSet = matlab.system.StringSet({'bus','double'});
    end

    % The following should ideally not show up in the MATLAB System block
    % dialog. However, setting them as 'Hidden' will prevent them from
    % being accessible via set_param & get_param.
    properties(Nontunable)
        %ModelName - Name of Simulink model
        %   Used for managing node instance
        ModelName = 'untitled'

        %BlockId Simulink Block Identifier
        %   Used to generate unique identifier for the block during code
        %   generation. This should be obtained using Simulink.ID.getSID()
        %   on the library block (*not* the MATLAB system block). The SID
        %   has the format '<modelName>:<blocknum>'
        BlockId = 'gettf1'
    end

    properties (SetAccess = immutable, GetAccess = protected)
        %SampleTimeHandler - Object for validating sample time settings
        SampleTimeHandler
    end

    properties (Access=protected)
        % Conversion function
        ConversionFcn

        % Empty Seed BusStruct
        EmptySeedBusStruct

        % Cast64BitIntegersToDouble - Cast 64-bit integers to double (true
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
            %getSampleTimeImpl Return sample time specification

            sts_base = obj.SampleTimeHandler.createSampleTimeSpec();

            if sts_base.Type == "Inherited"
                % Enable this system object to inherit constant ('inf') sample
                % times
                sts = createSampleTime(obj, 'Type', 'Inherited', 'Allow', 'Constant');
            else
                sts = sts_base;
            end
        end

        % We don't save SimState, since there is no way save & restore the
        % GetTransform object. However, saveObjectImpl are required since
        % we have private properties.
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
            if ~isKey(refCachedMap, obj.ROSMessageType)
                % If a new message type is found that is not
                % existing in map, then generate the converter for it.
                conversionFcn = getStaticConversionFcn(obj,emptyMsg,info,rosver,simDirection,pkgName,msgName,cachedMap,refCachedMap);
                refCachedMap(obj.ROSMessageType) = emptyMsg;
                save(refCachedMapStoragePath,'refCachedMap');
                rehash;
            elseif ~isequal(refCachedMap(obj.ROSMessageType),emptyMsg)
                % If there is a change in the message definition,
                % then regenerate its converter.
                conversionFcn = getStaticConversionFcn(obj,emptyMsg,info,rosver,simDirection,pkgName,msgName,cachedMap,refCachedMap);
                refCachedMap(obj.ROSMessageType) = emptyMsg;
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
        function obj = ROSTransformBase(varargin)
            coder.allowpcode('plain');
            
            % Support name-value pair arguments when constructing object
            setProperties(obj,nargin,varargin{:})
            
            % Initialize sample time validation object
            obj.SampleTimeHandler = robotics.slcore.internal.block.SampleTimeImpl;
        end

        function set.SampleTime(obj, sampleTime)
            %set.SampleTime Validate sample time specified by user
            obj.SampleTime = obj.SampleTimeHandler.validate(sampleTime); %#ok<MCSUP>
        end
    end

    methods(Static, Hidden)
        function newName = makeUniqueName(name)
        % Using the model name as the node name runs into some issues:
        %
        % 1) There are 2 MATLAB sessions running the same model
        %
        % 2) A model registers a node with ROS Master on model init
        %    and clears the node on model termination. In some cases, the ROS
        %    master can hold on to the node name even if the node
        %    itself (in ROSJAVA) is cleared. This causes a problem
        %    during model init on subsequent simulation runs.
        %
        % To avoid these kinds of issues, we randomize the node name
        % during simulation.
            newName = [name '_' num2str(randi(1e5,1))];
        end
    end
end
