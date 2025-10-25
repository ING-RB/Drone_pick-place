classdef PolyTrajSys < matlab.System
% Generate trajectories through multiple waypoints

% Copyright 2018-2024 The MathWorks, Inc.

%#codegen

    properties (Nontunable)
        %Method
        %   Polynomial variety
        Method = message("shared_robotics:robotslcore:trajectorygeneration:PolynomialCubicPopup").getString

        %Waypoint Source
        %   Waypoint Source
        WaypointSource = message("shared_robotics:robotslcore:trajectorygeneration:SourceInternalPopup").getString

        %Parameter Source
        ParameterSource = message("shared_robotics:robotslcore:trajectorygeneration:SourceInternalPopup").getString
    end

    properties (Constant, Hidden)
        % String set for Method
        MethodSet = matlab.system.StringSet({...
                                              message("shared_robotics:robotslcore:trajectorygeneration:PolynomialCubicPopup").getString, ...
                                              message("shared_robotics:robotslcore:trajectorygeneration:PolynomialQuinticPopup").getString, ...
                                              message("shared_robotics:robotslcore:trajectorygeneration:PolynomialBSplinePopup").getString, ...
                                            })

        % String set for Source
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
        %Waypoints
        Waypoints = [ 0 2 1 5 0; -1 3 1 4 4]

        %Time Points
        TimePoints = [0 1 2 3 4];

        %Time Interval
        TimeInterval = [1 4];

        %Velocity Boundary Conditions
        VelocityBoundaryCondition = zeros(2,5);

        %Acceleration Boundary Conditions
        AccelerationBoundaryCondition = zeros(2,5);

    end

    properties(DiscreteState)

    end

    properties(Access = private)

        %PPCell Cell array of position pp-forms
        PPStruct

        %PPDCell Cell array of velocity pp-forms
        PPDStruct

        %PPDDCell Cell array of acceleration pp-forms
        PPDDStruct

        %PrevOptInputs Previous optional inputs (inputs excl time)
        PrevOptInputs = {}

        %PPFormUpdatedNeeded Flag indicating that a PP-Form update is required
        PPFormUpdatedNeeded = false
    end

    properties (Dependent, Access = private)
        %HasInternalWptSource Returns true when waypoints are specified as properties, not external inputs
        HasInternalWptSource

        %HasInternalParamSource Returns true when parameters are specified as properties, not external inputs
        HasInternalParamSource

        %NumWaypointDimensions Number of elements in each waypoint
        NumWaypointElements

        %NumWaypoints Number of waypoints
        NumWaypoints
    end

    methods
        function isInternallyDefined = get.HasInternalWptSource(obj)
            isInternallyDefined = strcmp(obj.WaypointSource, "Internal");
        end

        function isInternallyDefined = get.HasInternalParamSource(obj)
            isInternallyDefined = strcmp(obj.ParameterSource, "Internal");
        end

        function n = get.NumWaypointElements(obj)
        %get.NumWaypointDimensions Waypoints are an N x P matrix of P waypoints with dimension N

            if obj.HasInternalWptSource
                n = size(obj.Waypoints,1);
            else
                wptSize = propagatedInputSize(obj,2);
                n = wptSize(1);
            end
        end

        function p = get.NumWaypoints(obj)
        %get.NumWaypointDimensions Waypoints are an N x P matrix of P waypoints with dimension N

            if obj.HasInternalWptSource
                p = size(obj.Waypoints,2);
            else
                wptSize = propagatedInputSize(obj,2);
                p = wptSize(2);
            end
        end
    end

    methods(Access = protected)
        function propArray = getMethodProps(obj)
        %getMethodProps method to get list of properties associated with each trajectory Method

            switch obj.Method
              case 'B-Spline'
                propArray = {};
              case 'Cubic Polynomial'
                propArray = {'VelocityBoundaryCondition'};
              case 'Quintic Polynomial'
                propArray = {'VelocityBoundaryCondition' 'AccelerationBoundaryCondition'};
            end
        end

        function inputNameArray = getMethodInputs(obj)
        %getMethodInputs method to get list of inputs associated with each trajectory Method

            switch obj.Method
              case 'B-Spline'
                inputNameArray = {};
              case 'Cubic Polynomial'
                inputNameArray = {'VelBC'};
              case 'Quintic Polynomial'
                inputNameArray = {'VelBC' 'AccelBC'};
            end
        end

        function setupImpl(obj)
        %setupImpl Perform one-time calculations, such as computing constants
        %   At the start, the piecewise polynomial is computed. This occurs
        %   again later but only when properties or inputs change.

            obj.initializePrevInputs();
            obj.initializePPFormStructs();
        end

        function [q, qd, qdd] = stepImpl(obj, time, varargin)
        %stepImpl Implement algorithm.
        %   Compute outputs as a function of waypoints, timepoints,
        %   time, and the boundary conditions.

            obj.updatePPFormsGivenExternalInputs(varargin);

            % Compute outputs at the times specified by the "time" input,
            % which may be either a vector or a scalar instant in time.
            q = ppval(obj.PPStruct, time);

            vaEvalTime = obj.processTimeForDiscontinuousOutputs(time);
            qd = ppval(obj.PPDStruct, vaEvalTime);
            qdd = ppval(obj.PPDDStruct, vaEvalTime);
        end

        function resetImpl(~)
        %resetImpl Initialize / reset discrete-state properties
        end

        function validatePropertiesImpl(obj)
        % Validate related or interdependent property values
            if strcmp(obj.WaypointSource, 'Internal')
                validateattributes(obj.Waypoints, {'numeric'}, {'2d','nonempty','real','finite'}, 'PolyTrajSys','wayPoints');
                if strcmp(obj.Method, 'B-Spline')
                    validateattributes(obj.TimeInterval, {'numeric'}, {'nonempty','vector','real','finite','increasing','nonnegative'}, 'PolyTrajSys','timePoints');
                    coder.internal.errorIf((size(obj.Waypoints,2) < 4), 'shared_robotics:robotcore:utils:TooFewControlPoints');
                    coder.internal.errorIf((numel(obj.TimeInterval) < 2), 'shared_robotics:robotcore:utils:TimePointsSizeError');
                else
                    validateattributes(obj.TimePoints, {'numeric'}, {'nonempty','vector','real','finite','increasing','nonnegative'}, 'PolyTrajSys','timePoints');
                    coder.internal.errorIf((numel(obj.TimePoints) < 2), 'shared_robotics:robotcore:utils:TimePointsSizeError');
                    coder.internal.errorIf((numel(obj.TimePoints) ~= size(obj.Waypoints,2)), 'shared_robotics:robotcore:utils:WayPointMismatch');
                end
            end

            % Validate parameter dimensions against waypoint dimensions.
            % This can only be checked if both are internal, since external
            % dimensions are unknown at the time this method is called (in
            % the block mask).
            if (strcmp(obj.WaypointSource, 'Internal') && strcmp(obj.ParameterSource, 'Internal') && ~strcmp(obj.Method, 'B-Spline'))
                coder.internal.errorIf(size(obj.VelocityBoundaryCondition,1) ~= size(obj.Waypoints,1) || size(obj.VelocityBoundaryCondition,2) ~= size(obj.Waypoints,2), 'shared_robotics:robotcore:utils:WaypointVelocityBCDimensionMismatch');
                if strcmp(obj.Method, 'Quintic Polynomial')
                    coder.internal.errorIf(size(obj.AccelerationBoundaryCondition,1) ~= size(obj.Waypoints,1) || ...
                                           size(obj.AccelerationBoundaryCondition,2) ~= size(obj.Waypoints,2), ...
                                           'shared_robotics:robotcore:utils:WaypointAccelerationBCDimensionMismatch');
                end
            end
        end

        function processTunedPropertiesImpl(obj)
        %processTunedPropertiesImpl Perform actions when tunable properties change between calls to the System object

        % Check if a property change is detected
            propChange = false;
            if obj.HasInternalWptSource
                propChange = isChangedProperty(obj,'Waypoints') || ...
                    isChangedProperty(obj,'TimePoints') || ...
                    isChangedProperty(obj,'TimeInterval');
            end

            % Only check again if one has not yet been detected
            if ~propChange && obj.HasInternalParamSource
                propChange = isChangedProperty(obj,'VelocityBoundaryCondition') || ...
                    isChangedProperty(obj,'AccelerationBoundaryCondition');
            end

            % Update the stored flag
            obj.PPFormUpdatedNeeded = propChange;

            % If all waypoints are internally sourced, the change can be made now
            if obj.PPFormUpdatedNeeded && obj.HasInternalWptSource && obj.HasInternalParamSource
                formattedWaypoints = obj.processWaypoints(obj.Waypoints);
                timeData = obj.getTimePropValue();
                obj.regeneratePPFormFromProperty(formattedWaypoints, timeData);
            end
        end

        function flag = isInactivePropertyImpl(obj,prop)
        %isInactivePropertyImpl Identify inactive properties
        %   Return false if property is visible based on object
        %   configuration, for the command line and System block dialog

            if strcmp(obj.ParameterSource, 'Internal')
                methodProps = obj.getMethodProps;
            else
                methodProps = {};
            end

            if ~strcmp(obj.Method, 'B-Spline')
                methodProps = [methodProps {'ParameterSource'}];
            end

            if strcmp(obj.WaypointSource, "Internal")
                props = [{'Method', 'WaypointSource', 'Waypoints'} obj.getTimePropName methodProps];
            else
                props = [{'Method', 'WaypointSource'} methodProps];
            end

            flag = ~ismember(prop, props);
        end

        function validateInputsImpl(obj,time,varargin)
        % Validate inputs to the step method at initialization
        %   Since the inputs at initialization do not have value, these
        %   checks simply establish size matching

            validateattributes(time, {'numeric'}, {'nonempty', 'vector'}, 'PolyTrajSys', 'Time');

            [waypoints, timePoints, inputOffsetNum] = getSharedInputs(obj, varargin);
            validateattributes(waypoints, {'numeric'}, {'2d','nonempty'}, 'PolyTrajSys','wayPoints');
            coder.internal.errorIf((numel(timePoints) < 2), 'shared_robotics:robotcore:utils:TimePointsSizeError');

            if strcmp(obj.Method, 'B-Spline')
                validateattributes(timePoints, {'numeric'}, {'nonempty','vector'}, 'PolyTrajSys','timePoints');
                coder.internal.errorIf((size(waypoints,2) < 4), 'shared_robotics:robotcore:utils:TooFewControlPoints');
            else
                validateattributes(timePoints, {'numeric'}, {'nonempty','vector'}, 'PolyTrajSys','timePoints');
                coder.internal.errorIf((numel(timePoints) ~= size(waypoints,2)), 'shared_robotics:robotcore:utils:WayPointMismatch');

                % Boundary conditions
                [velBounds] = obj.getPolynomialBC(varargin, inputOffsetNum);
                coder.internal.errorIf(size(velBounds,1) ~= size(waypoints,1) || size(velBounds,2) ~= size(waypoints,2), 'shared_robotics:robotcore:utils:WaypointVelocityBCDimensionMismatch');
                if strcmp(obj.Method, 'Quintic Polynomial')
                    [~, accBounds] = obj.getPolynomialBC(varargin, inputOffsetNum);
                    coder.internal.errorIf(size(accBounds,1) ~= size(waypoints,1) || size(accBounds,2) ~= size(waypoints,2), 'shared_robotics:robotcore:utils:WaypointAccelerationBCDimensionMismatch');
                end
            end


        end

        function num = getNumInputsImpl(obj)
        %getNumInputsImpl Define total number of inputs for system with optional inputs

            num = 1;
            if strcmp(obj.WaypointSource, "External")
                num = num + 2;
            end

            if strcmp(obj.ParameterSource, "External")
                num = num + length(obj.getMethodInputs);
            end
        end

        function num = getNumOutputsImpl(~)
        %getNumOutputsImpl Define total number of outputs for system with optional outputs
            num = 3;
        end

        function loadObjectImpl(obj,s,wasLocked)
        % Set properties in object obj to values in structure s

        % Set private and protected properties
            obj.PPStruct = s.PPCell;
            obj.PPDStruct = s.PPDCell;
            obj.PPDDStruct = s.PPDDCell;
            obj.PrevOptInputs = s.PrevOptInputs;
            obj.PPFormUpdatedNeeded = s.PPFormUpdatedNeeded;

            % Set public properties and states
            loadObjectImpl@matlab.System(obj,s,wasLocked);
        end

        function s = saveObjectImpl(obj)
        % Set properties in structure s to values in object obj

        % Set public properties and states
            s = saveObjectImpl@matlab.System(obj);

            % Set private and protected properties
            s.PPStruct = obj.PPStruct;
            s.PPDStruct = obj.PPDStruct;
            s.PPDDStruct = obj.PPDDStruct;
            s.PrevOptInputs = obj.PrevOptInputs;
            s.PPFormUpdatedNeeded = obj.PPFormUpdatedNeeded;
        end

        function flag = isInputSizeMutableImpl(~,~)
        %isInputSizeMutableImpl Allow input to be variable-dimension signals
            flag = true;
        end

        function icon = getIconImpl(obj)
        %getIconImpl Define icon for System block
            if strcmp(obj.Method, 'B-Spline')
                filepath = fullfile(matlabroot, 'toolbox', 'shared', 'robotics', 'robotslcore', 'blockicons', 'BSplineIcon.dvg');
            else
                filepath = fullfile(matlabroot, 'toolbox', 'shared', 'robotics', 'robotslcore', 'blockicons', 'CubicPolynomialIcon.dvg');
            end
            icon = matlab.system.display.Icon(filepath);
        end

        function varargout = getInputNamesImpl(obj)
        %getInputNamesImpl Return input port names for System block

            varargout = {'Time'};
            if strcmp(obj.WaypointSource, "External")
                varargout = [varargout {'Waypoints',obj.getTimePropName}];
            end

            if strcmp(obj.ParameterSource, "External")
                varargout = [varargout obj.getMethodInputs];
            end
        end

        function [out,out2,out3] = getOutputSizeImpl(obj)
        %getOutputSizeImpl Return size for each output port

        % Dimension of the output is propagated from waypoints
            if strcmp(obj.WaypointSource, "Internal")
                n = size(obj.Waypoints,1);
            else
                sz = propagatedInputSize(obj,2);
                if any(sz == 1)
                    % Row and column vectors are both propagated as 1x6, so
                    % it is necessary to force the edge case where the user
                    % passes a row vector. The opposite case, where they
                    % provide a column, is technically unsupported.
                    n = 1;
                else
                    n = sz(1);
                end
            end

            timeSize = max(propagatedInputSize(obj,1));
            out = [n timeSize];
            out2 = [n timeSize];
            out3 = [n timeSize];
        end

        function [out,out2,out3] = getOutputDataTypeImpl(obj)
        %getOutputDataTypeImpl Return data type for each output port

        % Propagate data type from the waypoints, which may be
        % specified internally or externally
            if strcmp(obj.WaypointSource, "Internal")
                out = class(obj.Waypoints);
                out2 = class(obj.Waypoints);
                out3 = class(obj.Waypoints);
            else
                out = propagatedInputDataType(obj,2);
                out2 = propagatedInputDataType(obj,2);
                out3 = propagatedInputDataType(obj,2);
            end
        end

        function [out,out2,out3] = isOutputComplexImpl(~)
        % Return true for each output port with complex data
            out = false;
            out2 = false;
            out3 = false;
        end

        function [out,out2,out3] = isOutputFixedSizeImpl(~)
        %isOutputFixedSizeImpl Return true for each output port with fixed size
            out = true;
            out2 = true;
            out3 = true;
        end

        function [velBounds, accBounds] = getPolynomialBC(obj, argsIn, inputOffsetNum)
        %getPolynomialBC Get boundary conditions

        % Parameters may be internal or external
            if strcmp(obj.ParameterSource, "External")
                velBounds = argsIn{inputOffsetNum + 1};
                if strcmp(obj.Method, 'Quintic Polynomial')
                    accBounds = argsIn{inputOffsetNum + 2};
                end
            else
                velBounds = obj.VelocityBoundaryCondition;
                accBounds = obj.AccelerationBoundaryCondition;
            end
        end

        function timeProperty = getTimePropName(obj)
        %getTimePropName Get the name of the property used to represent time intervals

            if strcmp(obj.Method, 'B-Spline')
                timeProperty = 'TimeInterval';
            else
                timeProperty = 'TimePoints';
            end
        end

        function timePropValue = getTimePropValue(obj)
            if strcmp(obj.Method, 'B-Spline')
                timePropValue = obj.TimeInterval;
            else
                timePropValue = obj.TimePoints;
            end
        end

        function [formattedWaypoints, timePoints, inputOffsetNum] = getSharedInputs(obj, argsIn)
        %getSharedInputs Get waypoints and timePoints OR timeInterval

        % Waypoints and timepoints may be internal or external
            if strcmp(obj.WaypointSource, "Internal")
                waypoints = obj.Waypoints;
                timePoints = obj.getTimePropValue;
                inputOffsetNum = 0;
            else
                waypoints = argsIn{1};
                timePoints = argsIn{2};
                inputOffsetNum = 2;
            end

            if isvector(waypoints)
                %Since some Simulink blocks convert row vectors to column
                %vector inputs, convert all vector inputs to rows
                formattedWaypoints = waypoints(:)';
            else
                formattedWaypoints = waypoints;
            end
        end

        function formattedWaypoints = processWaypoints(~, waypoints)

            if isvector(waypoints)
                %Since some Simulink blocks convert row vectors to column
                %vector inputs, convert all vector inputs to rows
                formattedWaypoints = waypoints(:)';
            else
                formattedWaypoints = waypoints;
            end

        end

        function [ppd, ppdd] = updateStoredPPForms(obj, pp)
        %updateStoredPPForms Update stored values of PP-Form and its derivatives

        % Get breaks, coefficients, and dimensions of the original pp-form
            [oldBreaks, oldCoeffs, ~, ~, dim] = unmkpp(pp);

            % Initialize new coefficient matrix
            dCoefs = robotics.core.internal.polyCoeffsDerivative(oldCoeffs);
            ddCoefs = robotics.core.internal.polyCoeffsDerivative(dCoefs);

            % Construct new polynomial forms
            ppd = mkpp(oldBreaks, dCoefs, dim);
            ppdd = mkpp(oldBreaks, ddCoefs, dim);

            % Update stored properties
            obj.PPStruct = pp;
            obj.PPDStruct = ppd;
            obj.PPDDStruct = ppdd;
        end
    end

    methods (Access = private)

        function newTime = processTimeForDiscontinuousOutputs(obj, time)
        %processTimeForDiscontinuousOutputs Modify the time vector used to evaluate velocity and acceleration, which are not continuous
        %   The velocity and acceleration outputs are not necessarily
        %   continuous at the end. When they are not, the values are
        %   define for the closed interval [minTime maxTime]. However,
        %   the pp-form produces an open interval, such that the final
        %   values are incorrectly represented. To fix this, whenever
        %   the velocity and acceleration are evaluated at the max time
        %   value, instead evaluate at a value just inside the
        %   interval.


            if strcmp(obj.Method, 'B-Spline')
                newTime = time;
            else

                % Process "time" variable so that any values that fall on the
                % last interval are processed as being inside the interval
                lastIntervalMaxValue = obj.PPStruct.breaks(end-1);
                timeValuesAtBound = time == lastIntervalMaxValue;

                newTime = time;
                newTime(timeValuesAtBound) = lastIntervalMaxValue - 10*eps;
            end
        end

        function updatePPFormsGivenExternalInputs(obj, externalInputsCellArray)
        %updatePPFormsGivenExternalInputs Update PP-Forms when external inputs change
        %   When the waypoints or parameters are external inputs, the
        %   PP-forms have to be regenerated any time these inputs are
        %   changed.

            if obj.PPFormUpdatedNeeded || obj.haveInputsChanged(externalInputsCellArray)
                % All conditions here require inputs to have changed. While
                % this check can be expensive, it's only so when parameters
                % are externally sourced (and big), which is the exact
                % condition that warrants changed, so it's always necessary
                % in these conditions. When parameters are internally
                % sourced, the check is always cheap.

                if (~obj.HasInternalWptSource) && (obj.HasInternalParamSource)
                    % External waypoints and internal parameters
                    formattedWaypoints = obj.processWaypoints(externalInputsCellArray{1});
                    timePoints = externalInputsCellArray{2};
                    obj.regeneratePPFormFromProperty(formattedWaypoints, timePoints);
                elseif (obj.HasInternalWptSource) && (~obj.HasInternalParamSource)
                    % Internal waypoints and external parameters
                    formattedWaypoints = obj.processWaypoints(obj.Waypoints);
                    timePoints = obj.getTimePropValue();
                    paramInputArgs = externalInputsCellArray;
                    obj.regeneratePPFormFromInputs(formattedWaypoints, timePoints, paramInputArgs);
                elseif (~obj.HasInternalWptSource) && (~obj.HasInternalParamSource)
                    % External waypoints and external parameters
                    formattedWaypoints = obj.processWaypoints(externalInputsCellArray{1});
                    timePoints = externalInputsCellArray{2};
                    paramInputArgs = {externalInputsCellArray{3:end}};
                    obj.regeneratePPFormFromInputs(formattedWaypoints, timePoints, paramInputArgs);
                end
            end
        end

        function regeneratePPFormFromProperty(obj, waypoints, timeData)
        %regeneratePPFormFromProperty Regenerate PP Forms when parameter inputs are all internal

        % Compute the terms using a minimal time vector since the
        % coefficients are all we actually want
            switch obj.Method
              case 'Cubic Polynomial'
                [ ~, ~, ~, pp] = cubicpolytraj(waypoints, timeData, timeData, ...
                                               'VelocityBoundaryCondition', obj.VelocityBoundaryCondition);
              case 'Quintic Polynomial'
                [ ~, ~, ~, pp] = quinticpolytraj(waypoints, timeData, timeData, ...
                                                 'VelocityBoundaryCondition', obj.VelocityBoundaryCondition, ...
                                                 'AccelerationBoundaryCondition', obj.AccelerationBoundaryCondition);
              case 'B-Spline'
                [ ~, ~, ~, pp] = bsplinepolytraj(waypoints, [timeData(1) timeData(end)], 1);
            end

            % Compute the derivatives
            obj.updateStoredPPForms(pp);

            % Reset the flag
            obj.PPFormUpdatedNeeded = false;
        end

        function regeneratePPFormFromInputs(obj, waypoints, timeData, paramInputArgs)
        %regeneratePPFormFromInputs Regenerate PP-Forms when parameters are external inputs

        % Compute the terms using a minimal time vector since the
        % coefficients are all we actually want
            switch obj.Method
              case 'Cubic Polynomial'
                [ ~, ~, ~, pp] = cubicpolytraj(waypoints, timeData, timeData, ...
                                               'VelocityBoundaryCondition', paramInputArgs{1});
              case 'Quintic Polynomial'
                [ ~, ~, ~, pp] = quinticpolytraj(waypoints, timeData, timeData, ...
                                                 'VelocityBoundaryCondition', paramInputArgs{1}, ...
                                                 'AccelerationBoundaryCondition', paramInputArgs{2});
              case 'B-Spline'
                [ ~, ~, ~, pp] = bsplinepolytraj(waypoints, [timeData(1) timeData(end)], 1);
            end

            % Compute the derivatives
            obj.updateStoredPPForms(pp);

            % Reset the flag
            obj.PPFormUpdatedNeeded = false;
        end

        function initializePPFormStructs(obj)
        %initializePPFormStructs Initialize the properties that contain the pp-forms

            if obj.HasInternalWptSource
                placeholderWpts = obj.processWaypoints(obj.Waypoints);
                placeholderTimeData = obj.getTimePropValue();
            else
                placeholderWpts = ones(obj.NumWaypointElements, obj.NumWaypoints);
                placeholderTimeData = 1:obj.NumWaypoints;
            end

            if obj.HasInternalParamSource
                obj.regeneratePPFormFromProperty(placeholderWpts, placeholderTimeData);
            else
                % If either waypoints or parameters are external, the
                % piecewise polynomials will anyway be recomputed in the
                % first call to stepImpl, so this call just initializes the
                % properties
                switch obj.Method
                  case 'Cubic Polynomial'
                    [ ~, ~, ~, placeholderPP] = cubicpolytraj(placeholderWpts, placeholderTimeData, 1);
                  case 'Quintic Polynomial'
                    [ ~, ~, ~, placeholderPP] = quinticpolytraj(placeholderWpts, placeholderTimeData, 1);
                  case 'B-Spline'
                    [ ~, ~, ~, placeholderPP] = bsplinepolytraj(placeholderWpts, [placeholderTimeData(1) placeholderTimeData(end)], 1);
                end
                obj.updateStoredPPForms(placeholderPP);
            end

        end

        function initializePrevInputs(obj)
        %initializePrevInputs Define stored prior inputs cell array
        %   For codegen, the previous inputs must be initialized to a
        %   cell array of the same size as the actual number of inputs.
        %   This is dependent on the block configuration.

            numOptionalInputs = obj.getNumInputsImpl-1;
            if numOptionalInputs == 0
                prevInputArray = cell(0,0);
            else
                prevInputArray = cell(1, numOptionalInputs);
            end

            for inputIdx = 1:numOptionalInputs
                inputSize = propagatedInputSize(obj,inputIdx+1);
                prevInputArray{inputIdx} = ones(inputSize);
            end

            obj.PrevOptInputs = prevInputArray;
        end

        function haveChanged = haveInputsChanged(obj, inputArgsCell)
        %haveInputsChanged Returns true if inputs have changed since last step

            haveChanged = ~isequal(inputArgsCell, obj.PrevOptInputs);
            obj.PrevOptInputs = inputArgsCell;

        end
    end

    methods(Access = protected, Static)
        %% Static custom helper methods

        function header = getHeaderImpl
        %getHeaderImpl Define header panel for System block dialog
            header = matlab.system.display.Header(mfilename("class"),...
                                                  'Title',message('shared_robotics:robotslcore:trajectorygeneration:PolynomialTitle').getString, ...
                                                  'Text', message('shared_robotics:robotslcore:trajectorygeneration:PolynomialDescription').getString, ...
                                                  'ShowSourceLink', false);
        end

        function groups = getPropertyGroupsImpl
        %getPropertyGroupsImpl Define property groups in mask

        % Section titles and descriptions
            WaypointInputSectionName = message('shared_robotics:robotslcore:trajectorygeneration:WaypointsSectionTitle').getString;
            ParameterInputSectionName = message('shared_robotics:robotslcore:trajectorygeneration:ParametersSectionTitle').getString;

            % Properties associated with waypoints section
            propWaypointSource = matlab.system.display.internal.Property('WaypointSource','Description',getString(message('shared_robotics:robotslcore:trajectorygeneration:WaypointSourcePrompt')));
            propWaypoints = matlab.system.display.internal.Property('Waypoints','Description',getString(message('shared_robotics:robotslcore:trajectorygeneration:WaypointsPrompt')));
            propTimePoints = matlab.system.display.internal.Property('TimePoints','Description',getString(message('shared_robotics:robotslcore:trajectorygeneration:TimePointsPrompt')));
            propTimeInterval = matlab.system.display.internal.Property('TimeInterval','Description',getString(message('shared_robotics:robotslcore:trajectorygeneration:TimeIntervalPrompt')));

            % Properties associated with time scaling
            propParameterSource = matlab.system.display.internal.Property('ParameterSource','Description',getString(message('shared_robotics:robotslcore:trajectorygeneration:ParameterSourcePrompt')));
            propMethod = matlab.system.display.internal.Property('Method','Description',getString(message('shared_robotics:robotslcore:trajectorygeneration:PolynomialMethodPrompt')));
            propVelocityBoundaryCondition = matlab.system.display.internal.Property('VelocityBoundaryCondition','Description',getString(message('shared_robotics:robotslcore:trajectorygeneration:PolynomialVelocityBCPrompt')));
            propAccelerationBoundaryCondition = matlab.system.display.internal.Property('AccelerationBoundaryCondition','Description',getString(message('shared_robotics:robotslcore:trajectorygeneration:PolynomialAccelerationBCPrompt')));

            waypointProps = matlab.system.display.Section( ...
                'Title', WaypointInputSectionName, ...
                'PropertyList', {propWaypointSource, propWaypoints, propTimePoints, propTimeInterval});

            inputProps = matlab.system.display.Section( ...
                'Title', ParameterInputSectionName, ...
                'PropertyList', {propMethod, propParameterSource, propVelocityBoundaryCondition, propAccelerationBoundaryCondition});

            groups = [waypointProps inputProps];
        end
    end
end

% LocalWords:  BSpline
