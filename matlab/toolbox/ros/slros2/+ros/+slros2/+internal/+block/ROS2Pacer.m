classdef ROS2Pacer < matlab.System
    % ROS2Pacer ROS 2 Pacer block co-simulates Simulink with ROS 2 enabled simulators
    % using lock-step cosimulation over the ROS 2 network.

    %   Copyright 2024 The MathWorks, Inc.

    %#codegen
    properties(Access=private)
        ErrorCode = uint8(0);
    end

    properties (Constant, Access=private)
        % Name of step service
        StepService = '/mw_step_control';

        % Step service type
        StepServiceType = 'rcl_interfaces/SetParameters';

        % Name of pause service
        PauseService = '/mw_pause_physics';

        % Pause service type
        PauseServiceType = 'std_srvs/SetBool';

        % Name of unpause service
        UnPauseService = '/mw_unpause_physics';

        % Unpause service type
        UnPauseServiceType = 'std_srvs/SetBool';

        % Name of reset world service
        ResetWorldService = '/mw_reset_world';

        % Reset World service type
        ResetWorldServiceType = 'std_srvs/SetBool';

        % Name of reset time service
        ResetTimeService = '/mw_reset_time';

        % Reset time service type
        ResetTimeServiceType = 'std_srvs/SetBool';
    end

    properties (Nontunable)
        %Timeout wait time for each call in seconds
        ConnectionTimeout = 10

        %SampleTime SampleTime for this block must be discrete fixed value
        SampleTime = 0.01

        %ResetBehavior ResetBehavior configure how to reset Simulator
        ResetBehavior = 0
    end

    % Pre-computed constants or internal states
    properties (Access = private)

        % ROS 2 Network node created by the block
        CurrentNode;

        % Client for Pause service
        PauseServiceClient;

        % Client for reset world service
        ResetWorldServiceClient;

        % Client for reset time service
        ResetTimeServiceClient;

        % Client for step service
        StepServiceClient;

        % Step service request message
        StepServiceReq;

        % Steps simulator move per step service call
        SimulatorSteps

        % Sample Time at which block will run
        FunctionalSampleTime

        % Model Name in which ROS 2 Pacer is added
        ModelName
    end

    methods(Access = protected, Static)

        function simMode = getSimulateUsingImpl
            % Only allow interpreted execution for driving Gazebo simulator
            simMode = "Interpreted execution";
        end

        function throwSimStateError()
            coder.internal.errorIf(true, 'ros:slros:sysobj:BlockSimStateNotSupported', 'ROS 2 Pacer');
        end
    end

    methods (Access = protected)
        function num = getNumInputsImpl(~)
            % Define total number of inputs for system with optional inputs
            num = 0;
        end

        function num = getNumOutputsImpl(~)
            % Define total number of outputs for system with optional
            % outputs
            num = 1;
        end

        function name = getOutputNamesImpl(~)
            % Return output port names for System block
            name = 'ErrorCode';
        end

        function varargout = getOutputSizeImpl(~)
            % Error code is always fixed size scalar
            varargout = {[1 1]};
        end

        function varargout = isOutputFixedSizeImpl(~)
            % Error code is always fixed size scalar
            varargout = {true};
        end

        function varargout = getOutputDataTypeImpl(~)
            % Data type of Block output is uint8
            varargout =  {'uint8'};
        end

        function varargout = isOutputComplexImpl(~)
            % Output is not complex
            varargout = {false};
        end

        function sts = getSampleTimeImpl(obj)
            % Define sample time type and parameters
            % Define OffsetTime to make sure block runs later than the other
            % blocks operating at same sample rate
            if obj.SampleTime == -1
                sts = createSampleTime(obj,'Type','Inherited');
                obj.FunctionalSampleTime = -1;
            else
                sts = createSampleTime(obj,'Type','Discrete','SampleTime',obj.SampleTime, 'OffsetTime', 0);
                obj.FunctionalSampleTime = sts.SampleTime;
            end

        end

        function validatePropertiesImpl(obj)
            % validating sample time
            if ~isequal(obj.SampleTime, -1)
                validateattributes(obj.SampleTime, {'numeric'}, {'scalar', 'positive'}, '', 'SampleTime');
            end
            % validate connection timeout
            validateattributes(obj.ConnectionTimeout, {'numeric'}, {'scalar', 'positive'}, '', 'ConnectionTimeout');
        end

        function setupImpl(obj)
            % setting ConnectionTimeout
            if coder.target('MATLAB')
                isCodegen = ros.codertarget.internal.isCodegen;
                if ~isCodegen
                    connectionTimeOut = ros.slros.internal.dlg.CosimSetup.setConnectionTimeout;
                    % if ConnectionTimeout value is updated by the user, then
                    % assigning the updated value to the parameter, otherwise
                    % continuing with the default value.
                    if ~isempty(connectionTimeOut)
                        obj.ConnectionTimeout = connectionTimeOut;
                    end

                    if obj.FunctionalSampleTime == -1
                        obj.FunctionalSampleTime = get_param(gcb, 'CompiledSampleTime');
                    end

                    fullBlockPath = gcb;

                    % Split the string at the slash to separate the model name and block name
                    pathParts = strsplit(fullBlockPath, '/');

                    % The first part is the model name
                    obj.ModelName = pathParts{1};
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

                    % creating node in the ROS 2 Network
                    obj.CurrentNode  = modelState.ROSNode;

                    % creating client for pause
                    [obj.PauseServiceClient, pauseReq] = ros2svcclient(modelState.ROSNode, obj.PauseService, obj.PauseServiceType);

                    try
                        % Pausing the Simulator
                        obj.PauseServiceClient.call(pauseReq, "Timeout", obj.ConnectionTimeout);
                    catch
                        % Failed to connect to server in the specified
                        % Timeout
                        error(message('ros:slros2:ros2pacer:ROS2PacerConnectionFailed'));
                    end

                    % Resetting simulator
                    if obj.ResetBehavior
                        % Creating reset time service client
                        [obj.ResetTimeServiceClient, resetTimeReq] = ros2svcclient(modelState.ROSNode, obj.ResetTimeService, obj.ResetTimeServiceType);

                        try
                            % Resetting time of Simulator
                            obj.ResetTimeServiceClient.call(resetTimeReq,"Timeout", obj.ConnectionTimeout);
                        catch
                            error(message('ros:slros2:ros2pacer:ROS2PacerConnectionFailed'));
                        end
                    else
                        % Creating Reset world service client
                        [obj.ResetWorldServiceClient,resetWorldReq] = ros2svcclient(modelState.ROSNode, obj.ResetWorldService, obj.ResetWorldServiceType);

                        try
                            % Resetting the Simulator
                            obj.ResetWorldServiceClient.call(resetWorldReq,"Timeout", obj.ConnectionTimeout);
                        catch
                            error(message('ros:slros2:ros2pacer:ROS2PacerConnectionFailed'));
                        end
                    end

                    % Creating service client to receive simulator time
                    % step
                    [timeStepClient, timeStepReq] = ros2svcclient(modelState.ROSNode, '/mw_get_time_step', 'rcl_interfaces/GetParameters');

                    try
                        % Fetching simulator time step
                        getTimeStepResp = timeStepClient.call(timeStepReq,"Timeout", obj.ConnectionTimeout);
                    catch
                        error(message('ros:slros2:ros2pacer:ROS2PacerConnectionFailed'));
                    end

                    % Parsing simulator time step
                    simulatorTimeStep = getTimeStepResp.values.double_value;

                    % Checking simulator time step
                    if isnan(simulatorTimeStep) || simulatorTimeStep == 0
                        error(message('ros:slros2:ros2pacer:ROS2PacerInvalidStepSize'));
                    end

                    % Computing steps Simulator move per service call
                    obj.SimulatorSteps = obj.FunctionalSampleTime / simulatorTimeStep;

                    % Checking if sample time is positive integral
                    % multiple of Simulator step size
                    if floor(obj.SimulatorSteps) ~= obj.SimulatorSteps

                        % fetching ModelName/BlockName to be displayed in
                        % error message
                        blockPath = get_param(gcb, 'Parent');

                        error(message('ros:slros2:ros2pacer:ROS2PacerSampleTimeNotMultiple', blockPath, num2str(simulatorTimeStep), num2str(obj.FunctionalSampleTime)));
                    end

                    % Creating step service client
                    [obj.StepServiceClient, obj.StepServiceReq] = ros2svcclient(modelState.ROSNode, obj.StepService, obj.StepServiceType);

                    % Assigning steps to request message for step service
                    obj.StepServiceReq.parameters.value.integer_value = int64(obj.SimulatorSteps);

                    modelState.incrNodeRefCount();
                end
            elseif coder.target('RtwForRapid')
            %Block does not contribute anything for code gen
            elseif coder.target('Rtw')
            %Block does not contribute anything for code gen
            elseif  coder.target('Sfun')
            %Block does not contribute anything for code gen
            else
            %Block does not contribute anything for code gen
            end
        end

        function errorCode = outputImpl(obj)
            % Assigning error code
            errorCode = obj.ErrorCode;
        end

        function updateImpl(obj)

            if coder.target('MATLAB')
                % Stepping Simulator forward
                [~, status, ~] = obj.StepServiceClient.call(obj.StepServiceReq,"Timeout", obj.ConnectionTimeout);
                if ~status
                    % Failed to receive valid response
                    obj.ErrorCode = uint8(1);
                else
                    obj.ErrorCode = uint8(0);
                end
            elseif coder.target('RtwForRapid')
            %Block does not contribute anything for code gen
            elseif coder.target('Rtw')
            %Block does not contribute anything for code gen
            elseif  coder.target('Sfun')
            %Block does not contribute anything for code gen
            else
            %Block does not contribute anything for code gen
            end
        end

        function releaseImpl(obj)
            if coder.target('MATLAB')
                st = ros.slros.internal.sim.ModelStateManager.getState(obj.ModelName);

                % Creating Unpause service client
                [unpauseClient, unpauseReq] = ros2svcclient(st.ROSNode, obj.UnPauseService, obj.UnPauseServiceType);

                try
                    % Unpausing Simulator
                    unpauseClient.call(unpauseReq,"Timeout", obj.ConnectionTimeout);
                catch
                    % No need to show error message if unpause call
                    % fails/timeouts
                end

                % Deleting all the previously created service clients and
                % node
                try
                    delete(obj.StepServiceClient);
                catch
                    obj.StepServiceClient = [];
                end
                try
                    delete(obj.PauseServiceClient);
                catch
                    obj.PauseServiceClient = [];
                end
                try
                    delete(unpauseClient);
                catch
                    % setting unpauseClient as empty error is throwing
                    % warning in editor, hence removing it.
                end

                if obj.ResetBehavior 
                    try
                        delete(obj.ResetTimeServiceClient);
                    catch
                        obj.ResetTimeServiceClient = [];
                    end
                else
                    try
                        delete(obj.ResetWorldServiceClient);
                    catch
                        obj.ResetWorldServiceClient = [];
                    end
                end

                st.decrNodeRefCount();
                if  ~st.nodeHasReferrers()
                    ros.slros.internal.sim.ModelStateManager.clearState(obj.ModelName);
                end
            end
        end

        function s = saveObjectImpl(obj)
            % We don't save SimState, since there is no way save & restore the
            % co-simulation settings.
            obj.throwSimStateError();
            s = saveObjectImpl@matlab.System(obj);
        end

        function loadObjectImpl(obj,s,wasLocked)
            loadObjectImpl@matlab.System(obj,s,wasLocked);
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
