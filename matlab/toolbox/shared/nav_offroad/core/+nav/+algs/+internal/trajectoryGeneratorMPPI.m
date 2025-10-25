classdef trajectoryGeneratorMPPI  < nav.algs.internal.InternalAccess
%This class is for internal use only. It may be removed in the future.

%TRAJECTORYGENERATORMPPI Generates random trajectories for Model Predictive Path Integral Control.
%   This class is responsible for generating random trajectories based
%   on the vehicle model and its current state. It takes into
%   consideration the vehicle's input constraints to ensure that the
%   generated trajectories are feasible.

%   Copyright 2024 The MathWorks, Inc.

%#codegen

    properties
        VehicleModel % Model of the vehicle used for trajectory prediction
        NumVehicleInputs % Number of control inputs for the vehicle
        NumVehicleStates % Number of states in the vehicle model
        NumTrajectories % Number of trajectories to generate
        NumTrajectoryStates % Number of states in each trajectory
        SampleTime % Sampling time for trajectory generation
        VehicleInputsStandardDeviation % Standard deviation of vehicle input noise
        MaxVehicleInput % Maximum allowable vehicle input
        MinVehicleInput % Minimum allowable vehicle input
        MaxVehicleInputDerivative % Maximum allowable rate of change of vehicle input
        MinVehicleInputDerivative % Minimum allowable rate of change of vehicle input
    end
    properties (SetAccess = 'immutable')
        IntegrationType % Type of integration method for state propagation
    end
    properties(Access=?nav.algs.internal.InternalAccess)
        IntegratorInternal
        IntegratorFcn
    end

    methods
        function obj = trajectoryGeneratorMPPI(options)
        %TRAJECTORYGENERATORMPPI Construct an instance of this class
        %   The constructor initializes the properties of the class with the
        %   values provided or with the default values if no values are provided.
        %   The input arguments are name-value pairs corresponding to the
        %   properties of the class.
            arguments
                options.VehicleModel = bicycleKinematics
                options.NumVehicleInputs (1,1) {mustBeInteger,mustBePositive} = 2
                options.NumVehicleStates (1,1) {mustBePositive,mustBeInteger} = 3
                options.NumTrajectories (1,1) {mustBePositive,mustBeInteger} = 500
                options.NumTrajectoryStates (1,1) {mustBePositive,mustBeInteger} = 20
                options.SampleTime (1,1) {mustBePositive} = 0.1
                options.VehicleInputsStandardDeviation (1,:) {mustBeNonnegative} = [2 0.5]
                options.MaxVehicleInput (1,:) {mustBeNumeric} = [5 0.1]
                options.MinVehicleInput (1,:) {mustBeNumeric} = [-0.1 -0.1]
                options.MaxVehicleInputDerivative (1,:) {mustBeNumeric} = [inf inf]
                options.MinVehicleInputDerivative (1,:) {mustBeNumeric} = [-inf -inf]
                options.IntegrationType {mustBeMember(options.IntegrationType,{'euler','rungeKutta4'})} = 'rungeKutta4'

            end
            propertyNames = fieldnames(options);
            for i = 1:length(propertyNames)
                obj.(propertyNames{i}) = options.(propertyNames{i});
            end
            % Builds Integrator based on Integrator Type
            obj.IntegratorInternal = obj.buildIntegrator(options.IntegrationType);
            derivFcn = @(q,u)derivative(options.VehicleModel,q,u)';
            updateFcn = @obj.update;
            obj.IntegratorFcn =  obj.IntegratorInternal.getIntegrator(derivFcn,updateFcn);
        end

        function [trajectories,trajectoriesInputs] = generate(obj,currentVehicleState,currentVehicleInput,trajectoriesInputsPrev)
        %GENERATE Generates random trajectories for the vehicle model
        %   This method generates random trajectories based on the current state
        %   and input of the vehicle. It applies noise to the control inputs
        %   and simulates the vehicle's response over the trajectory horizon.
        %   Inputs:
        %       currentVehicleState - The current state of the vehicle
        %       currentVehicleInput - The current input to the vehicle
        %       trajectoriesInputsPrev - The previous optimal trajectory Inputs
        %   Outputs:
        %       trajectories - A 3D matrix containing the generated state trajectories
        %                       [NumTrajectoryStates x NumVehicleStates x NumTrajectories]
        %       trajectoriesInputs - A 3D matrix containing the input commands for each trajectory
        %                           [NumTrajectoryStates x NumVehicleInputs x NumTrajectories]

        % Randomly sampling control inputs using Input Standard Deviation
            mu = zeros(1,obj.NumVehicleInputs);
            sigma = diag(obj.VehicleInputsStandardDeviation);
            gaussianDisturbances = obj.generateGaussianDisturbances(mu,sigma,obj.NumTrajectoryStates,obj.NumTrajectories);

            % Initializing 3d array to hold all state trajectories
            % (obj.NumTrajectoryStates x obj.NumVehicleStates x NumTrajectories )
            trajectories = zeros(obj.NumTrajectoryStates,obj.NumVehicleStates,obj.NumTrajectories);
            predictionSteps = obj.NumTrajectoryStates - 1;
            trajectories(1,:,:) = repmat(currentVehicleState,1,1,obj.NumTrajectories);
            % Adding sampled disturbances to initial input command provided by
            % user.
            sampledInputs =  trajectoriesInputsPrev + gaussianDisturbances;
            % Applying user provided velocity constraints on control inputs (before trajectory generation)
            sampledInputs = min(sampledInputs,obj.MaxVehicleInput); % max velocity constraint
            sampledInputs = max(sampledInputs,obj.MinVehicleInput); % min velocity constraint
                                                                    % Applying user provided acceleration constraints on control inputs (before trajectory generation)
            sampledInputDelayed = [repmat(currentVehicleInput,1,1,obj.NumTrajectories); sampledInputs(1:end-1,:,:)];
            sampledInputsAcceleration = ((sampledInputs-sampledInputDelayed)./obj.SampleTime); % compute accelerations
            constrainedAcceleration = min(sampledInputsAcceleration,obj.MaxVehicleInputDerivative); % max acceleration constraint
            constrainedAcceleration = max(constrainedAcceleration,obj.MinVehicleInputDerivative); % min acceleration constraint
            trajectoriesInputs = sampledInputDelayed + constrainedAcceleration*obj.SampleTime; % Move this inside inner for loop
                                                                                               % Predicting state trajectories using vehicle model & sampled
                                                                                               % controls
            for t = 1:predictionSteps
                sampledControlInput = reshape(trajectoriesInputs(t,:,:),obj.NumVehicleInputs,obj.NumTrajectories)';
                reshapedTrajStates = reshape(trajectories(t,:,:),obj.NumVehicleStates,obj.NumTrajectories)';
                integratedStates = obj.IntegratorFcn(reshapedTrajStates,sampledControlInput,obj.SampleTime);
                trajectories(t+1,:,:) = reshape(integratedStates,1,obj.NumVehicleStates,obj.NumTrajectories);
            end

        end
    end
    methods(Access=private,Static)
        % function for generation random disturbances using given mean(mu) & standard deviation
        function disturbances = generateGaussianDisturbances(mu,sigma,predictionSteps,numTrajectories)
            R = sigma;
            numInputs = size(mu,2);
            disturbances = repmat(mu,predictionSteps,1,numTrajectories) + pagemtimes(randn(predictionSteps,numInputs,numTrajectories),repmat(R,1,1,numTrajectories));
        end

        function qNew = update(q, dq)
        % Update method to be used for integrator
            qNew = q+dq;
        end
    end
    methods(Static,Hidden)
        function integrator = buildIntegrator(name)
        % function to initialize integrator based on integration method
        % selected by user
            switch name
              case 'euler'
                integrator = nav.algs.internal.integrators.euler;
              case 'rungeKutta4'
                integrator = nav.algs.internal.integrators.rk4;
            end
        end
    end
end
