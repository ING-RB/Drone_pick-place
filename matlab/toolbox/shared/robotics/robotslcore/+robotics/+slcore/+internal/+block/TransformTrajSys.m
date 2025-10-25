classdef TransformTrajSys < matlab.System
%TransformTrajSys Generate trajectories between two rotations

% Copyright 2018-2021 The MathWorks, Inc.

%#codegen

    properties (Nontunable)

        %Custom Time Scaling
        CustomTimeScaling (1, 1) logical = false



        %Waypoints Source
        WaypointSource = message("shared_robotics:robotslcore:trajectorygeneration:SourceInternalPopup").getString

        %Parameter Source
        ParameterSource = message("shared_robotics:robotslcore:trajectorygeneration:SourceInternalPopup").getString
    end

    properties (Constant, Hidden)

        % String set for WaypointSource
        WaypointSourceSet = matlab.system.StringSet({...
            message("shared_robotics:robotslcore:trajectorygeneration:SourceInternalPopup").getString, ...
            message("shared_robotics:robotslcore:trajectorygeneration:SourceExternalPopup").getString, ...
            })

        % String set for ParameterSource
        ParameterSourceSet = matlab.system.StringSet({...
            message("shared_robotics:robotslcore:trajectorygeneration:SourceInternalPopup").getString, ...
            message("shared_robotics:robotslcore:trajectorygeneration:SourceExternalPopup").getString, ...
            })
    end

    % Public, tunable properties
    properties
        %Initial Position
        T0 = trvec2tform([1 10 -1])

        %Final Position
        TF = eul2tform([0, pi, pi/2])

        %Time Interval
        TimeInterval = [2 3]

        %Time Scaling Time
        TSTime = 2:0.1:3

        %Time Scaling Values
        TimeScaling = [0:0.1:1; ones(1,11); zeros(1,11)]
    end

    properties(DiscreteState)

    end

    % Pre-computed constants
    properties(Access = private)

    end

    methods(Access = protected)
        %% System block methods

        function setupImpl(~)
        %setupImpl Perform one-time calculations, such as computing constants
        end

        function [tform, vel, acc] = stepImpl(obj, evalTime, varargin)
        %stepImpl Implement algorithm.

            % Waypoints may be internal or external
            [T0, TF, timeInterval, tsTime, timeScaling] = obj.getAndValidateInputs(evalTime, varargin, true);

            % Initialize fixed-type output arguments
            m = numel(evalTime);
            tform = zeros(4,4,m);
            vel = zeros(6,m);
            acc = zeros(6,m);

            % Pass argument by input case.
            if obj.CustomTimeScaling
                % Convert the user-defined time scaling, which may be at
                % points other than the exact evaluation time, into s(t)
                % and its derivatives at t = evalTime.
                localTimeScaling = robotics.slcore.internal.util.getTimeScalingAtEvalTime(tsTime, timeScaling, evalTime, timeInterval);

                % Compute outputs
                [tfCalc, vCalc, aCalc] = transformtraj(T0, TF, timeInterval, evalTime, 'TimeScaling', localTimeScaling);
            else
                [tfCalc, vCalc, aCalc] = transformtraj(T0, TF, timeInterval, evalTime);
            end

            % Pass computed outputs to block outputs
            tform(1:size(tfCalc,1), 1:size(tfCalc,2), 1:size(tfCalc,3)) = tfCalc;
            vel(1:size(vCalc,1),1:size(vCalc,2)) = vCalc;
            acc(1:size(aCalc,1),1:size(aCalc,2)) = aCalc;
        end

        function resetImpl(~)
        %resetImpl Initialize / reset discrete-state properties
        end

        function flag = isInactivePropertyImpl(obj,prop)
        %isInactivePropertyImpl Control appearance of block mask labels with changing visibility
        % Return false if property is visible based on object
        % configuration, for the command line and System block dialog

        %Initialize list of fields with option visibility
            parameterSrcPopup = {};
            parameterEditFields = {};
            waypointEditFields = {};

            if strcmp(obj.WaypointSource, "Internal")
                waypointEditFields = {'T0', 'TF', 'TimeInterval'};
            else
            end

            if obj.CustomTimeScaling
                parameterSrcPopup = {'ParameterSource'};
                if strcmp(obj.ParameterSource, "Internal")
                    parameterEditFields = {'TSTime', 'TimeScaling'};
                end
            end

            props = [waypointEditFields parameterSrcPopup parameterEditFields {'WaypointSource', 'CustomTimeScaling'}];

            flag = ~ismember(prop, props);
        end

        function validateInputsImpl(obj,evalTime,varargin)
        %validateInputsImpl Validate inputs to the step method at initialization
        %   These are checks that occur when the step method is
        %   initialized. At that point, the property dimensions and values
        %   are known, but input values are not known; only input
        %   dimensions can be used. All input validation that requires
        %   values to be known must be executed during the step method.
        
            [~, ~, timeInterval, timeScalingTimeVec, timeScaling] = getAndValidateInputs(obj, evalTime, varargin, false);
            validateattributes(evalTime, {'numeric'}, {'vector'}, 'TransformTrajSys', 'Time');
            validateattributes(timeInterval, {'numeric'}, {'vector','numel', 2}, 'TransformTrajSys', 'Time Interval');
            
            % Validate the time scaling time vector dimensions. The time
            % scaling time vector must have a dimension of at least two,
            % unless its value exactly matches that of evalTime
            coder.internal.errorIf((numel(timeScalingTimeVec) == 1) ...
                && (numel(timeScalingTimeVec) ~= numel(evalTime)), ...
                'shared_robotics:robotslcore:trajectorygeneration:TimeScalingIntervalDimensionError');

            % If all parameters are specified internally, the same rules
            % apply, but the values of the time interval may be verified at
            % initialization
            if strcmp(obj.ParameterSource, 'Internal') && strcmp(obj.WaypointSource, 'Internal') && obj.CustomTimeScaling
                coder.internal.errorIf(any([obj.TimeInterval(1) obj.TimeInterval(end)] ~= [obj.TSTime(1) obj.TSTime(end)]) ...
                    && (numel(timeScalingTimeVec) ~= numel(evalTime)), ...
                    'shared_robotics:robotslcore:trajectorygeneration:TimeScalingIntervalInterpError');
            end

            % Verify that sizes are appropriate if they have not already
            % been defined in the properties. To be able to independently
            % set properties without triggering validate attributes, the
            % check must happen here rather than in the
            % validatePropertiesImpl method.
            if strcmp(obj.ParameterSource, 'External')
                validateattributes(timeScaling, {'numeric'}, {'nonempty','nrows',3,'real','finite'}, 'TransformTrajSys','TimeScaling');
                coder.internal.errorIf(size(timeScaling,2) ~= numel(timeScalingTimeVec), 'shared_robotics:robotcore:utils:RotTrajTimeScalingLength');
            else
                coder.internal.errorIf(size(obj.TimeScaling,2) ~= numel(obj.TSTime), 'shared_robotics:robotcore:utils:RotTrajTimeScalingLength');
            end
        end

        function validatePropertiesImpl(obj)
        %validatePropertiesImpl Validate related or interdependent property values
        %   This method validates the properties at set time. Note that if
        %   there are interdependent property settings, applying them here
        %   will prevent users from entering them separately (though they
        %   can still be applied through the GUI or with a single set_param
        %   call). To ensure that the check is only processed at update,
        %   the check must instead be processed in the validateInputsImpl
        %   method.
        
            if strcmp(obj.WaypointSource, 'Internal')
                validateattributes(obj.T0, {'numeric'}, {'nonempty','2d','real','finite'}, 'TransformTrajSys','T0');
                validateattributes(obj.TF, {'numeric'}, {'nonempty','2d','real','finite'}, 'TransformTrajSys','TF');
                validateattributes(obj.TimeInterval, {'numeric'}, {'nonempty','vector','real','finite','increasing','nonnegative'}, 'TransformTrajSys','timeInterval');
            end

            if strcmp(obj.ParameterSource, 'Internal')
                validateattributes(obj.TimeScaling, {'numeric'}, {'nonempty','nrows',3,'real','finite'}, 'TransformTrajSys','TimeScaling');
                validateattributes(obj.TimeScaling(1,:), {'numeric'}, {'>=', 0, '<=', 1}, 'TransformTrajSys','TimeScaling(1,:)');
            end
        end

        function [T0, TF, timeInterval, timeScalingTimeVec, timeScaling] = getAndValidateInputs(obj, evalTime, varargs, validateItemsOn)
        %getFunctionInputs Map properties and inputs to stepImpl inputs
        %   Since numerous inputs can be properties or block inputs,
        %   this function is required to implement this mapping.

        % Waypoints may be internal or external
            if strcmp(obj.WaypointSource, "Internal")
                T0 = obj.T0; %#ok<*PROPLC>
                TF = obj.TF; %#ok<*PROPLC>
                timeInterval = obj.TimeInterval;
                inputOffsetNum = 0;
            else
                T0 = varargs{1};
                TF = varargs{2};
                timeInterval = varargs{3};
                inputOffsetNum = 3;
            end

            % Pass argument by input case.
            if obj.CustomTimeScaling
                % Get the time scaling time vector and custom time scaling.
                % The parameters may be internal or external
                if strcmp(obj.ParameterSource, "Internal")
                    timeScalingTimeVec = obj.TSTime;
                    timeScaling = obj.TimeScaling;
                else
                    timeScalingTimeVec = varargs{inputOffsetNum+1};
                    timeScaling = varargs{inputOffsetNum+2};
                end
            else
                % Output dummy variables of minimal size
                timeScalingTimeVec = 0:1;
                timeScaling = zeros(3, 2);
            end

            if validateItemsOn
                % Validate inputs
                validateattributes(evalTime, {'numeric'}, {'nonempty','vector','real','finite','increasing','nonnegative'}, 'TransformTrajSys','time');

                % Parameters
                if strcmp(obj.CustomTimeScaling, 'on')
                    validateattributes(timeScaling, {'numeric'}, {'nonempty','nrows',3,'real','finite'}, 'TransformTrajSys','TimeScaling');
                    validateattributes(timeScaling(1,:), {'numeric'}, {'>=', 0, '<=', 1}, 'TransformTrajSys','TimeScaling(1,:)');
                    coder.internal.errorIf(size(timeScaling,2) ~= numel(tsTime), 'shared_robotics:robotcore:utils:RotTrajTimeScalingLength');
                end
            end
        end

        function num = getNumInputsImpl(obj)
        %getNumInputsImpl Define total number of inputs for system with optional inputs

            num = 1;

            if strcmp(obj.WaypointSource, "External")
                num = num + 3;
            end

            if strcmp(obj.ParameterSource, "External") && obj.CustomTimeScaling
                num = num + 2;
            end
        end

        function flag = isInputSizeMutableImpl(~,~)
        %isInputSizeMutableImpl Allow input to be variable-dimension signals
            flag = true;
        end

        function icon = getIconImpl(~)
        %getIconImpl Define icon for System block
            filepath = fullfile(matlabroot, 'toolbox', 'shared', 'robotics', 'robotslcore', 'blockicons', 'TransformTrajectoryIcon.dvg');
            icon = matlab.system.display.Icon(filepath);
        end

        function varargout = getInputNamesImpl(obj)
        %getInputNamesImpl Return input port names for System block

            varargout = {'Time'};

            if strcmp(obj.WaypointSource, "External")
                varargout = [varargout {'T0', 'TF', 'TimeInterval'}];
            end

            if strcmp(obj.ParameterSource, "External")
                varargout = [varargout {'TSTime', 'TimeScaling'}];
            end
        end

        function [out1,out2,out3] = getOutputSizeImpl(obj)
        %getOutputSizeImpl Return size for each output port

        % Number of instants in time is dependent on time vector
            s1 = propagatedInputSize(obj,1);
            m = max(s1);

            % Assign output sizes
            out1 = [4 4 m];
            out2 = [6 m];
            out3 = [6 m];
        end

        function [out1,out2,out3] = getOutputDataTypeImpl(obj)
        %getOutputDataTypeImpl Return data type for each output port

        % Waypoint vector may be internal or external
            if strcmp(obj.WaypointSource, "External")
                outputType = propagatedInputDataType(obj,2);
            else
                outputType = class(obj.T0);
            end

            % Assign outputs
            out1 = outputType;
            out2 = outputType;
            out3 = outputType;
        end

        function [out1,out2,out3] = isOutputComplexImpl(~)
        %isOutputComplexImpl Return true for each output port with complex data

            out1 = false;
            out2 = false;
            out3 = false;
        end

        function [out1,out2,out3] = isOutputFixedSizeImpl(~)
        %isOutputFixedSizeImpl Return true for each output port with fixed size

            out1 = true;
            out2 = true;
            out3 = true;
        end
    end

    methods(Access = protected, Static)
        function header = getHeaderImpl
        %getHeaderImpl Define header panel for System block dialog
            header = matlab.system.display.Header(mfilename("class"),...
                                                  'Title', message('shared_robotics:robotslcore:trajectorygeneration:TransformTrajTitle').getString, ...
                                                  'Text', message('shared_robotics:robotslcore:trajectorygeneration:TransformTrajDescription').getString, ...
                                                  'ShowSourceLink', false);
        end

        function groups = getPropertyGroupsImpl
        %getPropertyGroupsImpl Define property grouping in System block dialog

        % Section titles and descriptions
            WaypointInputSectionName = message('shared_robotics:robotslcore:trajectorygeneration:WaypointsSectionTitle').getString;
            ParameterInputSectionName = message('shared_robotics:robotslcore:trajectorygeneration:ParametersSectionTitle').getString;

            % Properties associated with waypoints section
            propWaypointSource = matlab.system.display.internal.Property('WaypointSource','Description',getString(message('shared_robotics:robotslcore:trajectorygeneration:WaypointSourcePrompt')));
            propT0 = matlab.system.display.internal.Property('T0','Description',getString(message('shared_robotics:robotslcore:trajectorygeneration:TransformTrajT0Prompt')));
            propTF = matlab.system.display.internal.Property('TF','Description',getString(message('shared_robotics:robotslcore:trajectorygeneration:TransformTrajTFPrompt')));
            propTimeInterval = matlab.system.display.internal.Property('TimeInterval','Description',getString(message('shared_robotics:robotslcore:trajectorygeneration:TimeIntervalPrompt')));

            % Properties associated with time scaling
            propCustomTimeScaling = matlab.system.display.internal.Property('CustomTimeScaling','Description',getString(message('shared_robotics:robotslcore:trajectorygeneration:CustomTimeScalingPrompt')));
            propParameterSource = matlab.system.display.internal.Property('ParameterSource','Description',getString(message('shared_robotics:robotslcore:trajectorygeneration:ParameterSourcePrompt')));
            propTSTime = matlab.system.display.internal.Property('TSTime','Description',getString(message('shared_robotics:robotslcore:trajectorygeneration:CustomTimeScalingTimePrompt')));
            propTimeScaling = matlab.system.display.internal.Property('TimeScaling','Description',getString(message('shared_robotics:robotslcore:trajectorygeneration:CustomTimeScalingValuesPrompt')));

            waypointProps = matlab.system.display.Section( ...
                'Title', WaypointInputSectionName, ...
                'PropertyList', {propWaypointSource, propT0, propTF, propTimeInterval});

            inputProps = matlab.system.display.Section( ...
                'Title', ParameterInputSectionName, ...
                'PropertyList', { ...
                    propCustomTimeScaling, propParameterSource, ...
                    propTSTime,propTimeScaling});

            groups = [waypointProps inputProps];
        end
    end
end
