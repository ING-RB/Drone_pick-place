classdef TrapVelTrajSys < matlab.System
% Compute a trajectory between two vectors with a trapezoidal velocity profile

% Copyright 2018-2022 The MathWorks, Inc.

%#codegen

    properties (Nontunable)
        %Number of Parameters
        %   Users may specify up to two parameter inputs. The total number
        %   of parameters is specified by this dropdown.
        NumParams = "0";

        %Parameter 1
        %   Users may specify up to two inputs. If they wish to have the
        %   inputs be free and use default solutions, they may specify
        %   "free" as an option.
        Parameter1 = message("shared_robotics:robotslcore:trajectorygeneration:TrapVelTrajPeakVelocityPopup").getString

        %Parameter 2
        %   Users may specify up to two inputs. If they wish to have the
        %   inputs be free and use default solutions, they may specify
        %   "free" as an option.
        Parameter2 = message("shared_robotics:robotslcore:trajectorygeneration:TrapVelTrajEndTimePopup").getString

        %Waypoint Source
        %   Waypoint Source
        WaypointSource = message("shared_robotics:robotslcore:trajectorygeneration:SourceInternalPopup").getString

        %Parameter Source
        ParameterSource = message("shared_robotics:robotslcore:trajectorygeneration:SourceInternalPopup").getString
    end

    properties (Constant, Hidden)
        % String set for Parameter1
        NumParamsSet = matlab.system.StringSet({...
            '0', ...
            '1', ...
            '2'})

        % String set for Parameter1
        Parameter1Set = matlab.system.StringSet({...
            message("shared_robotics:robotslcore:trajectorygeneration:TrapVelTrajPeakVelocityPopup").getString, ...
            message("shared_robotics:robotslcore:trajectorygeneration:TrapVelTrajAccelPopup").getString, ...
            message("shared_robotics:robotslcore:trajectorygeneration:TrapVelTrajEndTimePopup").getString, ...
            message("shared_robotics:robotslcore:trajectorygeneration:TrapVelTrajAccelTimePopup").getString, ...
            })

        % String set for Parameter2
        Parameter2Set = matlab.system.StringSet({...
            message("shared_robotics:robotslcore:trajectorygeneration:TrapVelTrajPeakVelocityPopup").getString, ...
            message("shared_robotics:robotslcore:trajectorygeneration:TrapVelTrajAccelPopup").getString, ...
            message("shared_robotics:robotslcore:trajectorygeneration:TrapVelTrajEndTimePopup").getString, ...
            message("shared_robotics:robotslcore:trajectorygeneration:TrapVelTrajAccelTimePopup").getString, ...
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
        Waypoints = [0 -0.5 -1; 0 0.5 1]

        %Peak Velocity
        PeakVelocity = [2; 2]

        %Acceleration
        Acceleration = [1; 2];

        %End Time
        EndTime = [1; 1]

        %Acceleration Time
        AccelTime = [1; 2];
    end

    properties (DiscreteState)

    end

    properties(Access = private)

        %PPCell Cell array of position pp-forms
        PPCell

        %PPDCell Cell array of velocity pp-forms
        PPDCell

        %PPDDCell Cell array of acceleration pp-forms
        PPDDCell

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
        function isInternal = get.HasInternalWptSource(obj)
            isInternal = strcmp(obj.WaypointSource, "Internal");
        end

        function isInternal = get.HasInternalParamSource(obj)
            isInternal = strcmp(obj.ParameterSource, "Internal");
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
        %% System block methods
        function setupImpl(obj) 
        %setupImpl Perform one-time calculations, such as computing constants
        %   At the start, the piecewise polynomial is computed. This occurs
        %   again later but only when properties or inputs change.

            obj.initializePrevInputs();
            obj.initializePPFormCellArrays();
        end

        function [q, qd, qdd] = stepImpl(obj,time,varargin)
        %stepImpl Implement algorithm

            obj.updatePPFormsGivenExternalInputs(varargin);
            
            % Generate trajectories from the stored PP-Form
            [qArray, qdArray, qddArray] = obj.generateTrajectoriesFromPPForm(time);

            % Fit the generate trajectory values to the block outputs
            m = numel(time);
            n = obj.NumWaypointElements;
            q = zeros(n,m);
            qd = zeros(n,m);
            qdd = zeros(n,m);
            q(1:size(qArray,1),1:size(qArray,2)) = qArray;
            qd(1:size(qdArray,1),1:size(qdArray,2)) = qdArray;
            qdd(1:size(qddArray,1),1:size(qddArray,2)) = qddArray;

        end

        function resetImpl(~)
        %resetImpl Initialize / reset discrete-state properties
        end

        function validatePropertiesImpl(obj)
        %validatePropertiesImpl Validate related or interdependent property values
            if strcmp(obj.WaypointSource, 'Internal')
                validateattributes(obj.Waypoints, {'numeric'}, {'2d','nonempty','real','finite'}, 'TrapVelTrajSys','Waypoints');
            end

            if ~strcmp(obj.NumParams, '0')
                parameter1Name = obj.getParameterName(obj.Parameter1);
                validateattributes(obj.(parameter1Name), {'numeric'}, {'real', 'positive', 'finite', 'nonnan'}, 'TrapVelTrajSys', obj.Parameter1);
                if strcmp(obj.NumParams, '2')
                    parameter2Name = obj.getParameterName(obj.Parameter2);
                    validateattributes(obj.(parameter2Name), {'numeric'}, {'real', 'positive', 'finite', 'nonnan'}, 'TrapVelTrajSys', obj.Parameter2);
                end
            end
        end

        function processTunedPropertiesImpl(obj)
            %processTunedPropertiesImpl Perform actions when tunable properties change between calls to the System object


            % Check if a property change is detected
            propChange = false;
            if obj.HasInternalWptSource
                propChange = isChangedProperty(obj,'Waypoints');
            end

            % Only check again if one has not yet been detected
            if ~propChange && obj.HasInternalParamSource
                propChange = isChangedProperty(obj,'PeakVelocity') || ...
                    isChangedProperty(obj,'Acceleration') || ...
                    isChangedProperty(obj,'EndTime') || ...
                    isChangedProperty(obj,'AccelTime');
            end

            % Update the stored flag
            obj.PPFormUpdatedNeeded = propChange;

            % If all waypoints are internally sourced, the change can be made now
            if obj.PPFormUpdatedNeeded && obj.HasInternalWptSource && obj.HasInternalParamSource
                obj.regeneratePPFormFromProperty(obj.Waypoints);
            end
        end

        function flag = isInactivePropertyImpl(obj,prop)
        %isInactivePropertyImpl Control appearance of block mask labels with changing visibility
        % Return false if property is visible based on object
        % configuration, for the command line and System block dialog

        % Get the lists of parameter edit fields and parameter
        % selection popups to display on the block mask
            [paramSelectionPopups, paramEditFields] = obj.getTrapVelProps;

            % Only show the Waypoints field if the source is internal
            if strcmp(obj.WaypointSource, "Internal")
                waypointField = {'Waypoints'};
            else
                waypointField = {};
            end

            props = [paramEditFields paramSelectionPopups {'NumParams', 'WaypointSource'} waypointField];

            flag = ~ismember(prop, props);
        end

        function validateInputsImpl(obj,time,varargin)
        % Validate inputs to the step method at initialization
        %   Since the inputs at initialization do not have value, these
        %   checks simply establish size matching

            validateattributes(time, {'numeric'}, {'nonempty', 'vector'}, 'TrapVelTrajSys', 'Time');

            % Waypoints may be internal or external
            if strcmp(obj.WaypointSource, "Internal")
                waypoints = obj.Waypoints;
                argsOffset = 0;
            else
                waypoints = varargin{1};
                argsOffset = 1;
            end

            waypointSize = size(waypoints);

            % Parameters may be internal or external
            if ~strcmp(obj.NumParams, '0')
                if strcmp(obj.ParameterSource, 'Internal')
                    parameter1Name = obj.getParameterName(obj.Parameter1);
                    parameter1 = obj.(parameter1Name);
                else
                    parameter1 = varargin{argsOffset+1};
                end
                obj.validateParameterSize(waypointSize, parameter1, obj.Parameter1);
                if strcmp(obj.NumParams, '2')
                    if strcmp(obj.ParameterSource, 'Internal')
                        parameter2Name = obj.getParameterName(obj.Parameter1);
                        parameter2 = obj.(parameter2Name);
                    else
                        parameter2 = varargin{argsOffset+2};
                    end
                    obj.validateParameterSize(waypointSize, parameter2, obj.Parameter2);
                end
            end
        end

        function num = getNumInputsImpl(obj)
        %getNumInputsImpl Define total number of inputs for system with optional inputs

            num = 1;
            if strcmp(obj.WaypointSource, "External")
                num = num + 1;
            end

            if strcmp(obj.ParameterSource, "External")
                % With external parameters, the number of additional inputs
                % is dictated by the number of different parameters.
                num = num + obj.getNumUniqueParams;
            end
        end

        function loadObjectImpl(obj,s,wasLocked)
            % Set properties in object obj to values in structure s

            % Set private and protected properties
            obj.PPCell = s.PPCell;
            obj.PPDCell = s.PPDCell; 
            obj.PPDDCell = s.PPDDCell; 
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
            s.PPCell = obj.PPCell;
            s.PPDCell = obj.PPDCell; 
            s.PPDDCell = obj.PPDDCell; 
            s.PrevOptInputs = obj.PrevOptInputs; 
            s.PPFormUpdatedNeeded = obj.PPFormUpdatedNeeded; 
        end

        function flag = isInputSizeMutableImpl(~,~)
        %isInputSizeMutableImpl Disallow variable-dimension signals
        %   This isn't compatible with code generation

            flag = true;
        end

        function icon = getIconImpl(~)
        %getIconImpl Define icon for System block
            filepath = fullfile(matlabroot, 'toolbox', 'shared', 'robotics', 'robotslcore', 'blockicons', 'TrapezoidalVelocityProfileIcon.dvg');
            icon = matlab.system.display.Icon(filepath);
        end

        function varargout = getInputNamesImpl(obj)
        %getInputNamesImpl Return input port names for System block

            varargout = {'Time'};
            if strcmp(obj.WaypointSource, "External")
                varargout = [varargout {'Waypoints'}];
            end

            if strcmp(obj.ParameterSource, "External")
                varargout = [varargout obj.getTrapVelInputLabels];
            end

        end

        function [out1,out2,out3] = getOutputSizeImpl(obj)
        %getOutputSizeImpl Return size for each output port

        % Number of dimensions in waypoint vector may be internal or
        % external
            if strcmp(obj.WaypointSource, "External")
                s2 = propagatedInputSize(obj,2);
                n = s2(1);
            else
                n = size(obj.Waypoints,1);
            end

            % Number of instants in time is dependent on time vector
            s1 = propagatedInputSize(obj,1);
            m = max(s1);

            % Assign output sizes
            out1 = [n m];
            out2 = [n m];
            out3 = [n m];
        end

        function [out1,out2,out3] = getOutputDataTypeImpl(obj)
        %getOutputDataTypeImpl Return data type for each output port

        % Waypoint vector may be internal or external
            if strcmp(obj.WaypointSource, "External")
                outputType = propagatedInputDataType(obj,2);
            else
                outputType = class(obj.Waypoints);
            end

            % Assign outputs
            out1 = outputType;
            out2 = outputType;
            out3 = outputType;
        end

        function [out,out2,out3] = isOutputComplexImpl(obj) %#ok<MANU>
        %isOutputComplexImpl Return true for each output port with complex data

            out = false;
            out2 = false;
            out3 = false;
        end

        function [out1,out2,out3] = isOutputFixedSizeImpl(obj) %#ok<MANU>
        %isOutputFixedSizeImpl Return true for each output port with fixed size
            out1 = true;
            out2 = true;
            out3 = true;
        end

        %% Custom helper methods

        function inputLabelList = getTrapVelInputLabels(obj)
        %getTrapVelInputLabels Get block input labels
        %   The block input labels vary depending on the parameter
        %   selection. Additionally, since they are abbreviated
        %   versions (rather than exact copies of the properties), this
        %   function is used to generate the list of input labels.

        % Get the names of the items presently selected as parameter 1
        % and 2. Note that if only one parameter is being used, the
        % parameter2 property will still have a value
            fullPropNames = {obj.Parameter1 obj.Parameter2};

            % Select only the properties in use and map them to block input
            % labels based on a list
            numParams = obj.getNumUniqueParams;
            inputLabelList = cell(1,numParams);
            for i = 1:numParams
                switch fullPropNames{i}
                  case 'Peak Velocity'
                    inputLabelList{i} = 'PeakVel';
                  case 'Acceleration'
                    inputLabelList{i} = 'Accel';
                  case 'End Time'
                    inputLabelList{i} = 'EndTime';
                  case 'Acceleration Time'
                    inputLabelList{i} = 'AccelTime';
                end
            end
        end

        function [paramSelectionPopups, paramEditFields] = getTrapVelProps(obj)
        %getTrapVelProps Get parameter property list
        %   This method returns an array of property labels and
        %   parameter values to appear based on user selection. The
        %   propArray output is the Parameters to list for the user to
        %   specify, based on the "Number of parameters" selection,
        %   while the property list returns to corresponding properties
        %   to show in the property list given user selections for
        %   "Parameter1" and "Parameter2".

        % Determine what parameters to evaluate based on the number of options
            switch obj.NumParams
              case "0"
                paramSelectionPopups = {};
              case "1"
                paramSelectionPopups = {'ParameterSource', 'Parameter1'};
              case "2"
                paramSelectionPopups = {'ParameterSource', 'Parameter1', 'Parameter2'};
            end

            % Initialize parameter edit field list to empty
            paramEditFields = {};

            % Only show the parameter edit fields if the source is internal
            if strcmp(obj.ParameterSource, "Internal")

                % Only add the parameters if they are activated
                p1On = ~isempty(paramSelectionPopups);
                p2On = (numel(paramSelectionPopups) > 2);

                if (p1On && strcmp(obj.Parameter1, 'Peak Velocity')) || (p2On && strcmp(obj.Parameter2, 'Peak Velocity'))
                    paramEditFields = [paramEditFields {'PeakVelocity'}];
                end

                if (p1On && strcmp(obj.Parameter1, 'Acceleration')) || (p2On && strcmp(obj.Parameter2, 'Acceleration'))
                    paramEditFields = [paramEditFields {'Acceleration'}];
                end

                if (p1On && strcmp(obj.Parameter1, 'End Time')) || (p2On && strcmp(obj.Parameter2, 'End Time'))
                    paramEditFields = [paramEditFields {'EndTime'}];
                end

                if (p1On && strcmp(obj.Parameter1, 'Acceleration Time')) || (p2On && strcmp(obj.Parameter2, 'Acceleration Time'))
                    paramEditFields = [paramEditFields {'AccelTime'}];
                end
            end
        end

        function param = getParameter(obj, paramName)
        %getParameter Return the value of the name-value pair given the parameter name

            switch paramName
              case 'Peak Velocity'
                param = obj.PeakVelocity;
              case 'Acceleration'
                param = obj.Acceleration;
              case 'End Time'
                param = obj.EndTime;
              case 'Acceleration Time'
                param = obj.AccelTime;
            end
        end

        function numParams = getNumUniqueParams(obj)
        %getNumUniqueParams Return the number of different parameters selected by the user
        %   Since str2num is not supported for codegen, it is necessary
        %   to manually convert between the string values "0"-"2" and
        %   their numeric equivalents. In the special case of 2
        %   parameters, the number of unique parameters is actually
        %   also dependent on the specific parameter popup selection.

            switch obj.NumParams
              case "0"
                numParams = 0;
              case "1"
                numParams = 1;
              case "2"
                % Because popup lists cannot be dynamically updated, it
                % is possible for users to select the same value twice.
                % In that case, the number of settable parameters (as
                % inputs or edit fields) differs from the NumParams
                % property.

                % Use an if-statement since "unique" is not codegen
                % supported with cell arrays
                if strcmp(obj.Parameter1, obj.Parameter2)
                    numParams = 1;
                else
                    numParams = 2;
                end
            end
        end
    end

    methods (Access = private)
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
                    wPts = externalInputsCellArray{1};
                    obj.regeneratePPFormFromProperty(wPts);
                elseif (obj.HasInternalWptSource) && (~obj.HasInternalParamSource)
                    % Internal waypoints and external parameters
                    wPts = obj.Waypoints;
                    paramInputArgs = externalInputsCellArray;
                    obj.regeneratePPFormFromInputs(wPts, paramInputArgs);
                elseif (~obj.HasInternalWptSource) && (~obj.HasInternalParamSource)
                    % External waypoints and external parameters
                    wPts = externalInputsCellArray{1};
                    paramInputArgs = {externalInputsCellArray{2:end}}; %Avoid non-curly braces to satisfy codegen
                    obj.regeneratePPFormFromInputs(wPts, paramInputArgs);
                end
            end
        end

        function regeneratePPFormFromProperty(obj, wPts)
            %regeneratePPFormFromProperty Regenerate PP Forms when parameter inputs are all internal

            % Compute the pp-form. Since the trajectory outputs are
            % undesired, use a minimal number of points
            numPts = 2;
            switch obj.NumParams
                case "0"
                    [ ~, ~, ~, ~, trajPP] = trapveltraj(wPts, numPts);
                case "1"
                    % Name-value pair arguments can be passed through
                    % external inputs or internal properties
                    param1Name = obj.getParameterName(obj.Parameter1);
                    param1Value = obj.getParameter(obj.Parameter1);
                    [ ~, ~, ~, ~, trajPP] = trapveltraj(wPts, numPts, param1Name, param1Value);
                case "2"
                    % Name-value pair arguments can be passed through
                    % external inputs or internal properties
                    param1Name = obj.getParameterName(obj.Parameter1);
                    param2Name = obj.getParameterName(obj.Parameter2);
                    param1Value = obj.getParameter(obj.Parameter1);
                    param2Value = obj.getParameter(obj.Parameter2);
                    [ ~, ~, ~, ~, trajPP] = trapveltraj(wPts, numPts, param1Name, param1Value, param2Name, param2Value);
            end

            obj.update1DPPFormArrays(trajPP);

            % Reset the flag
            obj.PPFormUpdatedNeeded = false;
        end

        function regeneratePPFormFromInputs(obj, wPts, paramInputArgs)
            %regeneratePPFormFromInputs Regenerate PP-Forms when parameters are external inputs

            % Compute the pp-form. Since the trajectory outputs are
            % undesired, use a minimal number of points
            numPts = 2;
            switch obj.NumParams
                case "0"
                    [ ~, ~, ~, ~, trajPP] = trapveltraj(wPts, numPts);
                case "1"
                    % Name-value pair arguments can be passed through
                    % external inputs or internal properties
                    param1Name = obj.getParameterName(obj.Parameter1);
                    param1Value = paramInputArgs{1};
                    [ ~, ~, ~, ~, trajPP] = trapveltraj(wPts, numPts, param1Name, param1Value);
                case "2"
                    % Name-value pair arguments can be passed through
                    % external inputs or internal properties
                    param1Name = obj.getParameterName(obj.Parameter1);
                    param2Name = obj.getParameterName(obj.Parameter2);
                    param1Value = paramInputArgs{1};
                    param2Value = paramInputArgs{2};
                    [ ~, ~, ~, ~, trajPP] = trapveltraj(wPts, numPts, param1Name, param1Value, param2Name, param2Value);
            end

            obj.update1DPPFormArrays(trajPP);

            % Reset the flag
            obj.PPFormUpdatedNeeded = false;
        end

        function update1DPPFormArrays(obj, trajPP)
            %update1DPPFormArrays Update the stored cell arrays of 1-D PP-Forms
            %   The object stores N-element cell arrays of 1-D ppforms for
            %   position, velocity, and acceleration, which are used to
            %   compute the final trajectory. This method accepts an
            %   N-element PP-Form corresponding to position and extracts a
            %   cell array of N 1-D PP-Forms. Additionally, the method
            %   creates corresponding arrays for its two derivative
            %   piecewise polynomial (velocity and acceleration).

            n = obj.NumWaypointElements;

            % Initialize PP-Form Cell arrays
            ppCell = cell(1,n);
            ppdCell = cell(1,n);
            ppddCell = cell(1,n);

            % For codegen generalization, treat all trajectories as
            % individual Nx1 pp-forms
            for i = 1:n

                % Extract the breaks and coefficients from the piecewise
                % polynomial cell array
                if numel(trajPP) > 1
                    % If the cell array is already constructed of N 1-D
                    % pp-forms, then it is sufficient to unmake the ith
                    % pp-form.
                    [breaks, oneDimCoeffs] = unmkpp(trajPP{i});
                else
                    % If the cell array consists of 1 N-D pp-form, then it
                    % is necessary to extract the ith dimension from the
                    % pp-form.
                    [breaks, oneDimCoeffs] = obj.extract1DimFromPP(trajPP{1}, n, i);
                end

                % Make first dimension explicit for codegen
                evalCoeffs = zeros(size(oneDimCoeffs,1), 3);
                evalCoeffs(1:size(oneDimCoeffs,1),1:3) = oneDimCoeffs;

                [pp, ppd, ppdd] = obj.generate1DPVAPPForms(breaks, evalCoeffs);

                ppCell{i} = pp;
                ppdCell{i} = ppd;
                ppddCell{i} = ppdd;
            end

            obj.PPCell = ppCell;
            obj.PPDCell = ppdCell;
            obj.PPDDCell= ppddCell;
        end

        function [qArray, qdArray, qddArray] = generateTrajectoriesFromPPForm(obj, time)
            %generateTrajectoriesFromPPForm

            n = obj.NumWaypointElements;

            % Generate trajectories
            qCell = cell(n,1);
            qdCell = cell(n,1);
            qddCell = cell(n,1);

            for j = 1:n
                % Evaluate trajectories
                [qCell{j}, qdCell{j}, qddCell{j}] = obj.generate1DTrajectories(obj.PPCell{j}, obj.PPDCell{j}, obj.PPDDCell{j}, time);
            end

            % Concatenate the outputs in a codegen compatible way
            qArray = vertcat(qCell{:});
            qdArray = vertcat(qdCell{:});
            qddArray = vertcat(qddCell{:});
        end

        function initializePPFormCellArrays(obj)
            %initializePPFormCellArrays Initialize the PPCell, PPDCell, and PPDDCell properties

            if obj.HasInternalWptSource && obj.HasInternalParamSource
                obj.regeneratePPFormFromProperty(obj.Waypoints);
            else
                % If either waypoints or parameters are external, the
                % piecewise polynomials will anyway be recomputed in the
                % first call to stepImpl, so this call just initializes the
                % cell arrays
                placeholderWpts = ones(1, obj.NumWaypoints);
                [~,~,~,~,placeholderPPCell] = trapveltraj(placeholderWpts, 2);
                placeholderPP = placeholderPPCell{1};
                obj.PPCell = repmat({placeholderPP}, 1, obj.NumWaypointElements);
                obj.PPDCell = repmat({placeholderPP}, 1, obj.NumWaypointElements);
                obj.PPDDCell = repmat({placeholderPP}, 1, obj.NumWaypointElements);
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

        function [pp, ppd, ppdd] = generate1DPVAPPForms(breaks, coefs)
            %generate1DPVAPPForms Generate 1-D PP-Forms for position, velocity, and acceleration
            %   This method accepts breaks and coefficients for position
            %   and generates 1-D pp-forms for position, velocity and
            %   acceleration piecewise polynomials (pp, ppd, and ppdd).

            % Compute the coefficients of the derivatives
            dCoefs = robotics.core.internal.polyCoeffsDerivative(coefs);
            ddCoefs = robotics.core.internal.polyCoeffsDerivative(dCoefs);

            % Generate the pp-forms for position, velocity, acceleration
            pp = mkpp(breaks, coefs,1);
            ppd = mkpp(breaks, dCoefs,1);
            ppdd = mkpp(breaks, ddCoefs,1);
        end

        function [q, qd, qdd] = generate1DTrajectories(pp, ppd, ppdd, t)
        %generate1DTrajectories Generate q, qd, and qdd trajectories
        %   This method takes pp-forms for a piecewise polynomial with
        %   dimension=1 and computes the value at time T. T can be a scalar
        %   time or a vector of times. The method also computes the first
        %   and second derivatives. 

            % To ensure that the output is always a row, make sure time is
            % in row format
            evalTime = zeros(1, numel(t));
            evalTime(:) = t;

            % Compute outputs at the times specified by the "time" input,
            % which may be either a vector or a scalar instant in time.
            q = ppval(pp, evalTime);
            qd = ppval(ppd, evalTime);
            qdd = ppval(ppdd, evalTime);
        end

        %% Static System block methods

        function header = getHeaderImpl
        %getHeaderImpl Define header panel for System block dialog

            header = matlab.system.display.Header(mfilename("class"),...
                                                  'Title',message('shared_robotics:robotslcore:trajectorygeneration:TrapVelTrajTitle').getString, ...
                                                  'Text', message('shared_robotics:robotslcore:trajectorygeneration:TrapVelTrajDescription').getString, ...
                                                  'ShowSourceLink', false);
        end

        function groups = getPropertyGroupsImpl
        %getPropertyGroupsImpl Organize property grouping appearance on block mask

        % Section titles and descriptions
            WaypointInputSectionName = message('shared_robotics:robotslcore:trajectorygeneration:WaypointsSectionTitle').getString;
            ParameterInputSectionName = message('shared_robotics:robotslcore:trajectorygeneration:ParametersSectionTitle').getString;

            % Properties associated with waypoints section
            propWaypointSource = matlab.system.display.internal.Property('WaypointSource','Description',getString(message('shared_robotics:robotslcore:trajectorygeneration:WaypointSourcePrompt')));
            propWaypoints = matlab.system.display.internal.Property('Waypoints','Description',getString(message('shared_robotics:robotslcore:trajectorygeneration:WaypointsPrompt')));

            % Properties associated with time scaling
            propParameterSource = matlab.system.display.internal.Property('ParameterSource','Description',getString(message('shared_robotics:robotslcore:trajectorygeneration:ParameterSourcePrompt')));
            propNumParams = matlab.system.display.internal.Property('NumParams','Description',getString(message('shared_robotics:robotslcore:trajectorygeneration:TrapVelTrajNumParamsPrompt')));
            propParameter1 = matlab.system.display.internal.Property('Parameter1','Description',getString(message('shared_robotics:robotslcore:trajectorygeneration:TrapVelTrajParameter1Prompt')));
            propParameter2 = matlab.system.display.internal.Property('Parameter2','Description',getString(message('shared_robotics:robotslcore:trajectorygeneration:TrapVelTrajParameter2Prompt')));
            propPeakVelocity = matlab.system.display.internal.Property('PeakVelocity','Description',getString(message('shared_robotics:robotslcore:trajectorygeneration:TrapVelTrajVelocityPrompt')));
            propAcceleration = matlab.system.display.internal.Property('Acceleration','Description',getString(message('shared_robotics:robotslcore:trajectorygeneration:TrapVelTrajAccelerationPrompt')));
            propEndTime = matlab.system.display.internal.Property('EndTime','Description',getString(message('shared_robotics:robotslcore:trajectorygeneration:TrapVelTrajEndTimePrompt')));
            propAccelTime = matlab.system.display.internal.Property('AccelTime','Description',getString(message('shared_robotics:robotslcore:trajectorygeneration:TrapVelTrajAccelTimePrompt')));

            waypointProps = matlab.system.display.Section( ...
                'Title', WaypointInputSectionName, ...
                'PropertyList', {propWaypointSource, propWaypoints});

            inputProps = matlab.system.display.Section( ...
                'Title', ParameterInputSectionName, ...
                'PropertyList', {propNumParams, propParameter1, propParameter2, propParameterSource, propPeakVelocity, propAcceleration, propEndTime, propAccelTime});

            groups = [waypointProps inputProps];
        end

        %% Static custom helper methods

        function [breaks, oneDimCoeffs] = extract1DimFromPP(pp, n, i)
        %extract1DimFromPP Extract breaks and coefficients for the ith dimension from a pp-form with dim=N
        %   Given a pp-form that represents an N-dimensional piecewise
        %   polynomial, this utility extracts the breaks and the
        %   coefficients for the Ith dimension. Note that N is passed
        %   as an input to conform to code generation requirements.

            [breaks, coeffs] = unmkpp(pp);
            numPieces = numel(breaks)-1;

            % Select relevant entries from coefficient and breaks matrices
            nCoeffIndex = false(n,1);
            nCoeffIndex(i) = true;
            coeffIndex = repmat(nCoeffIndex, numPieces, 1);

            oneDimCoeffs = coeffs(coeffIndex, :);
        end

        function param = getParameterName(paramName)
        %getParameterName Return the name of the name-value pair given the parameter edit field name

            switch paramName
              case 'Peak Velocity'
                param = 'PeakVelocity';
              case 'Acceleration'
                param = 'Acceleration';
              case 'End Time'
                param = 'EndTime';
              case 'Acceleration Time'
                param = 'AccelTime';
            end
        end

        function validateParameterSize(waypointSize, parameter, parameterName)

        % Exact size can only be verified if the waypoint size is known
            if ~isempty(waypointSize)
                n = waypointSize(1);
                p = waypointSize(2);
                isSizeValid = (all(size(parameter) == [1 1]) || all(size(parameter) == [n 1]) || all(size(parameter) == [n p-1]));
                coder.internal.errorIf(~isSizeValid, 'shared_robotics:robotcore:utils:TrapVelOptInputSize', parameterName);
            end
        end
    end
end
