classdef controllerMPPI < matlab.System & nav.algs.internal.controllerMPPIImpl
%

%   Copyright 2024 The MathWorks, Inc.

%#codegen

% Public Dependent Properties
    properties(Dependent)
        ReferencePath
        NumTrajectory
        SampleTime
        TrajectorySelectionBias
        StandardDeviation
        GoalTolerance;
    end

    % Public Immutable Properties
    properties (SetAccess=immutable)
        VehicleModel
    end

    % Public Properties
    properties
        LookaheadTime
        Map
        Options
    end

    % Read only properties
    properties (Dependent, SetAccess=private,GetAccess=public)
        NumStates
    end

    properties(Access=private)
        Cost
    end

    methods
        function obj = controllerMPPI(referencePath,nvPairs)
        %
            arguments
                referencePath {mustBeA(referencePath,{'navPath','numeric'})} = []
                nvPairs.Map = binaryOccupancyMap()
                nvPairs.VehicleModel (1,1) {mustBeA(nvPairs.VehicleModel,{'ackermannKinematics','bicycleKinematics','differentialDriveKinematics','unicycleKinematics'})} = bicycleKinematics
                nvPairs.LookaheadTime = 4
                nvPairs.NumTrajectory = 500
                nvPairs.SampleTime  = 0.1
                nvPairs.TrajectorySelectionBias = 1000
                nvPairs.StandardDeviation =  getVehicleInputStdDev(bicycleKinematics)
                nvPairs.GoalTolerance = [1 1 0.1];
                nvPairs.Options = createOptionsStruct
            end

            % Enable save-load functionality for controllerMPPI
            % Check if object is being loaded by user
            isLoading = coder.const(controllerMPPI.isLoading);
            if isLoading
                refpath = [];
            else
                % Validate Reference Path
                refpath = controllerMPPI.validateReferencePath(referencePath);
            end

            % Extract Vehicle Model dependent Information. This should
            % either come from RST Kinematic models or custom vehicle
            % models
            [numVehicleStates, numVehicleInputs, maxForwardVelocity, maxReverseVelocity,maxInputLimits, minInputLimits,~] = ...
                controllerMPPI.getVehicleModelInformation(nvPairs.VehicleModel);

            % Need to call it here before accessing obj
            obj@nav.algs.internal.controllerMPPIImpl(refpath,"VehicleModel",nvPairs.VehicleModel);

            % Initialize all properties with intrinsic validation using set
            % methods
            obj.MaxForwardVelocity = maxForwardVelocity;
            obj.MaxReverseVelocity = maxReverseVelocity;
            obj.TrajectoryGeneratorObj.NumVehicleStates = numVehicleStates;
            obj.TrajectoryGeneratorObj.NumVehicleInputs = numVehicleInputs;
            obj.TrajectoryGeneratorObj.MaxVehicleInput(1) = maxInputLimits(1);
            obj.TrajectoryGeneratorObj.MinVehicleInput(1) = minInputLimits(1);
            obj.TrajectoryGeneratorObj.MaxVehicleInput(2) = maxInputLimits(2);
            obj.TrajectoryGeneratorObj.MinVehicleInput(2) = minInputLimits(2);

            propertyNames = fieldnames(nvPairs);
            for i = 1:length(propertyNames)
                obj.(propertyNames{i}) = nvPairs.(propertyNames{i});
            end


        end
    end
    methods (Access = protected)
        function num = getNumInputsImpl(~)
            num = 2;
        end

        function setupImpl(~)
        end

        function validateInputsImpl(obj,currentState,currentControl)
            validateattributes(currentState,'numeric',{'row','ncols',obj.TrajectoryGeneratorObj.NumVehicleStates,'finite','nonempty'},'controllerMPPI','Current State',1);
            validateattributes(currentControl,'numeric',{'row','ncols',obj.TrajectoryGeneratorObj.NumVehicleInputs,'finite','nonempty'},'controllerMPPI','Current Control',2);
        end

        function [optTrajControls, optTrajStates, extraInfo] = stepImpl(obj,currentState,currentControl)
        %
            [optTrajControls, optTrajStates, extraInfo] = stepImpl@nav.algs.internal.controllerMPPIImpl(obj,currentState,currentControl);
        end

        function s = saveObjectImpl(obj)
            s = saveObjectImpl@matlab.System(obj);
            s.ReferencePath = obj.ReferencePath;
            s.NumTrajectory = obj.NumTrajectory;
            s.SampleTime = obj.SampleTime;
            s.TrajectorySelectionBias = obj.TrajectorySelectionBias;
            s.StandardDeviation = obj.StandardDeviation;
            s.GoalTolerance = obj.GoalTolerance;
        end

        function loadObjectImpl(obj,s,wasLocked)
            loadObjectImpl@matlab.System(obj,s,wasLocked);
            obj.ReferencePath = s.ReferencePath;
            obj.NumTrajectory = s.NumTrajectory;
            obj.SampleTime = s.SampleTime;
            obj.TrajectorySelectionBias = s.TrajectorySelectionBias;
            obj.StandardDeviation = s.StandardDeviation;
            obj.GoalTolerance = s.GoalTolerance;
        end


    end

    %% Set-Get methods for each property
    methods

        function refPath = get.ReferencePath(obj)
            refPath = obj.ReferencePathInternal;
        end

        function set.ReferencePath(obj, refPath)
            obj.ReferencePathInternal = controllerMPPI.validateReferencePath(refPath);
            % If the user reset the reference path, the index in reference
            % path which is closest to the robot should also be reset to 1.
            obj.RefPathIdxCloseToRobot = 1;
        end

        function set.Map(obj, map)
        %   set.Map(OBJ, MAP) sets the 'Map' property of OBJ to MAP. MAP must be an
        %   instance of one of the following classes: 'occupancyMap',
        %   'binaryOccupancyMap', or 'signedDistanceMap'.
            arguments
                obj
                map (1,1) {mustBeA(map,{'occupancyMap','binaryOccupancyMap','signedDistanceMap'})}
            end
            obj.Map = map;
        end

        % get methods for vehicle type (validation only through constructor
        % route as it can be only defined during constructor initialization)
        function value = get.VehicleModel(obj)
        % get Method for VehicleModel
            value = obj.VehicleModel;
        end

        function set.LookaheadTime(obj,value)
        % set Method for LookaheadTime
            arguments
                obj
                value (1,1) {mustBeNumeric,mustBeFinite, mustBePositive}

            end
            obj.LookaheadTime = value;
            obj.TrajectoryGeneratorObj.NumTrajectoryStates = floor((value/(obj.TrajectoryGeneratorObj.SampleTime)) + 1);
            obj.PrevOptTrajControls = zeros(obj.TrajectoryGeneratorObj.NumTrajectoryStates,obj.TrajectoryGeneratorObj.NumVehicleInputs);
            obj.LookaheadDistance =  obj.MaxForwardVelocity*obj.LookaheadTime;
        end

        function value = get.LookaheadTime(obj)
        % get Method for LookaheadTime
            value = obj.LookaheadTime;
        end

        function set.NumTrajectory(obj,value)
        % set Method for NumTrajectory
            arguments
                obj
                value (1,1) {mustBeInteger, mustBePositive}
            end
            obj.TrajectoryGeneratorObj.NumTrajectories = value;
        end
        function value = get.NumTrajectory(obj)
        % get Method for NumTrajectory
            value = obj.TrajectoryGeneratorObj.NumTrajectories;
        end

        function set.SampleTime(obj,value)
        % get method for SampleTime
            arguments
                obj
                value (1,1) {mustBeNumeric,mustBeFinite, mustBeReal, mustBePositive}
            end
            obj.TrajectoryGeneratorObj.NumTrajectoryStates = floor((obj.LookaheadTime/(value)) + 1);
            obj.PrevOptTrajControls = zeros(obj.TrajectoryGeneratorObj.NumTrajectoryStates,obj.TrajectoryGeneratorObj.NumVehicleInputs);
            obj.TrajectoryGeneratorObj.SampleTime = value;
        end

        function value = get.SampleTime(obj)
        % get Method for SampleTime
            value = obj.TrajectoryGeneratorObj.SampleTime;
        end

        function set.TrajectorySelectionBias(obj,value)
        % set method for TrajectorySelectionBias
            arguments
                obj
                value (1,1) {mustBeNumeric, mustBeNonempty, mustBeFinite, ...
                             mustBeReal, mustBePositive, mustBeNonsparse}
            end
            obj.Lambda = value;
        end

        function value = get.TrajectorySelectionBias(obj)
        % get method for TrajectorySelectionBias
            value = obj.Lambda;
        end

        function set.GoalTolerance(obj,value)
        %   set.GoalTolerance(OBJ, GOALTOL) sets the 'GoalToleranceInternal' property
        %   of OBJ to GOALTOL. GOALTOL specifies the tolerances for reaching the goal
        %   position and orientation. It must be a numeric row vector of size 1-by-3,
        %   containing positive, finite, real numbers.
            arguments
                obj
                value (1,3) {mustBeNonempty, mustBeFinite, mustBePositive}
            end
            obj.GoalToleranceInternal = value;
        end

        function value = get.GoalTolerance(obj)
        % validation for Goal Tolerance
            value = obj.GoalToleranceInternal;
        end

        function set.Options(obj,value)
        % set method for Options
            arguments
                obj
                value {validateOptionsValue(value)}
            end
            % Codegen does not allow redefinition of function handles once
            % initialized. For codegen, Options.CostFcn can be defined
            % only once either through constructor or property setter. If
            % the user input is not provided the nav.algs.internal.defaultCost
            % will be used for optimization.
            if coder.target('MATLAB')
                obj.CostFcn = value.CostFcn;
                obj.Options = value;
            else
                if isfield(value,"CostFcn")
                    obj.CostFcn = value.CostFcn;
                    obj.Options = struct('Parameters',value.Parameters);
                else
                    obj.Options = value;
                end
            end
            obj.Parameters = value.Parameters;
            obj.TrajectoryGeneratorObj.MaxVehicleInputDerivative(2) = value.Parameters.MaxAngularAcceleration;
            obj.TrajectoryGeneratorObj.MinVehicleInputDerivative(2) = -value.Parameters.MaxAngularAcceleration;
            obj.TrajectoryGeneratorObj.MaxVehicleInputDerivative(1) = value.Parameters.MaxLinearAcceleration;
            obj.TrajectoryGeneratorObj.MinVehicleInputDerivative(1) = -value.Parameters.MaxLinearDeceleration;
            obj.ObstacleSafetyMargin = value.Parameters.ObstacleSafetyMargin;
            obj.CostWeights = value.Parameters.CostWeights;
            shapeName = obj.Options.Parameters.VehicleCollisionInformation.Shape;
            shapeName = string(validatestring(shapeName, {'Rectangle', 'Point'}, mfilename, 'VehicleCollisionInformation.Shape'));
            obj.Options.Parameters.VehicleCollisionInformation.Shape = shapeName;
            value.Parameters.VehicleCollisionInformation.Shape = shapeName;
            if strcmp(value.Parameters.VehicleCollisionInformation.Shape,'Point')
                value.Parameters.VehicleCollisionInformation.Dimension = [0 0];
                obj.Options.Parameters.VehicleCollisionInformation.Dimension = [0 0];
            end
            obj.VehicleCollisionInformation = value.Parameters.VehicleCollisionInformation;
        end

        function value = get.Options(obj)
        % get method for Options
            value = obj.Options;
        end

        function set.StandardDeviation(obj,value)
        % set method for StandardDeviation
            arguments
                obj
                value (1,:) {mustBeNumeric,mustBeNonnegative,mustBeFinite}
            end
            coder.internal.errorIf(~isequal(size(value,2),...
                                            obj.TrajectoryGeneratorObj.NumVehicleInputs), ...
                                   'shared_nav_offroad:controllermppi:InvalidVehicleInputStdDev');
            obj.TrajectoryGeneratorObj.VehicleInputsStandardDeviation = value;
        end

        function value = get.StandardDeviation(obj)
        % getMethod for StandardDeviation
            value = obj.TrajectoryGeneratorObj.VehicleInputsStandardDeviation;
        end

        function value = get.NumStates(obj)
        % getMethod for NumStates
        % Read Only Property
            value = obj.TrajectoryGeneratorObj.NumTrajectoryStates;
        end
    end

    methods(Hidden, Static, Access = protected)
        function rp = validateReferencePath(refpath)

            if isa(refpath, "navPath")
                coder.internal.errorIf(class(refpath.StateSpace) ~= "stateSpaceSE2", ...
                                       "shared_nav_offroad:controllermppi:InvalidPathInput");

                coder.internal.errorIf(refpath.NumStates < 3, ...
                                       'shared_nav_offroad:controllermppi:MinPathPoints');

                rp = refpath.States;
            else
                % for now keep a numeric path as catch all, if the reference path is not a special
                % class it should be a numeric matrix
                validateattributes(refpath, 'numeric', ...
                                   {'2d', 'nonempty', 'nonnan', 'finite', 'real'}, mfilename, 'ReferencePath')

                coder.internal.errorIf(width(refpath)>3||width(refpath)<2,...
                                       'shared_nav_offroad:controllermppi:InvalidPathInput');

                coder.internal.errorIf(height(refpath)<3, ...
                                       'shared_nav_offroad:controllermppi:MinPathPoints');

                if width(refpath) == 2
                    heading = getHeadingFromXY(refpath);
                    rp = [refpath heading];
                else
                    rp = refpath;
                end
            end


        end

        % Vehicle Model related pre-processing.
        function [numVehicleStates, numVehicleInputs, maxForwardVelocity, maxReverseVelocity,maxInputLimits, minInputLimits,vehicleInputStdDev] = getVehicleModelInformation(vehicleModel)
            maxInputLimits = [5 0.1]; % initialized here to support code generation
            minInputLimits = [5 0.1]; % initialized here to support code generation
            if isa(vehicleModel,"ackermannKinematics")
                maxForwardVelocity = vehicleModel.VehicleSpeedRange(2);
                maxReverseVelocity = abs(vehicleModel.VehicleSpeedRange(1));
                numVehicleStates = 4;
                numVehicleInputs = 2;
                vehicleInputStdDev = [2 0.05];
                if isinf(maxForwardVelocity)
                    vehicleModel.VehicleSpeedRange = [-0.1 5];
                    maxForwardVelocity = vehicleModel.VehicleSpeedRange(2);
                    maxReverseVelocity = abs(vehicleModel.VehicleSpeedRange(1));
                end
                maxInputLimits = [vehicleModel.VehicleSpeedRange(2) inf];
                minInputLimits = [vehicleModel.VehicleSpeedRange(1) -inf];
            elseif isa(vehicleModel,"bicycleKinematics")
                maxForwardVelocity = vehicleModel.VehicleSpeedRange(2);
                maxReverseVelocity = abs(vehicleModel.VehicleSpeedRange(1));
                maxSteeringAngle = vehicleModel.MaxSteeringAngle;
                wheelBase = vehicleModel.WheelBase;
                numVehicleStates = 3;
                numVehicleInputs = 2;
                vehicleInputStdDev = [2 0.5];
                switch vehicleModel.VehicleInputs
                    case {'VehicleSpeedSteeringAngle'}
                        if isfinite(maxForwardVelocity)
                            maxInputLimits = [vehicleModel.VehicleSpeedRange(2) maxSteeringAngle] ;
                            minInputLimits = [vehicleModel.VehicleSpeedRange(1) -maxSteeringAngle];
                        else
                            vehicleModel.VehicleSpeedRange = [-0.1 5];  % wheel speed corresponding to forward velocity 5 m/sec
                            maxForwardVelocity = vehicleModel.VehicleSpeedRange(2);
                            maxReverseVelocity = abs(vehicleModel.VehicleSpeedRange(1));
                            maxInputLimits = [vehicleModel.VehicleSpeedRange(2) maxSteeringAngle] ;
                            minInputLimits = [vehicleModel.VehicleSpeedRange(1) -maxSteeringAngle];
                        end
                    case {'VehicleSpeedHeadingRate'}
                        if isfinite(maxForwardVelocity)
                            maxInputLimits = [vehicleModel.VehicleSpeedRange(2) (maxForwardVelocity*tan(maxSteeringAngle))/wheelBase];
                            minInputLimits = [vehicleModel.VehicleSpeedRange(1) -(maxForwardVelocity*tan(maxSteeringAngle))/wheelBase];
                        else
                            vehicleModel.VehicleSpeedRange = [-0.1 5];  % wheel speed corresponding to forward velocity 5 m/sec
                            maxForwardVelocity = vehicleModel.VehicleSpeedRange(2);
                            maxReverseVelocity = abs(vehicleModel.VehicleSpeedRange(1));
                            maxInputLimits = [vehicleModel.VehicleSpeedRange(2) (maxForwardVelocity*tan(maxSteeringAngle))/wheelBase];
                            minInputLimits = [vehicleModel.VehicleSpeedRange(1) -(maxForwardVelocity*tan(maxSteeringAngle))/wheelBase];
                        end
                end
            elseif isa(vehicleModel,"differentialDriveKinematics")
                wheelSpeedRange = vehicleModel.WheelSpeedRange;
                wheelRadius = vehicleModel.WheelRadius;
                trackWidth = vehicleModel.TrackWidth;
                maxForwardVelocity = vehicleModel.WheelSpeedRange(2)*vehicleModel.WheelRadius;
                maxReverseVelocity = abs(vehicleModel.WheelSpeedRange(1)*vehicleModel.WheelRadius);
                numVehicleStates = 3;
                numVehicleInputs = 2;
                vehicleInputStdDev = [2 0.5];
                switch vehicleModel.VehicleInputs
                    case {'WheelSpeeds'}
                        if isfinite(maxForwardVelocity)
                            [maxInputLimits, minInputLimits] = differentialDriveLimits("WheelSpeeds", wheelSpeedRange, wheelRadius, trackWidth);
                        else
                            vehicleModel.WheelSpeedRange = [-0.1/wheelRadius 5/wheelRadius];  % wheel speed corresponding to forward velocity 5 m/sec
                            [maxInputLimits, minInputLimits] = differentialDriveLimits("WheelSpeeds", vehicleModel.WheelSpeedRange, wheelRadius, trackWidth);
                            maxForwardVelocity = vehicleModel.WheelSpeedRange(2)*vehicleModel.WheelRadius;
                            maxReverseVelocity = abs(vehicleModel.WheelSpeedRange(1)*vehicleModel.WheelRadius);
                        end
                    case {'VehicleSpeedHeadingRate',"VehicleSpeedHeadingRate"}
                        if isfinite(maxForwardVelocity)
                             [maxInputLimits, minInputLimits] = differentialDriveLimits("VehicleSpeedHeadingRate", wheelSpeedRange, wheelRadius, trackWidth);
                        else
                            vehicleModel.WheelSpeedRange = [-0.1/wheelRadius 5/wheelRadius]; % wheel speed corresponding to forward velocity 5 m/sec
                            [maxInputLimits, minInputLimits] = differentialDriveLimits("VehicleSpeedHeadingRate", vehicleModel.WheelSpeedRange, wheelRadius, trackWidth);
                            maxForwardVelocity = vehicleModel.WheelSpeedRange(2)*vehicleModel.WheelRadius;
                            maxReverseVelocity = abs(vehicleModel.WheelSpeedRange(1)*vehicleModel.WheelRadius);
                        end
                end
            else % For Unicycle model
                wheelRadius = vehicleModel.WheelRadius;
                maxForwardVelocity = vehicleModel.WheelSpeedRange(2)*wheelRadius;
                maxReverseVelocity = abs(vehicleModel.WheelSpeedRange(1)*wheelRadius);
                numVehicleStates = 3;
                numVehicleInputs = 2;
                vehicleInputStdDev = [2 0.5];
                switch vehicleModel.VehicleInputs
                    case {'WheelSpeedHeadingRate'}
                        if isfinite(maxForwardVelocity)
                            maxInputLimits = [vehicleModel.WheelSpeedRange(2),inf];
                            minInputLimits = [vehicleModel.WheelSpeedRange(1),-inf];
                        else
                            vehicleModel.WheelSpeedRange = [-0.1/wheelRadius 5/wheelRadius];  % wheel speed corresponding to forward velocity 5 m/sec
                            maxForwardVelocity = vehicleModel.WheelSpeedRange(2)*wheelRadius;
                            maxReverseVelocity = abs(vehicleModel.WheelSpeedRange(1)*wheelRadius);
                            maxInputLimits = [vehicleModel.WheelSpeedRange(2),inf];
                            minInputLimits = [vehicleModel.WheelSpeedRange(1),-inf];
                        end
                    case {'VehicleSpeedHeadingRate'}
                        if isfinite(maxForwardVelocity)
                            maxInputLimits = [vehicleModel.WheelSpeedRange(2)*wheelRadius inf] ;
                            minInputLimits = [vehicleModel.WheelSpeedRange(1)*wheelRadius -inf];
                        else
                            vehicleModel.WheelSpeedRange = [-0.1/wheelRadius 5/wheelRadius]; % wheel speed corresponding to forward velocity 5 m/sec
                            maxForwardVelocity = vehicleModel.WheelSpeedRange(2)*wheelRadius;
                            maxReverseVelocity = abs(vehicleModel.WheelSpeedRange(1))*wheelRadius;
                            maxInputLimits = [vehicleModel.WheelSpeedRange(2)*wheelRadius inf] ;
                            minInputLimits = [vehicleModel.WheelSpeedRange(1)*wheelRadius -inf];                            
                        end
                end
            end
            if isinf(maxForwardVelocity) % To avoid inf velocity, which is defaults in RST models
                maxForwardVelocity = 5; % replace this
            end
            if isinf(maxReverseVelocity)  % To avoid inf velocity, which is defaults in RST models
                maxReverseVelocity = 0.1; % replace this
            end
        end
    end

    %% Object Display Method
    methods (Access = protected)

        function header = getHeader(obj)
            if ~isscalar(obj)
                header = getHeader@matlab.mixin.CustomDisplay(obj);
            else
                headerStr = matlab.mixin.CustomDisplay.getClassNameForHeader(obj);
                header = sprintf('%s\n',headerStr);
            end
        end
        function propgrp = getPropertyGroups(obj)
            if ~isscalar(obj)
                propgrp = getPropertyGroups@matlab.mixin.CustomDisplay(obj);
            else

                propList4 = {'Options','TrajectorySelectionBias'};
                gTitle4 = ['<strong>'...
                           'Optimization Parameters'  '</strong>'];

                propList3 = {'ReferencePath','GoalTolerance','Map'...
                            };
                gTitle3 = ['<strong>'...
                           'Path Following' ...
                           '</strong>'];

                propList2 = {'LookaheadTime','NumTrajectory','SampleTime','StandardDeviation','NumStates'};
                gTitle2 = ['<strong>'...
                           'Trajectory Generation Parameters'...
                           '</strong>'];

                propList1 = {'VehicleModel'};
                gTitle1 = ['<strong>'...
                           'Vehicle Parameters' ...
                           '</strong>'];



                propgrp1 = matlab.mixin.util.PropertyGroup(propList1,gTitle1);
                propgrp2 = matlab.mixin.util.PropertyGroup(propList2,gTitle2);
                propgrp3 = matlab.mixin.util.PropertyGroup(propList3,gTitle3);
                propgrp4 = matlab.mixin.util.PropertyGroup(propList4,gTitle4);
                propgrp = [propgrp1 propgrp2 propgrp3 propgrp4];

            end
        end
    end
    methods(Static, Hidden)
        function flag = isLoading()
        % Returns true if the object is currently being loaded
            flag = false;
            % Check for loading flag only for MATLAB workflow. As "dbstack"
            % doesn't support code generation.
            if coder.target('MATLAB')
                st = dbstack;
                for m = numel(st):-1:1
                    flag = strcmp(st(m).name,'System.loadobj');
                    if flag
                        break
                    end
                end
            end
        end
    end
