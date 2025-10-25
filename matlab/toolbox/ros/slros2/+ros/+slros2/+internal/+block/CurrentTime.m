classdef CurrentTime < matlab.System

    %This class is for internal use only. It may be removed in the future.

    %CurrentTime Return the current ROS 2 time
    %
    %   t = ros.slros2.internal.block.CurrentTime creates a system
    %   object, t, that retrieves the current ROS 2 time on step. If the
    %   /use_sim_time ROS 2 parameter is true, the most recent time from the
    %   /clock topic is returned. Otherwise, step will return the system
    %   time.
    %
    %   The system time in ROS 2 follows the Unix / POSIX time standard.
    %   POSIX time is defined as the time that has elapsed since 00:00:00
    %   Coordinated Universal Time (UTC), 1 January 1970, not counting leap
    %   seconds.
    %
    %   See also ros2time.

    %   Copyright 2022-2024 The MathWorks, Inc.

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
        %ModelName - Name of model for this block
        ModelName = 'untitled'
    end

    properties(Constant, Hidden)
        %OutputFormatSet - Valid drop-down choices for OutputFormat
        OutputFormatSet = matlab.system.StringSet({'bus', 'double'});
    end

    properties (Constant, Access=?ros.slros.internal.block.mixin.NodeDependent)
        %MessageCatalogName - Name of this block used in message catalog
        %   This property is used by the NodeDependent base class to
        %   customize error messages with the block name.
         
        %   Due a limitation in Embedded MATLAB code-generation with UTF-8 characters,
        %   use English text instead of message("ros:slros:rostime:MaskTitle").getString
        MessageCatalogName = 'ROS 2 Current Time'
    end

    properties (Access = ...
                {?ros.slros2.internal.block.CurrentTime, ...
                 ?matlab.unittest.TestCase})

        %SampleTimeHandler - Object for validating sample time settings
        SampleTimeHandler

        ROS2NodeHandle = []

        ROS2TimeObj = []

        UseSimulationTime = false
    end

    properties (Constant, Access = ...
                {?ros.slros.internal.block.CurrentTime, ...
                 ?matlab.unittest.TestCase})

        %IconName - Name of block icon
        IconName = "Current" + newline + "Time"

        %TimeMessageType
        TimeMessageType = 'builtin_interfaces/Time'

        %Time Bus type
        TimeBusType = 'SL_Bus_builtin_interfaces_Time';

        TimeToDoubleFcn = @(x)double(x.sec)+double(x.nanosec)/1e9;

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
        
        function set.ModelName(obj, val)
            validateattributes(val, {'char'}, {'nonempty'}, '', 'ModelName');
            obj.ModelName = val;
        end
    end

    methods(Access = protected)
        function setupImpl(obj)
        %setupImpl Perform one-time setup of system object
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
                        uniqueName = ros.slros.internal.block.ROSPubSubBase.makeUniqueName(obj.ModelName);
                        modelState.ROSNode = ros2node(uniqueName, ...
                                                      ros.ros2.internal.NetworkIntrospection.getDomainIDForSimulink, ...
                                                      'RMWImplementation', ...
                                                       ros.ros2.internal.NetworkIntrospection.getRMWImplementationForSimulink);
                    end
                    modelState.incrNodeRefCount();
                    obj.ROS2NodeHandle = modelState.ROSNode;
                    obj.ROS2TimeObj = ros.internal.ros2.Time(obj.ROS2NodeHandle);
                    paramObj = ros2param(modelState.ROSNode.Name);
                    if paramObj.has('use_sim_time') && paramObj.get('use_sim_time')
                        obj.UseSimulationTime = true;
                    end
                end
            elseif coder.target('RtwForRapid')
                % Rapid Accelerator. In this mode, coder.target('Rtw')
                % returns true as well, so it is important to check for
                % 'RtwForRapid' before checking for 'Rtw'
                coder.internal.errorIf(true, 'ros:slros2:codegen:RapidAccelNotSupported', 'ROS2 Current Time');

            elseif coder.target('Rtw')
                coder.cinclude(ros.slros2.internal.cgen.Constants.NodeInterface.CommonHeader);

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

        function timeOut = stepImpl(obj)
        %stepImpl Retrieve and output current ROS time

            % Preallocate output
            if obj.OutputFormat == "double"
                timeOut = double(0.0);
            else
                timeOut.sec = int32(0);
                timeOut.nanosec = uint32(0);
            end

            if coder.target("MATLAB")
                % Execute in interpreted mode
                if ~obj.UseSimulationTime
                    % If the use_sim_time is not set for the node, fetch the
                    % wall clock time directly. ROS and ROS 2 treats all
                    % time as UTC. POSIXTIME(T) - If T is unzoned, then
                    % POSIXTIME treats T as though its time zone is UTC,
                    % and not your local time zone
                    systemEpochTime = posixtime(datetime('now', 'TimeZone', 'UTC'));
                    currentTimeStruct.sec = floor(systemEpochTime);
                    currentTimeStruct.nanosec = round((systemEpochTime - currentTimeStruct.sec) * 1e9);
                    % Normalize the second and nanosecond values, this will
                    % return double
                    [currentTime.sec,currentTime.nanosec] = ros.internal.Parsing.normalizeSecsNsecs(currentTimeStruct.sec,currentTimeStruct.nanosec);
                else
                    currentTime = obj.ROS2TimeObj.CurrentTime;
                end
                if obj.OutputFormat == "double"
                    timeOut = obj.TimeToDoubleFcn(currentTime);
                else
                    timeOut.sec = int32(currentTime.sec);
                    timeOut.nanosec = uint32(currentTime.nanosec);
                end
            elseif coder.target("Rtw")
                % Execute in ROS node generation

                if obj.OutputFormat == "double"
                    coder.ceval("currentROS2TimeDouble", coder.wref(timeOut));
                else
                    coder.ceval("currentROS2TimeBus", coder.wref(timeOut));
                end
            end
        end

        function releaseImpl(obj)
            if coder.target('MATLAB')
                % release implementation is only required for simulation
                isCodegen = ros.codertarget.internal.isCodegen;
                if ~isCodegen
                    st = ros.slros.internal.sim.ModelStateManager.getState(obj.ModelName);
                    st.decrNodeRefCount();
                    % catch the error and clear the subscriber property instead of explicitly
                    % calling the delete method
                    obj.ROS2NodeHandle = [];
                    obj.ROS2TimeObj = [];
                    if  ~st.nodeHasReferrers()
                        ros.slros.internal.sim.ModelStateManager.clearState(obj.ModelName);
                    end
                end
            end
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
            maskDisplay = {'ros.internal.setBlockIcon(gcbh, ''rosicons.ros2lib_currenttime'');'};
        end

        function timeSize = getOutputSizeImpl(~)
        %getOutputSizeImpl Return size for each output port

        % The Time output port is always a scalar - either a double or
        % a scalar bus.
            timeSize = [1 1];
        end

        function timeType = getOutputDataTypeImpl(obj)
        %getOutputDataTypeImpl Return data type for each output port

            if obj.OutputFormat == "double"
                timeType = 'double';
            else
                % Return a bus name
                timeType = obj.TimeBusType;
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
        function name = modelName(obj)
        %modelName Retrieve model name

            name = obj.ModelName;
        end
    end


    methods(Access = protected, Static)
        function simMode = getSimulateUsingImpl
        %getSimulateUsingImpl Restrict simulation mode to interpreted execution
            simMode = "Interpreted execution";
        end

        function flag = showSimulateUsingImpl
        %showSimulateUsingImpl Do now show simulation execution mode drop-down in block mask
            flag = false;
        end

        function header = getHeaderImpl
        %getHeaderImpl Define header panel for System block dialog
            header = matlab.system.display.Header(mfilename("class"), ...
                                                  "Title", message("ros:slros2:blockmask:CurrentTimeMaskTitle").getString, ...
                                                  "Text", message("ros:slros:blockmask:CurrentTimeMaskDescription").getString,...
                                                  "ShowSourceLink", false);
        end
    end
end
