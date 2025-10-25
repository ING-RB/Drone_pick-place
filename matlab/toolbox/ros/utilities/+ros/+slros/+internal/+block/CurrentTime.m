classdef CurrentTime < ...
        matlab.System & ...
        ros.slros.internal.block.mixin.NodeDependent

    %This class is for internal use only. It may be removed in the future.

    %CurrentTime Return the current ROS time
    %
    %   t = ros.slros.internal.block.CurrentTime creates a system
    %   object, t, that retrieves the current ROS time on step. If the
    %   /use_sim_time ROS parameter is true, the most recent time from the
    %   /clock topic is returned. Otherwise, step will return the system
    %   time.
    %
    %   The system time in ROS follows the Unix / POSIX time standard. POSIX
    %   time is defined as the time that has elapsed since 00:00:00 Coordinated
    %   Universal Time (UTC), 1 January 1970, not counting leap seconds.
    %
    %   See also rostime.

    %   Copyright 2018-2024 The MathWorks, Inc.

    %#codegen

    properties (Nontunable)
        %OutputFormat - Output format
        %   The output format for the "Time" output.
        %   Default: 'bus'.
        OutputFormat = 'bus'

        %SampleTime - Sample time
        %   Default: -1 (inherited)
        SampleTime = -1
    end

    properties (Nontunable)
        %StreamWSVar - Workspace stream
        %   Used to redirect system object to get time from a workspace
        %   variable instead of from ROS network (used for testing only).
        %   The workspace variable should be created like this:
        %
        %   workspaceVar = ros.slros.internal.sim.TimeListStream;
        %   workspaceVar.TimeList = {rostime(5)};
        %
        %   This capability of using workspace variables is only used in
        %   internal testing, and is not documented for Simulink users.
        StreamWSVar = ''

        %ModelName - Name of model for this block
        ModelName = ros.slros.internal.block.mixin.NodeDependent.DefaultModelName
    end

    properties(Constant, Hidden)
        %OutputFormatSet - Valid dropdown choices for OutputFormat
        OutputFormatSet = matlab.system.StringSet({'bus', 'double'});
    end

    properties (Constant, Access=?ros.slros.internal.block.mixin.NodeDependent)
        %MessageCatalogName - Name of this block used in message catalog
        %   This property is used by the NodeDependent base class to
        %   customize error messages with the block name.
         
        %   Due a limitation in Embedded MATLAB code-generation with UTF-8 characters,
        %   use English text instead of message("ros:slros:rostime:MaskTitle").getString
        MessageCatalogName = 'ROS Current Time'
    end

    properties (Access = ...
                {?ros.slros.internal.block.CurrentTime, ...
                 ?matlab.unittest.TestCase})

        %Converter - Message to bus structure converter
        Converter

        %SampleTimeHandler - Object for validating sample time settings
        SampleTimeHandler
    end

    properties (Constant, Access = ...
                {?ros.slros.internal.block.CurrentTime, ...
                 ?matlab.unittest.TestCase})

        %IconName - Name of block icon
        IconName = "Current" + newline + "Time"

        %TimeMessageType - Pseudo Message Type for time structure
        TimeMessageType = string(ros.slros.internal.bus.Util.TimeMessageType)

        TimeToDoubleFcn = @(x)x.Sec+(x.Nsec)/1e9;
    end

    properties (Access = protected, Transient)
        %TimeStream - Handle to object that implements ros.slros.internal.sim.TimeStream
        %   This can be a sim.TimeNetStream (for getting time off
        %   the ROS network) or sim.TimeListStream (for getting messages
        %   from an object in the global scope; used in conjunction with
        %   StreamWsVar property)
        TimeStream

        UseSimulationTime = false;
    end

    methods
        function obj = CurrentTime(varargin)
        %CurrentTime Standard constructor

        % Support name-value pair arguments when constructing the object.
            setProperties(obj, nargin, varargin{:});

            % Initialize sample time validation object
            obj.SampleTimeHandler = robotics.slcore.internal.block.SampleTimeImpl;
        end

        function set.SampleTime(obj, sampleTime)
        %set.SampleTime Validate sample time specified by user
            obj.SampleTime = obj.SampleTimeHandler.validate(sampleTime); %#ok<MCSUP>
        end

    end

    methods(Access = protected)
        function setupImpl(obj)
        %setupImpl Perform one-time setup of system object

            obj.setupNodeDependent;

            if coder.target("MATLAB")
                % Execute in interpreted mode

                % Initialize converter to bus structure
                obj.createBusIfNeeded;
            elseif coder.target("Rtw")
                % Execute in ROS node generation

                headerFile = coder.const(ros.slros.internal.cgen.Constants.InitCode.HeaderFile);
                coder.cinclude(headerFile);
            end
        end

        function timeOut = stepImpl(obj)
        %stepImpl Retrieve and output current ROS time

            % Preallocate output
            if obj.OutputFormat == "double"
                timeOut = double(0.0);
            else
                timeOut.Sec = 0.0;
                timeOut.Nsec = 0.0;
            end

            if coder.target("MATLAB")
                % Execute in interpreted mode
                if ~isempty(obj.StreamWSVar)
                    currentTime = obj.TimeStream.getTime;
                elseif ~obj.UseSimulationTime
                    % If the use_sim_time is not set for the node, fetch the
                    % wall clock time directly.ROS and ROS 2 treats all
                    % time as UTC. POSIXTIME(T) - If T is unzoned, then
                    % POSIXTIME treats T as though its time zone is UTC,
                    % and not your local time zone
                    systemEpochTime = posixtime(datetime('now', 'TimeZone', 'UTC'));
                    currentTimeStruct.Sec = floor(systemEpochTime);
                    currentTimeStruct.Nsec = round((systemEpochTime - currentTimeStruct.Sec) * 1e9);
                    % Normalize the second and nanosecond values
                    [currentTime.Sec,currentTime.Nsec] = ros.internal.Parsing.normalizeSecsNsecs(currentTimeStruct.Sec,currentTimeStruct.Nsec);
                else
                    % If the use_sim_time is set for the node, fetch the Simulation time
                    % from interprocess
                    currentTimeStruct = obj.TimeStream.CurrentTimeStruct;
                    % Normalize the second and nanosecond values
                    [currentTime.Sec,currentTime.Nsec] = ros.internal.Parsing.normalizeSecsNsecs(currentTimeStruct.Sec,currentTimeStruct.Nsec);
                end

                if obj.OutputFormat == "double"
                    timeOut = obj.TimeToDoubleFcn(currentTime);
                else
                    timeOut.Sec = currentTime.Sec;
                    timeOut.Nsec = currentTime.Nsec;
                end
            elseif coder.target("Rtw")
                % Execute in ROS node generation

                if obj.OutputFormat == "double"
                    coder.ceval("currentROSTimeDouble", coder.wref(timeOut));
                else
                    coder.ceval("currentROSTimeBus", coder.wref(timeOut));
                end
            end
        end

        function releaseImpl(obj)
        %releaseImpl Release all resources

            obj.releaseNodeDependent;
        end
    end

    methods (Access = protected)
        function num = getNumInputsImpl(~)
        %getNumInputsImpl Define total number of inputs
        %   Since this is a source block, it has no input ports.
            num = 0;
        end

        function num = getNumOutputsImpl(~)
        %getNumOutputsImpl Define total number of outputs
            num = 1;
        end

        function timeOutputName = getOutputNamesImpl(~)
        %getOutputNamesImpl Return output port names for System block
            timeOutputName = "Time";
        end

        function maskDisplay = getMaskDisplayImpl(~)
        %getMaskDisplayImpl Customize the mask icon display
        %   This method allows customization of the mask display code. Note
        %   that this works both for the base mask and for the
        %   mask-on-mask.

            % Override the default system object mask with blank white icon with no-labels
            maskDisplay = {'ros.internal.setBlockIcon(gcbh, ''rosicons.robotlib_currenttime'');'};
        end

        function timeSize = getOutputSizeImpl(~)
        %getOutputSizeImpl Return size for each output port

        % The Time output port is always a scalar - either a double or
        % a scalar bus.
            timeSize = [1 1];
        end

        function timeType = getOutputDataTypeImpl(obj)
        %getOutputDataTypeImpl Return data type for each output port

            busName = obj.createBusIfNeeded;

            if obj.OutputFormat == "double"
                timeType = 'double';
            else
                % Return a bus name
                timeType = busName;
            end
        end

        function timeComplex = isOutputComplexImpl(~)
        %isOutputComplexImpl Return true for each output port with complex data
            timeComplex = false;
        end

        function timeFixed = isOutputFixedSizeImpl(~)
        %isOutputFixedSizeImpl Return true for each output port with fixed size
            timeFixed = true;
        end
    end

    methods (Access = protected)
        function sts = getSampleTimeImpl(obj)
        %getSampleTimeImpl Return sample time specification

            sts = obj.SampleTimeHandler.createSampleTimeSpec();
        end
    end

    methods (Access = protected)
        %% Methods that are implementations of abstract NodeDependent mixin
        function initializeDataStream(obj, modelState)
        %initializeDataStream Initialize data stream
        %   The stream is either connected to the ROS network or
        %   connected to a workspace variable.

            if ~isempty(obj.StreamWSVar)
                % Use a variable in MATLAB Workspace as source of messages.
                obj.TimeStream = evalin('base', obj.StreamWSVar);
                validateattributes(obj.TimeStream, {'ros.slros.internal.sim.TimeListStream'}, {'scalar'}, ...
                                   'initializeDataStream', 'TimeStream');
            else
                % Use ROS network as a source of parameters.
                if isempty(modelState.ROSNode) || ~isValidNode(modelState.ROSNode)
                    obj.ROSMaster = ros.slros.internal.sim.ROSMaster;
                    %  verifyReachable() errors if ROS master is unreachable
                    obj.ROSMaster.verifyReachable;
                    % createNode() errors if unable to create node
                    % (e.g., if node with same name already exists)
                    uniqueName = obj.ROSMaster.makeUniqueName(obj.ModelName);
                    modelState.ROSNode = obj.ROSMaster.createNode(uniqueName);
                end

                pTree = ros.ParameterTree(modelState.ROSNode);
                if pTree.has('use_sim_time') && pTree.get('use_sim_time')
                    obj.UseSimulationTime = true;
                end

                % Initialize the time stream
                obj.TimeStream = ros.internal.Time(modelState.ROSNode);
            end
        end

        function name = modelName(obj)
        %modelName Retrieve model name

            name = obj.ModelName;
        end
    end

    methods (Access = private)
        function busName = createBusIfNeeded(obj)
        %createBusIfNeeded Create a bus time object in the global workspace
        %   Only create it if it does not exist yet

            [busExists, busName] = ros.slros.internal.bus.Util.checkForBus(...
                char(obj.TimeMessageType), char(obj.ModelName));
            if busExists
                return;
            end

            % Create the object
            emptyROSMsg = ros.msg.Time;
            ros.slros.internal.bus.createBusDefnInGlobalScope(emptyROSMsg, char(obj.ModelName));
        end
    end


    methods(Access = protected, Static)
        function simMode = getSimulateUsingImpl
        %getSimulateUsingImpl Restrict simulation mode to interpreted execution
            simMode = "Interpreted execution";
        end

        function flag = showSimulateUsingImpl
        %showSimulateUsingImpl Do now show simulation execution mode dropdown in block mask
            flag = false;
        end

        function header = getHeaderImpl
        %getHeaderImpl Define header panel for System block dialog

            header = matlab.system.display.Header(mfilename("class"), ...
                                                  "Title", message("ros:slros:rostime:MaskTitle").getString, ...
                                                  "Text", message("ros:slros:rostime:MaskDescription").getString,...
                                                  "ShowSourceLink", false);
        end
    end
end