end

function validateOptionsValue(value)

% Validate the CostFcn
    if coder.target('MATLAB')
        validateattributes(value, {'struct'}, {});
        mustHaveFields = {'CostFcn', 'Parameters'};
        for fieldName = mustHaveFields
            if ~isfield(value, fieldName{1})
                coder.internal.error("shared_nav_offroad:controllermppi:MissingStructField","Options", fieldName{1});
            end
        end
        validateattributes(value.CostFcn, {'function_handle'},{}, mfilename,'Options.CostFcn');
    else
        if isfield(value,"CostFcn")
            validateattributes(value.CostFcn, {'function_handle'},{}, mfilename,'Options.CostFcn');
        end
    end

    % Validate the Parameters structure and its fields
    validateattributes(value.Parameters, {'struct'}, {});
    mustHaveFields = {'CostWeights', 'MaxLinearAcceleration', 'MaxLinearDeceleration', 'MaxAngularAcceleration', 'ObstacleSafetyMargin', 'VehicleCollisionInformation'};
    for fieldName = mustHaveFields
        if ~isfield(value.Parameters, fieldName{1})
            %error('Parameters must include the field: %s', fieldName{1});
            coder.internal.error("shared_nav_offroad:controllermppi:MissingStructField","Parameters", fieldName{1});
        end
    end

    % Validate specific fields in Parameters

    % Validation for the CostWeights structure and its fields
    % Validate the CostWeights structure and its fields
    validateattributes(value.Parameters.CostWeights, {'struct'}, {});
    fieldsCostWeights = {'ObstacleRepulsion', 'PathAlignment', 'ControlSmoothing', 'PathFollowing'};
    for fieldName = fieldsCostWeights
        if isfield(value.Parameters.CostWeights, fieldName{1})
            validateattributes(value.Parameters.CostWeights.(fieldName{1}), {'numeric'}, {'nonnegative'});
        else
            coder.internal.error("shared_nav_offroad:controllermppi:MissingStructField","CostWeights", fieldName{1});
        end
    end

    % Validate non struct fields in Parameters
    validateattributes(value.Parameters.MaxLinearAcceleration, {'numeric'}, {'nonempty', 'scalar', 'nonnan', 'real', 'positive', 'nonsparse'},mfilename,'Options.Parameters.MaxLinearAcceleration');
    validateattributes(value.Parameters.MaxLinearDeceleration, {'numeric'}, {'nonempty', 'scalar', 'nonnan', 'real', 'positive', 'nonsparse'},mfilename,'Options.Parameters.MaxLinearDeceleration');
    validateattributes(value.Parameters.MaxAngularAcceleration, {'numeric'}, {'nonempty', 'scalar', 'nonnan', 'real', 'positive', 'nonsparse'},mfilename,'Options.Parameters.MaxAngularAcceleration');
    validateattributes(value.Parameters.ObstacleSafetyMargin, {'numeric'}, {'nonempty', 'scalar', 'nonnan', 'finite','real', 'nonnegative', 'nonsparse'},mfilename,'Options.Parameters.ObstacleSafetyMargin');

    % Validate VehicleCollisionInformation structure and its fields
    validateVehicleCollisionInformation(value.Parameters.VehicleCollisionInformation);

