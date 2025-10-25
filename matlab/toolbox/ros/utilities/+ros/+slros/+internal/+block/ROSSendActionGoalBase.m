classdef (Abstract) ROSSendActionGoalBase < matlab.System
    %This class is for internal use only. It may be removed in the future.

    %#codegen

    %   Copyright 2023 The MathWorks, Inc.

    properties (Nontunable)
        %ActionName Name of the action
        %   This system object will use ActionName as specified in both
        %   simulation and code generation. In particular, it will not add
        %   a "/" in front of topic, as that forces the topic to be in the
        %   absolute namespace.
        ActionName = '/fibonacci'
    end

    properties (Abstract, Constant, Hidden)
        ROSVersion
    end

    % The following should ideally not show up in the MATLAB System block
    % dialog. However, setting them as 'Hidden' will prevent them from
    % being accessible via set_param & get_param.
    %
    %   ModelName is needed for managing the node instance
    %   BlockId is needed to generate a unique identifier in codegen
    properties (Nontunable)
        %SLGoalInputBusName - Simulink Bus Name for input (goal message)
        SLGoalInputBusName = ''

        %ModelName Name of Simulink model
        %   Used for managing node instance
        ModelName = 'untitled'

        %BlockId Simulink Block Identifier
        %  Used to generate unique identifier for the block during code
        %  generation. This should be obtained using Simulink.ID.getSID()
        %  on the library block (*not* the MATLAB system block). The
        %  SID has the format '<modelName>:<blocknum>'
        BlockId = 'action1'
    end

    properties(Abstract, Constant, Access=protected)
        %HeaderFile Name of header file with declarations for variables and
        %types referred to in code emitted by setupImpl and stepImpl.
        HeaderFile
    end

    properties (Access=protected)
        % OutputConversionFcn Conversion function for output message
        OutputConversionFcn

        % EmptySeedOutputBusStruct Empty Seed output ROS2 Message
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
            %getSampleTimeImpl Return sample time specification

            % Enable this system object to inherit constant ('inf') sample
            % times
            sts = createSampleTime(obj, 'Type', 'Inherited', 'Allow', 'Constant');
        end

        % We don't save SimState, since there is no way save & restore the
        % Action Client object. However, saveObjectImpl and loadObjectImpl
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
        function obj = ROSSendActionGoalBase(varargin)
            coder.allowpcode('plain');
            % Support name-value pair arguments when constructing object
            setProperties(obj,nargin,varargin{:})
        end

        function set.ActionName(obj, val)
            validateattributes(val,{'char'},{'nonempty'},'','ActionName');
            if coder.target('MATLAB')
                ros.internal.Namespace.canonicalizeName(val); % throws error
            end
            obj.ActionName = val;
        end

        function set.SLGoalInputBusName(obj, val)
            validateattributes(val, {'char'}, {}, '', 'SLGoalInputBusName');
            obj.SLGoalInputBusName = val;
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

    methods(Static, Hidden)
        function newName = makeUniqueName(name)
            % Using the model name as the node name runs into some issues:
            %
            % 1) There are 2 MATLAB sessions running the same model
            %
            % 2) A model registers a node with ROS Master on model init
            %    and clears the node on model termination. In some cases, the ROS
            %    master can hold on to the node name even if the node
            %    itself is cleared. This causes a problem during model init
            %    on subsequent simulation runs.
            %
            % To avoid these kinds of issues, we randomize the node name
            % during simulation.
            newName = [name '_' num2str(randi(1e5,1))];
        end
    end
end
