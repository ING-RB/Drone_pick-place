classdef stateEstimatorPF< handle & matlabshared.tracking.internal.CustomDisplay
%stateEstimatorPF Create a particle filter state estimator
%   The particle filter is a recursive, Bayesian state estimator that
%   uses discrete particles to approximate the posterior distribution
%   of the estimated state.
%
%   The particle filter algorithm computes this state estimate recursively
%   and involves two steps, prediction and correction (also known as
%   the update step).
%
%   The prediction step uses the previous state to predict the current
%   state based on a given system model. The correction step uses the
%   current sensor measurement to correct the state estimate. The
%   algorithm periodically redistributes, or resamples, the particles
%   in the state space to match the posterior distribution of the
%   estimated state.
%   The particle filter can be applied to arbitrary non-linear system
%   models and process and measurement noise can follow arbitrary
%   non-Gaussian distributions.
%
%   The estimated state consists of a number of state variables. Each
%   particle represents a discrete state hypothesis. The set of all
%   particles approximates the posterior distribution of the estimated
%   state.
%
%   PF = stateEstimatorPF creates a
%   stateEstimatorPF object PF. Modify the StateTransitionFcn and
%   MeasurementLikelihoodFcn to customize the particle filter's system
%   and measurement models. Use the initialize method to initialize the
%   particles with a known mean and covariance or uniformly distributed
%   within defined state bounds.
%
%
%   stateEstimatorPF properties:
%       NumStateVariables        - (Read-only) Number of state variables for the particle filter
%       NumParticles             - (Read-only) Number of particles used in the filter
%       StateTransitionFcn       - Callback function calculating the state transition
%       MeasurementLikelihoodFcn - Callback function calculating the likelihood of sensor measurements
%       IsStateVariableCircular  - (Read-only) Indicator if state variables have a circular distribution
%       ResamplingPolicy         - Policy settings that determine when to trigger resampling
%       ResamplingMethod         - Method used for particle resampling
%       StateEstimationMethod    - Method used for state estimation
%       Particles                - Array of particle values
%       Weights                  - Vector of particle weights
%       State                    - (Read-only) Current state estimate
%       StateCovariance          - (Read-only) Current state estimation error covariance
%
%   stateEstimatorPF methods:
%       initialize       - Initialize the state of the particle filter
%       predict          - Calculate the predicted state in the next time step
%       correct          - Adjust state estimate based on sensor measurement
%       getStateEstimate - Extract the best state estimate and covariance from the particles
%       copy             - Create a copy of the particle filter
%
%
%   Example:
%
%       % Create a particle filter
%       pf = stateEstimatorPF
%
%       % Set the StateTransitionFcn and MeasurementFcn
%       pf.StateTransitionFcn = @nav.algs.gaussianMotion;
%       pf.MeasurementLikelihoodFcn = @nav.algs.fullStateMeasurement;
%
%       % Pick the mean state estimation method and systematic resampling
%       pf.StateEstimationMethod = 'mean';
%       pf.ResamplingMethod = 'systematic';
%
%       % Initialize the particle filter at state [4 1 9] with unit covariance
%       % Use 5000 particles
%       initialize(pf, 5000, [4 1 9], eye(3), 'StateOrientation', 'row');
%
%       % Assume we have a measurement [4.2 0.9 9]
%       % Run one predict and one correct step
%       [statePredicted, stateCov] = predict(pf)
%       [stateCorrected, stateCov] = correct(pf, [4.2 0.9 9])
%
%
%   References:
%
%   [1] M.S. Arulampalam, S. Maskell, N. Gordon, T. Clapp, "A tutorial on
%       particle filters for online nonlinear/non-Gaussian Bayesian tracking,"
%       IEEE Transactions on Signal Processing, vol. 50, no. 2, pp. 174-188,
%       Feb 2002
%   [2] Z. Chen, "Bayesian filtering: From Kalman filters to particle filters,
%       and beyond," Statistics, vol. 182, no. 1, pp. 1-69, 2003

     
    %   Copyright 2015-2019 The MathWorks, Inc.

    methods
        function out=stateEstimatorPF
            %stateEstimatorPF Constructor for object
        end

        function out=assertInitializeIsCalledAtLeastOnce(~) %#ok<STOUT>
            %assertInitializeIsCalledAtLeastOnce Ensure that initialize has been called
            %   Various PF operations require initialize() to be called
            %   first, at least once. Check this via a property that is
            %   only settable in initialize(), and is surely set when
            %   initialize() is called.
        end

        function out=clone(~) %#ok<STOUT>
            % CLONE Create a clone of the particle filter
            %   COBJ = CLONE(OBJ) creates a deep copy of the particleFilter
            %   object OBJ and returns it in COBJ. OBJ has to be a scalar
            %   handle object.
            %
            %   COBJ is an independent handle object that has the same
            %   property values as OBJ.
            %
            %   The clone() and copy() methods perform the same operation. 
            %   The copy() method has been retained to maintain backward
            %   compatibility.
        end

        function out=copy(~) %#ok<STOUT>
            % COPY Create a copy of the particle filter
            %   COBJ = COPY(OBJ) creates a deep copy of the particleFilter
            %   object OBJ and returns it in COBJ. OBJ has to be a scalar
            %   handle object.
            %
            %   COBJ is an independent handle object that has the same
            %   property values as OBJ.
            %
            %   The clone() and copy() methods perform the same operation. 
            %   The copy() method has been retained to maintain backward
            %   compatibility.
        end

        function out=correct(~) %#ok<STOUT>
            %CORRECT Adjust state estimate based on sensor measurement
            %   [STATECORR, STATECOV] = CORRECT(OBJ, MEASUREMENT) calculates
            %   the corrected system state STATECORR and its associated
            %   uncertainty covariance STATECOV based on a sensor
            %   MEASUREMENT at the current time step.
            %   CORRECT uses the measurement likelihood model specified in
            %   MeasurementLikelihoodFcn to calculate the likelihood for
            %   the sensor measurement for each particle. It then extracts
            %   the best state estimate and covariance based on the
            %   setting in StateEstimationMethod.
            %
            %   [STATECORR, STATECOV] = CORRECT(OBJ, MEASUREMENT, VARARGIN)
            %   passes all additional arguments supplied in VARARGIN to the
            %   underlying MeasurementLikelihoodFcn. The first two inputs to
            %   MeasurementLikelihoodFcn are the set of particles from the
            %   current time step and the MEASUREMENT, followed by all arguments
            %   in VARARGIN
            %
            %
            %   Example:
            %
            %       % Create a particle filter with 5000 particles and initialize it
            %       pf = stateEstimatorPF
            %       pf.StateTransitionFcn = @nav.algs.gaussianMotion;
            %       pf.MeasurementLikelihoodFcn = @nav.algs.fullStateMeasurement;
            %
            %       initialize(pf, 5000, [0 0 pi], eye(3), 'CircularVariables', [0 0 1], 'StateOrientation', 'row');
            %
            %       % Run one prediction step
            %       predict(pf)
            %
            %       % Assume we have a measurement [-1 0 pi]. Run the correction step.
            %       [stateCorrected, stateCov] = CORRECT(pf, [-1 0 pi])
            %
            %   See also MeasurementLikelihoodFcn, ResamplingMethod.
        end

        function out=getPropertyGroups(~) %#ok<STOUT>
            %getPropertyGroups Custom display for the object
            %
            % Do not calculate State and StateCovariance when displaying
            % the object
        end

        function out=getStateEstimate(~) %#ok<STOUT>
            %getStateEstimate Extract state estimate and covariance from particles
            %   STATEEST = getStateEstimate(OBJ) returns the best state
            %   estimate STATEEST based on the current set of particles.
            %   How this state estimate is extracted is determined by the
            %   StateEstimationMethod algorithm.
            %
            %   [STATEEST, STATECOV] = getStateEstimate(OBJ) also returns
            %   the covariance STATECOV around the state estimate. This is
            %   a measure of the uncertainty of the state estimate STATEEST.
            %   Note that not all state estimation methods support the STATECOV
            %   output. If a method does not support this output, STATECOV
            %   is set to [].
            %
            %   See also StateEstimationMethod.
        end

        function out=initialize(~) %#ok<STOUT>
            %INITIALIZE Initialize the state of the particle filter
            %   INITIALIZE(OBJ, NUMPARTICLES, MEAN, COVARIANCE)
            %   initializes the particle filter with NUMPARTICLES
            %   particles. Their initial location in the state space is
            %   determined by sampling from the multivariate normal
            %   distribution with the given MEAN and COVARIANCE.
            %   The number of state variables (NumStateVariables) is
            %   retrieved automatically based on the length of the MEAN vector.
            %   The COVARIANCE matrix has a size of
            %   NumStateVariables-by-NumStateVariables.
            %
            %   INITIALIZE(OBJ, NUMPARTICLES, STATEBOUNDS) determines the
            %   initial location of NUMPARTICLES particles by sampling from
            %   the multivariate uniform distribution with the given STATEBOUNDS.
            %   STATEBOUNDS is an NumStateVariables-by-2 array, with each
            %   row specifying the sampling limits for one state variable.
            %   The number of state variables (NumStateVariables) is
            %   retrieved automatically based on the number of rows of the
            %   STATEBOUNDS array.
            %
            %   INITIALIZE(___, Name, Value) provides additional options
            %   specified by one or more Name, Value pair arguments:
            %
            %      'CircularVariables' -
            %           Specifies which state variables are described by a
            %           circular distribution, like angles. This vector needs
            %           to have a length of NumStateVariables.
            %      'StateOrientation' -
            %           Valid values are 'column' or 'row'. If it is
            %           'column', State property and getStateEstimate
            %           method returns the states as a column vector, and
            %           the Particles property has dimensions
            %           NumStateVariables-by-NumParticles. If it is 'row',
            %           the states have the row orientation and Particles
            %           has dimensions NumParticles-by-NumStateVariables.
            %
            %
            %   Example:
            %      % Create particle filter object
            %      pf = stateEstimatorPF;
            %
            %      % Use 5,000 particles and initialize 2 state variables
            %      % by sampling from Gaussian with zero mean and covariance of 1.
            %      INITIALIZE(pf, 5000, [0 0], eye(2))
            %      pf.Particles
            %
            %      % Use 20,000 particles and initialize 3 state variables
            %      % by sampling from uniform distribution
            %      INITIALIZE(pf, 20000, [0 1; -4 1; 10 12])
            %
            %      % Initialize 3 state variables by sampling from uniform
            %      % distribution. Designate third variable circular.
            %      INITIALIZE(pf, 20000, [0 1; -4 1; -pi pi], 'CircularVariables', ...
            %          [0 0 1])
            %      pf.Particles
        end

        function out=initializeStateEstimator(~) %#ok<STOUT>
            %initializeStateEstimator Initialize the state estimator object
            %   The type of the object is determined by the current setting
            %   of the StateEstimationMethod
        end

        function out=invokeMeasurementLikelihoodFcn(~) %#ok<STOUT>
            %invokeMeasurementLikelihoodFcn
            % Subclasses can call user specified measurement likelihood fcn
            % with different syntaxes.
        end

        function out=invokeStateTransitionFcn(~) %#ok<STOUT>
            %invokeStateTransitionFcn
            % Subclasses can call user specified state transition fcn with
            % different syntaxes.
        end

        function out=predict(~) %#ok<STOUT>
            %PREDICT Calculate the predicted state in the next time step
            %   [STATEPRED, STATECOV] = PREDICT(OBJ) calculates the
            %   predicted system state STATEPRED and its associated
            %   uncertainty covariance STATECOV.
            %   PREDICT uses the system model specified in
            %   StateTransitionFcn to evolve the state of all particles and
            %   then extract the best state estimate and covariance based on the
            %   setting in StateEstimationMethod.
            %
            %   [STATEPRED, STATECOV] = PREDICT(OBJ, VARARGIN) passes
            %   all additional arguments supplied in VARARGIN to the
            %   underlying StateTransitionFcn. The first input to
            %   StateTransitionFcn is the set of particles from the
            %   previous time step, followed by all arguments in VARARGIN.
            %
            %
            %   Example:
            %
            %       % Create a particle filter with 5000 particles and initialize it
            %       pf = stateEstimatorPF
            %       pf.StateTransitionFcn = @nav.algs.gaussianMotion;
            %
            %       initialize(pf, 5000, [4 1 9], eye(3), 'StateOrientation', 'row');
            %
            %       % Run one prediction step
            %       [statePredicted, stateCov] = PREDICT(pf)
            %
            %   See also StateTransitionFcn.
        end

        function out=resample(~) %#ok<STOUT>
            %RESAMPLE Resample the current set of particles
            %   Resampling is only executed if the ResamplingPolicy
            %   verifies that a resampling trigger has been reached.
        end

        function out=sampleGaussian(~) %#ok<STOUT>
            %sampleGaussian Sample the multivariate Gaussian distribution with given mean and covariance
            %   This function assigns initial values to the particles.
        end

        function out=sampleUniform(~) %#ok<STOUT>
            %sampleUniform Sample uniformly within the given state bounds
            %   This function assigns initial values to the particles.
        end

    end
    properties
        %InternalIsStateVariableCircular - Internal storage for circular variable setting
        InternalIsStateVariableCircular;

        %InternalNumParticles - Internal storage for number of particles
        %   This is user-exposed through the NumParticles property.
        InternalNumParticles;

        %InternalNumStateVariables - Internal storage for number of state variables
        %   This is user-exposed through the NumStateVariables property.
        InternalNumStateVariables;

        %InternalParticles - Internal storage for particle values
        InternalParticles;

        %InternalResamplingMethod - Internal storage for resampling method string
        InternalResamplingMethod;

        %InternalStateEstimationMethod - Internal storage for state estimation string
        InternalStateEstimationMethod;

        %InternalWeights - Internal storage for particle weights
        InternalWeights;

        %IsStateVariableCircular - Indicator if state variables have a circular distribution
        %   The probability density function of a circular state variable
        %   takes on angular values in the range [-pi,pi].
        IsStateVariableCircular;

        %MeasurementLikelihoodFcn - Callback function calculating the likelihood of sensor measurements
        %   Once a sensor measurement is available, this callback function
        %   calculates the likelihood that the measurement is consistent
        %   with the state hypothesis of each particle.
        %
        %   The callback function should accept at least two input arguments.
        %   The first argument is the set of particles PREDICTPARTICLES that
        %   represent the predicted system state at the current time step.
        %   This is a NumParticles-by-NumStateVariables array if StateOrientation
        %   is 'row', or NumStateVariables-by-NumParticles if StateOrientation
        %   is 'column'.
        %   MEASUREMENT is the state measurement at the current time step.
        %   Additional input arguments can be provided with VARARGIN (these
        %   are passed through to the correct function).
        %   The callback needs to return exactly one output,
        %   LIKELIHOOD, a vector with NumParticles length, which is the
        %   likelihood of the given MEASUREMENT for each particle state
        %   hypothesis.
        %
        %   The function signature is as follows:
        %
        %      function LIKELIHOOD = measurementLikelihoodFcn(PREDICTPARTICLES, MEASUREMENT, VARARGIN)
        %
        %   See also correct.
        MeasurementLikelihoodFcn;

        %NumParticles - Number of particles used in the filter
        %   Each particle represents a state hypothesis.
        NumParticles;

        %NumStateVariables - Number of state variables for the particle filter
        %   The state is comprised of this number of state
        %   variables.
        NumStateVariables;

        %Particles - Array of particle values
        %   This is a NumParticles-by-NumStateVariables array if
        %   StateOrientation is 'row', or NumStateVariables-by-NumParticles
        %   array if StateOrientation is 'column'.
        %
        %   Each row or column corresponds to the state hypothesis of a
        %   single particle.
        Particles;

        %ResamplingMethod - Method used for particle resampling
        %   Possible choices are 'multinomial', 'systematic', 'stratified',
        %   and 'residual'.
        %
        %   Default: 'multinomial'
        ResamplingMethod;

        %ResamplingPolicy - Policy settings that determine when to trigger resampling
        %   The resampling can be triggered either at fixed intervals or
        %   dynamically based on the number of effective particles.
        ResamplingPolicy;

        %State - Current state estimate
        %   Current state estimate, calculated from Particles and Weight
        %   per StateEstimationMethod. It is 1-by-NumStateVariables if
        %   StateOrientation is 'row', NumStateVariables-by-1 if
        %   StateOrientation is 'column'.
        State;

        %StateCovariance - Current state estimation error covariance
        %   Current state estimation error covariance, calculated from
        %   Particles and Weight per StateEstimationMethod. It is a
        %   NumStateVariables-by-NumStateVariables array.
        StateCovariance;

        %StateEstimationMethod - Method used for state estimation
        %   Possible choices are 'mean', 'maxweight'.
        %
        %   Default: 'mean'
        StateEstimationMethod;

        %StateOrientation - Orientation of states in the Particles property
        %   Possible choices are 'column' or 'row'
        %
        %   Default: 'column'
        StateOrientation;

        %StateTransitionFcn - Callback function calculating the state transition
        %   The state transition function evolves the system state for each
        %   particle.
        %
        %   The callback function should accept at least one input arguments.
        %   The first argument is the set of particles PREVPARTICLES that
        %   represent the system state at the previous time step. This is a
        %   NumParticles-by-NumStateVariables array if StateOrientation is
        %   'row', or NumStateVariables-by-NumParticles if StateOrientation
        %   is 'column'.
        %   Additional input arguments can be provided with VARARGIN (these
        %   are passed to the predict function).
        %   The callback needs to return exactly one output, PREDICTPARTICLES,
        %   which is the set of predicted particle locations for the
        %   current time step (array with same dimensions as PREVPARTICLES).
        %
        %   The function signature is as follows:
        %
        %      function PREDICTPARTICLES = stateTransitionFcn(PREVPARTICLES, VARARGIN)
        %
        %   See also predict.
        StateTransitionFcn;

        %Weights - Vector of particle weights
        %   Vector of particle weights. It is NumParticles-by-1 if
        %   StateOrientation is 'row'. Then each weight is associated with
        %   the particle in the same row in Particles.
        %
        %   If StateOrientation is 'column', it is 1-by-NumParticles and
        %   each weight is associated with the particle in the same column
        %   in Particles.
        Weights;

    end
end