end

function validateVehicleCollisionInformation(vehicleInfo)

    validateattributes(vehicleInfo, {'struct'}, {});
    mustHaveFields = {'Shape','Dimension'};
    for fieldName = mustHaveFields
        if ~isfield(vehicleInfo, fieldName{1})
            coder.internal.error("shared_nav_offroad:controllermppi:MissingStructField","Parameters", fieldName{1});
        end
    end
    vehicleShape = validatestring(vehicleInfo.Shape, {'Rectangle', 'Point'}, ...
                                  mfilename, 'VehicleCollisionInformation.Shape');

    switch vehicleShape
      case "Point"
        validateattributes(vehicleInfo.Dimension, 'numeric', ...
                           {'nonempty', 'row', 'numel', 2, 'nonnan', 'finite', 'real'}, ...
                           mfilename, 'VehicleCollisionInformation.Dimension');
      case "Rectangle"
        validateattributes(vehicleInfo.Dimension, 'numeric', ...
                           {'nonempty', 'row', 'numel', 2, 'nonnan', 'finite', 'real', 'positive'}, ...
                           mfilename, 'VehicleCollisionInformation.Dimension for Rectangle');
    end
end


function optionsStruct = createOptionsStruct

% Function handle for Cost function
    defaultCostFcn =  @nav.algs.mppi.defaultCost;

    % Cost Weights for Cost Function
    CostWeightsStruct = struct( 'ObstacleRepulsion', 200, ...% Obstacle cutoff distance.
                                'PathAlignment', 1, ...% Obstacle cutoff distance.
                                'ControlSmoothing', 1, ...% Obstacle cutoff distance.
                                'PathFollowing', 1 ...% Obstacle cutoff distance.
                              );


    % Configurable Parameters
    VehicleCollisionInformationStruct = struct('Dimension',[1 1],"Shape","Rectangle");
    ParametersStruct = struct( 'CostWeights',CostWeightsStruct,...% cost weights
                               'MaxLinearAcceleration',inf,... % meter/sec^2
                               'MaxLinearDeceleration',inf,... % meter/sec^2 % positive value
                               'MaxAngularAcceleration',inf,... % rad/sec^2
                               'VehicleCollisionInformation',VehicleCollisionInformationStruct,...
                               'ObstacleSafetyMargin',0.5);

    % Constructing Cost Settings:
    % Codegen does not allow redefinition of function handles once
    % initialized. For codegen, Options.CostFcn can be defined
    % only once either through constructor or property setter. If
    % the user input is not provided the nav.algs.internal.defaultCost
    % will be used for optimization.

    if coder.target('MATLAB')
        optionsStruct = struct( 'CostFcn',defaultCostFcn, ...% Obstacle cutoff distance.
                                'Parameters', ParametersStruct ...% Cost related parameters
                              );
    else
        optionsStruct = struct('Parameters', ParametersStruct ...% Cost related parameters
                              );
    end
end


function vehicleInputstdDev = getVehicleInputStdDev(vehicleModel)
    if isa(vehicleModel,"ackermannKinematics")
        vehicleInputstdDev = [2 0.05];
    elseif isa(vehicleModel,"bicycleKinematics")
        vehicleInputstdDev = [2 0.5];
    elseif isa(vehicleModel,"differentialDriveKinematics")
        vehicleInputstdDev = [2 0.5];
    elseif isa(vehicleModel,"unicycleKinematics")
        vehicleInputstdDev = [2 0.05];
    else
        vehicleInputstdDev = [2 0.5];
    end
end


function heading = getHeadingFromXY(inputPath)

% Compute the first difference between the rows
    delta = diff(inputPath);

    % Compute the heading angle
    dirT = atan2(delta(:,2), delta(:,1));

    % Wrap the heading angle
    dirT = robotics.internal.wrapToPi(dirT);

    % Assigning direction to last pose.
    heading = [dirT;dirT(end)];
end


function [maxInputLimits, minInputLimits] = differentialDriveLimits(inputsType, wheelSpeedRange, wheelRadius, trackWidth)
    d = trackWidth/2;
    switch inputsType
        case 'WheelSpeeds'
            maxInputLimits = [wheelSpeedRange(2) wheelSpeedRange(2)]; % maxWheelSpeeds
            minInputLimits = [wheelSpeedRange(1) wheelSpeedRange(1)]; % minWheelSpeeds
        case 'VehicleSpeedHeadingRate'
            maxInputLimits = [wheelSpeedRange(2)*wheelRadius      (wheelSpeedRange(2)*wheelRadius - wheelSpeedRange(1)*wheelRadius)/(2*d)]; % maxWheelSpeeds
            minInputLimits = [wheelSpeedRange(1)*wheelRadius (wheelSpeedRange(1)*wheelRadius - wheelSpeedRange(2)*wheelRadius)/(2*d)]; % minWheelSpeeds
    end
end