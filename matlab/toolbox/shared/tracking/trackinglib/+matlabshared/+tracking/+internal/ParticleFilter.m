classdef (Hidden) ParticleFilter < handle & matlabshared.tracking.internal.CustomDisplay
    %ParticleFilter Create a particle filter state estimator
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
    %   PF = matlabshared.tracking.internal.ParticleFilter creates a
    %   ParticleFilter object PF. Modify the StateTransitionFcn and
    %   MeasurementLikelihoodFcn to customize the particle filter's system
    %   and measurement models. Use the initialize method to initialize the
    %   particles with a known mean and covariance or uniformly distributed
    %   within defined state bounds.
    %
    %
    %   ParticleFilter properties:
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
    %   ParticleFilter methods:
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
    %       pf = matlabshared.tracking.internal.ParticleFilter
    %
    %       % Set the StateTransitionFcn and MeasurementFcn
    %       pf.StateTransitionFcn = @(varargin)matlabshared.tracking.internal.gaussianMotion(pf, varargin{:});
    %       pf.MeasurementLikelihoodFcn = @(varargin)matlabshared.tracking.internal.fullStateMeasurement(pf, varargin{:});
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
    
    %#codegen
    
    
    %% Public Particle Filter Properties
    properties (Dependent)
        %NumStateVariables - Number of state variables for the particle filter
        %   The state is comprised of this number of state
        %   variables.
        NumStateVariables
        
        %NumParticles - Number of particles used in the filter
        %   Each particle represents a state hypothesis.
        NumParticles
    end
    
    properties
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
        StateTransitionFcn
        
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
        MeasurementLikelihoodFcn
    end
    
    properties (Dependent)
        %IsStateVariableCircular - Indicator if state variables have a circular distribution
        %   The probability density function of a circular state variable
        %   takes on angular values in the range [-pi,pi].
        IsStateVariableCircular
    end
    
    properties
        %ResamplingPolicy - Policy settings that determine when to trigger resampling
        %   The resampling can be triggered either at fixed intervals or
        %   dynamically based on the number of effective particles.
        ResamplingPolicy
    end
    
    properties (Dependent)
        %ResamplingMethod - Method used for particle resampling
        %   Possible choices are 'multinomial', 'systematic', 'stratified',
        %   and 'residual'.
        %
        %   Default: 'multinomial'
        ResamplingMethod
        
        %StateEstimationMethod - Method used for state estimation
        %   Possible choices are 'mean', 'maxweight'.
        %
        %   Default: 'mean'
        StateEstimationMethod
        
        %StateOrientation - Orientation of states in the Particles property
        %   Possible choices are 'column' or 'row'
        %
        %   Default: 'column'
        StateOrientation
    end
    
    properties (Dependent)
        %Particles - Array of particle values
        %   This is a NumParticles-by-NumStateVariables array if
        %   StateOrientation is 'row', or NumStateVariables-by-NumParticles
        %   array if StateOrientation is 'column'.
        %
        %   Each row or column corresponds to the state hypothesis of a
        %   single particle.
        Particles
        
        %Weights - Vector of particle weights
        %   Vector of particle weights. It is NumParticles-by-1 if
        %   StateOrientation is 'row'. Then each weight is associated with
        %   the particle in the same row in Particles.
        %
        %   If StateOrientation is 'column', it is 1-by-NumParticles and
        %   each weight is associated with the particle in the same column
        %   in Particles.
        Weights
    end
    
    properties (Dependent, SetAccess=private)
        %State - Current state estimate
        %   Current state estimate, calculated from Particles and Weight
        %   per StateEstimationMethod. It is 1-by-NumStateVariables if
        %   StateOrientation is 'row', NumStateVariables-by-1 if
        %   StateOrientation is 'column'.
        State
        
        %StateCovariance - Current state estimation error covariance
        %   Current state estimation error covariance, calculated from
        %   Particles and Weight per StateEstimationMethod. It is a
        %   NumStateVariables-by-NumStateVariables array.
        StateCovariance
    end
    
    %% Internal Storage Properties
    % These are used for storing data of dependent properties and to avoid
    % order-dependency in initialization.
    properties (Access = protected)
        %InternalNumStateVariables - Internal storage for number of state variables
        %   This is user-exposed through the NumStateVariables property.
        InternalNumStateVariables
        
        %InternalNumParticles - Internal storage for number of particles
        %   This is user-exposed through the NumParticles property.
        InternalNumParticles
        
        %InternalIsStateVariableCircular - Internal storage for circular variable setting
        InternalIsStateVariableCircular
        
        %InternalResamplingMethod - Internal storage for resampling method string
        InternalResamplingMethod
        
        %InternalStateEstimationMethod - Internal storage for state estimation string
        InternalStateEstimationMethod
        
        %InternalParticles - Internal storage for particle values
        InternalParticles
        
        %InternalWeights - Internal storage for particle weights
        InternalWeights
    end
    
    %% Probability Distributions
    % These are used for initial sampling. They are also accessible to tests.
    % The properties are function handles, since we need to know the number
    % of random variables at construction time.
    properties (Access = {?matlabshared.tracking.internal.ParticleFilter, ?matlab.unittest.TestCase})
        %UniformDistribution - Object used for uniform sampling of linear state variables
        UniformDistribution
        
        %WrappedUniformDistribution - Object used for uniform sampling of circular state variables
        WrappedUniformDistribution
        
        %NormalDistribution - Object used for Gaussian sampling of linear state variables
        NormalDistribution
        
        %WrappedNormalDistribution - Object used for Gaussian sampling of circular state variables
        WrappedNormalDistribution
    end
    
    %% Helper Classes
    % Classes used for input parsing, resampling, and state estimation.
    % They are also accessible to tests.
    properties (Access = {?matlabshared.tracking.internal.ParticleFilter, ?matlab.unittest.TestCase})
        %InputParser - Helper object for input parsing
        %   This object has to be derived from matlabshared.tracking.internal.ParticleFilterInputParser.
        InputParser
        
        %Resampler - Helper object used for resampling
        %   This object has to be derived from matlabshared.tracking.internal.Resampler.
        Resampler
        
        %StateEstimator - Helper object used for state estimation
        %   This object has to be derived from matlabshared.tracking.internal.StateEstimator.
        StateEstimator
        
        %ParticleManager - Helper object used for row versus column state orientation
        %   This object has to be derived from matlabshared.tracking.internal.ParticleManager
        ParticleManager
    end
    
    %% Constructor and Initialization
    methods
        function obj = ParticleFilter(stateTransitionFcn,measurementLikelihoodFcn)
            %ParticleFilter Constructor for object
            
            coder.internal.assert(nargin==0 || nargin==2, ...
                'shared_tracking:particle:ConstructorWrongNargin');
            if nargin<2
                measurementLikelihoodFcn = [];
                stateTransitionFcn = [];
            end
            
            % Initialize input parser object
            obj.InputParser = matlabshared.tracking.internal.ParticleFilterInputParser;
            
            % Initialize the resampling policy object
            obj.ResamplingPolicy = obj.defaultResamplingPolicy;
            
            % Set default algorithms for resampling and state estimation
            obj.ResamplingMethod = obj.defaultResamplingMethod;
            obj.StateEstimationMethod = obj.defaultStateEstimationMethod;
            
            % Assign *Fcns only if they are specified
            if ~isempty(stateTransitionFcn)
                obj.StateTransitionFcn = stateTransitionFcn;
            end
            if ~isempty(measurementLikelihoodFcn)
                obj.MeasurementLikelihoodFcn = measurementLikelihoodFcn;
            end
        end
        
        function initialize(obj, numParticles, varargin)
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
            %      pf = matlabshared.tracking.internal.ParticleFilter;
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
            
            % Check range of possible input values.
            % The function has 3 inputs when called with stateBounds
            % The function has 8 inputs when called with mean, covariance
            % and two name-value pairs.
            narginchk(3,8);
            
            [tunableInputs,nontunableInputs] = obj.InputParser.parseInitializeInputs(obj.defaultStateOrientation, numParticles, varargin{:});
            assert(~isempty(tunableInputs.IsStateVariableCircular));
            assert(tunableInputs.NumStateVariables > 0);
            
            % Assign state orientation
            obj.ParticleManager = matlabshared.tracking.internal.ParticleFilter.initializeParticleManager(nontunableInputs.IsStateOrientationColumn);

            % Assign basic particle filter properties
            obj.InternalNumParticles = tunableInputs.NumParticles;
            obj.InternalNumStateVariables = tunableInputs.NumStateVariables;
            
            % Set the internal variables directly, since we already checked for
            % validity in input parsing.
            obj.InternalIsStateVariableCircular = tunableInputs.IsStateVariableCircular;
            
            % Initialize distributions
            numCircular = nnz(tunableInputs.IsStateVariableCircular);
            numNonCircular = numel(tunableInputs.IsStateVariableCircular) - numCircular;
            obj.UniformDistribution = matlabshared.tracking.internal.UniformDistribution(max(1,numNonCircular));
            obj.WrappedUniformDistribution = matlabshared.tracking.internal.WrappedUniformDistribution(max(1,numCircular));
            obj.NormalDistribution = matlabshared.tracking.internal.NormalDistribution(max(1,numNonCircular));
            obj.WrappedNormalDistribution = matlabshared.tracking.internal.WrappedNormalDistribution(max(1,numCircular));
            
            % Initialize weights. 
            % * Only double precision variables are used in command-line PF
            dataType = 'double';
            obj.InternalWeights = obj.ParticleManager.getUniformWeights(tunableInputs.NumParticles, dataType);
            
            % Initialize particles
            %
            % allocateMemoryParticles uses coder.nullcopy to skip unnecessary
            % initialization
            obj.InternalParticles = obj.ParticleManager.allocateMemoryParticles(tunableInputs.NumParticles, tunableInputs.NumStateVariables, dataType);
            
            if tunableInputs.UsesStateBounds
                % Sample uniformly within the state bounds that the user specified
                obj.sampleUniform(tunableInputs.StateBounds, obj.IsStateVariableCircular);
                return
            end
            
            % Sample from a normal distribution with mean and covariance
            assert(~isempty(tunableInputs.Mean));
            assert(~isempty(tunableInputs.Covariance));
            obj.sampleGaussian(tunableInputs.Mean, tunableInputs.Covariance, obj.IsStateVariableCircular);
        end
    end
    
    %% Prediction, Correction, and State Estimation
    methods
        function [statePred, stateCov] = predict(obj, varargin)
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
            %       pf = matlabshared.tracking.internal.ParticleFilter
            %       pf.StateTransitionFcn = @(varargin)matlabshared.tracking.internal.gaussianMotion(pf, varargin{:});
            %
            %       initialize(pf, 5000, [4 1 9], eye(3), 'StateOrientation', 'row');
            %
            %       % Run one prediction step
            %       [statePredicted, stateCov] = PREDICT(pf)
            %
            %   See also StateTransitionFcn.
            
            % The order of operations in this function corresponds to the
            % "Generic Particle Filter" Algorithm 3 in reference [1].
            
            nargoutchk(0,2);
            
            % initialize() must have been called at least once before this operation
            obj.assertInitializeIsCalledAtLeastOnce();
            
            % Evolve state of each particle
            predictParticles = obj.invokeStateTransitionFcn(varargin{:});
            if any(size(predictParticles) ~= size(obj.InternalParticles))
                coder.internal.error(...
                'shared_tracking:particle:PredParticlesWrongSize', ...
                sprintf('(%g-by-%g)', size(obj.InternalParticles,1), size(obj.InternalParticles,2)), ...
                sprintf('(%g-by-%g)', size(predictParticles,1), size(predictParticles,2)));
            end
            
            % Assign predicted particles
            %
            % Already performed the size check, assign InternalParticles
            obj.InternalParticles = predictParticles;
            
            % Wrap all circular variables
            if any(obj.InternalIsStateVariableCircular)
                obj.InternalParticles = obj.ParticleManager.setStates(...
                    obj.InternalParticles, obj.InternalIsStateVariableCircular, ...
                    matlabshared.tracking.internal.wrapToPi(obj.ParticleManager.getStates(obj.InternalParticles, obj.InternalIsStateVariableCircular))...
                    );
            end
            
            % Do not extract state estimate if not requested by user
            if nargout == 0
                return;
            end
            
            if nargout == 1
                % Return only state estimate
                statePred = obj.getStateEstimate;
            elseif nargout == 2
                % Also return state covariance
                [statePred, stateCov] = obj.getStateEstimate;
            end
            
        end
        
        function [stateCorr, stateCov] = correct(obj, measurement, varargin)
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
            %       pf = matlabshared.tracking.internal.ParticleFilter
            %       pf.StateTransitionFcn = @(varargin)matlabshared.tracking.internal.gaussianMotion(pf, varargin{:});
            %       pf.MeasurementLikelihoodFcn = @(varargin)matlabshared.tracking.internal.fullStateMeasurement(pf, varargin{:});
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
            
            % The order of operations in this function correspond to the
            % "Generic Particle Filter" Algorithm 3 in reference [1].
            
            nargoutchk(0,2);
            
            % initialize() must have been called at least once before this operation
            obj.assertInitializeIsCalledAtLeastOnce();                   
            
            
            % Determine likelihood of measurement for each particle
            lhood = obj.invokeMeasurementLikelihoodFcn(measurement, varargin{:});
            if length(lhood) ~= obj.NumParticles
                coder.internal.error(...
                'shared_tracking:particle:LikelihoodWrongSize', ...
                sprintf('%g ', obj.NumParticles),...
                sprintf('%g ', length(lhood)));
            end
            
            % Always add some small fraction to the likelihoods to avoid
            % a singularity when the weights are normalized.
            %
            % Ensure the result follows the orientation of weight
            % regardless of the orientation of likelihood vector
            %
            % Already verified numel of lhood, assign IntervalWeights
            obj.InternalWeights = obj.ParticleManager.weightTimesLikelihood(obj.InternalWeights, lhood + 1e-99);
            
            % Normalize weights, so they sum up to 1
            obj.InternalWeights = obj.InternalWeights / sum(obj.InternalWeights);
            
            % Extract state estimate. Doing this before any resampling is
            % suggested by reference [2] on page 27 because resampling
            % brings extra random variations to the current particles.
            
            % Only run state estimation if user requested outputs
            if nargout == 1
                % Return only state estimate
                stateCorr = obj.getStateEstimate;
            elseif nargout == 2
                % Also return state covariance
                [stateCorr, stateCov] = obj.getStateEstimate;
            end
            
            % Trigger resampling if determined by the policy
            obj.resample;
        end
        
        function [stateEst, stateCov] = getStateEstimate(obj)
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
            
            nargoutchk(0,2);
            
            % initialize() must have been called at least once before this operation
            obj.assertInitializeIsCalledAtLeastOnce();
            
            % Call special method in code generation
            if ~coder.target('MATLAB')
                [stateEst,stateCov] = obj.estimateCodegen;
                return;
            end
            
            % Always return state estimate
            % Pass internal variables for performance reasons
            if nargout <= 1
                stateEst = obj.StateEstimator.estimate(...
                    obj.ParticleManager, obj.InternalParticles, ...
                    obj.InternalWeights, obj.InternalIsStateVariableCircular);
            elseif nargout == 2
                [stateEst, stateCov] = obj.StateEstimator.estimate(...
                    obj.ParticleManager, obj.InternalParticles, ...
                    obj.InternalWeights, obj.InternalIsStateVariableCircular);
            end
            
        end
        
    end
    
    %% Clone and Copy Methods
    methods
       function cObj = clone(obj)
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
           %           
          cObj = copy(obj);
       end

        function cObj = copy(obj)
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
            
            if ~isscalar(obj)
                coder.internal.error('shared_tracking:particle:PolicyCopyNotScalar', 'ParticleFilter');
            end
            
            % Create a new object with the same properties
            % Use the object's runtime class to allow copying of derived
            % classes.
            fcnClassName = str2func(class(obj));
            cObj = fcnClassName();
            
            % Preserve deleted handle
            if coder.target('MATLAB')
                % isvalid and delete are not supported in code generation
                if ~obj.isvalid
                    cObj.delete;
                    return;
                end
            end
            
            % Copy all properties that don't need a deep copy
            %
            % Copy only if the properties were already set. This avoids
            % writing [] to them. This is needed to allow operations such
            % as following during codegen:
            %
            % X = particleFilter();
            % Y = copy(X);
            % Y.StateTransitionFcn = @myFcn;
            ppProperties = {
                'ParticleManager',... (1)
                'StateTransitionFcn','MeasurementLikelihoodFcn',...
                'InternalNumStateVariables','InternalNumParticles'...
                'InternalIsStateVariableCircular',...
                'InternalResamplingMethod',...
                'InternalStateEstimationMethod',...
                'InternalParticles','InternalWeights',...
                'ResamplingMethod','StateEstimationMethod'}; % (2)
            % It is likely a good idea to copy (1) first as it is
            % responsible for getting/setting other properties such as
            % Particles and Weights. Order of assignments here does not
            % matter today, but this should keep things more robust.
            %
            % (1), (2) recreates the underlying objects
            for kk = coder.unroll(1:numel(ppProperties))
                % Copy only if the prop was set in the source obj
                if coder.internal.is_defined(obj.(ppProperties{kk}))
                    cObj.(ppProperties{kk}) = obj.(ppProperties{kk});
                end
            end
            
            % Properties that need a deep copy
            deepCopyProperties = {...
                'UniformDistribution','NormalDistribution',...
                'WrappedUniformDistribution','WrappedNormalDistribution',...
                'ResamplingPolicy'};
            for kk = coder.unroll(1:numel(deepCopyProperties))
                % Copy only if the prop was set in the source obj
                if coder.internal.is_defined(obj.(deepCopyProperties{kk}))
                    cObj.(deepCopyProperties{kk}) = obj.(deepCopyProperties{kk}).copy;
                end
            end
        end
    end
    
    %% Property Getters and Setters
    methods
        function numVars = get.NumStateVariables(obj)
            %get.NumStateVariables Get number of state variables from internal storage
            numVars = obj.InternalNumStateVariables;
        end
        
        function set.NumStateVariables(obj, ~)
            %set.NumStateVariables Set number of state variables
            %   This setter always displays an error and point users to
            %   the initialize method for changing the value of this
            %   property.
            
            ex = MException(message('shared_tracking:particle:ReadOnlyPropertySeeInitialize', ...
                'NumStateVariables', obj.getFormattedMethodName(class(obj), 'initialize') ));
            throwAsCaller(ex);
        end
        
        function numParticles = get.NumParticles(obj)
            %get.NumParticles Get number of particles from internal storage
            numParticles = obj.InternalNumParticles;
        end
        
        function set.NumParticles(obj, ~)
            %set.NumParticles Set number of particles that the filter uses
            %   This setter always displays an error and point users to
            %   the initialize method for changing the value of this
            %   property.
            
            ex = MException(message('shared_tracking:particle:ReadOnlyPropertySeeInitialize', ...
                'NumParticles', obj.getFormattedMethodName(class(obj), 'initialize') ));
            throwAsCaller(ex);
        end
        
        function set.StateTransitionFcn(obj, stateTransitionFcn)
            %set.StateTransitionFcn Set state transition function handle
            validateattributes(stateTransitionFcn, {'function_handle'}, {'nonempty'}, 'ParticleFilter', 'StateTransitionFcn');
            obj.StateTransitionFcn = stateTransitionFcn;
        end
        
        function set.MeasurementLikelihoodFcn(obj, measLhoodFcn)
            %set.MeasurementLikelihoodFcn Set measurement likelihood function handle
            validateattributes(measLhoodFcn, {'function_handle'}, {'nonempty'}, 'ParticleFilter', 'MeasurementLikelihoodFcn');
            obj.MeasurementLikelihoodFcn = measLhoodFcn;
        end
        
        function set.ResamplingPolicy(obj, policy)
            %set.ResamplingPolicy Set resampling policy object
            validateattributes(policy, {'matlabshared.tracking.internal.ResamplingPolicy'}, {'scalar','nonempty'}, 'ParticleFilter', 'ResamplingPolicy');
            obj.ResamplingPolicy = policy;
        end
        
        function resampleMethod = get.ResamplingMethod(obj)
            %get.ResamplingMethod Get resampling algorithm from internal storage
            resampleMethod = obj.InternalResamplingMethod;
        end
        
        function set.ResamplingMethod(obj, resampleMethod)
            %set.ResamplingMethod Set resampling algorithm
            validMethod = validatestring(resampleMethod, {'multinomial', ...
                'systematic','stratified','residual'}, 'ParticleFilter', 'ResamplingMethod');
            
            % Declare validMethod variable as variable-sized. This will
            % also ensure that codegen recognizes the
            % InternalResamplingMethod as being variable-sized.
            coder.varsize('validMethod', [1 20], [0 1]);
            obj.InternalResamplingMethod = validMethod;
            
            if coder.target('MATLAB')
                obj.Resampler = matlabshared.tracking.internal.ParticleFilter.initializeResampler(validMethod);
            end
        end
        
        function estMethod = get.StateEstimationMethod(obj)
            %get.StateEstimationMethod Get state estimation algorithm from internal storage
            estMethod = obj.InternalStateEstimationMethod;
        end
        
        function set.StateEstimationMethod(obj, estMethod)
            %set.StateEstimationMethod Set state estimation algorithm
            validMethod = validatestring(estMethod, {'mean', 'maxweight'}, ...
                'ParticleFilter', 'StateEstimationMethod');
            
            % Declare validMethod variable as variable-sized. This will
            % also ensure that codegen recognizes the
            % InternalStateEstimationMethod as being variable-sized.
            coder.varsize('validMethod', [1 20], [0 1]);
            obj.InternalStateEstimationMethod = validMethod;
            
            if coder.target('MATLAB')
                obj.StateEstimator = obj.initializeStateEstimator(validMethod);
            end
        end
        
        function estMethod = get.StateOrientation(obj)
            %get.StateOrientation Get state orientation from internal storage
            if coder.internal.is_defined(obj.ParticleManager)
                estMethod = obj.ParticleManager.StateOrientation;
            else
                estMethod = [];
            end
        end
        
        function set.StateOrientation(obj, ~)
            %set.StateEstimationMethod Set state orientation
            %   This setter always displays an error and point users to the
            %   initialize method for changing the value of this property.
            
            ex = MException(message('shared_tracking:particle:ReadOnlyPropertySeeInitialize', ...
                'StateOrientation', obj.getFormattedMethodName(class(obj), 'initialize') ));
            throwAsCaller(ex);
        end
        
        function particles = get.Particles(obj)
            %get.Particles Get particle values from internal storage
            particles = obj.InternalParticles;
        end
        
        function set.Particles(obj, particles)
            %set.Particles Set particle values (size has to be maintained)
            
            % initialize() must have been called at least once before this operation
            obj.assertInitializeIsCalledAtLeastOnce();
            
            validSize = obj.ParticleManager.getValidParticlesSize(obj.NumParticles, obj.NumStateVariables);
            validateattributes(particles, {'numeric'}, {'size', validSize}, ...
                'ParticleFilter', 'Particles');
            
            obj.InternalParticles = double(particles);
        end
        
        function weights = get.Weights(obj)
            %get.Weights Get particle weights from internal storage
            weights = obj.InternalWeights;
        end
        
        function set.Weights(obj, weights)
            %set.Weights Set particle weights (size has be maintained)
            
            % initialize() must have been called at least once before this operation
            obj.assertInitializeIsCalledAtLeastOnce();
            
            validateattributes(weights, {'numeric'}, {'vector', 'numel', obj.NumParticles}, ...
                'ParticleFilter', 'Weights');
            
            % Always store weights as column vector
            obj.InternalWeights = obj.ParticleManager.orientWeights(double(weights));
        end
        
        function val = get.State(obj)
            %get.State Get method for State
            val = obj.getStateEstimate();
        end
        
        function val = get.StateCovariance(obj)
            %get.State Get method for StateCovariance
            [~,val] = obj.getStateEstimate();
        end
        
        function isVarCirc = get.IsStateVariableCircular(obj)
            %get.IsStateVariableCircular Get setting for circular state variables
            isVarCirc = obj.InternalIsStateVariableCircular;
        end
        
        function set.IsStateVariableCircular(obj, ~)
            %set.IsStateVariableCircular Set circular state variables.
            %   This setter always displays an error and point users to
            %   the initialize method for changing the value of this
            %   property.
            
            ex = MException(message('shared_tracking:particle:ReadOnlyPropertySeeInitialize', ...
                'IsStateVariableCircular', obj.getFormattedMethodName(class(obj), 'initialize') ));
            throwAsCaller(ex);
        end
        
        function set.InputParser(obj, pfInputParser)
            validateattributes(pfInputParser, {'matlabshared.tracking.internal.ParticleFilterInputParser'}, {'scalar'}, ...
                'ParticleFilter', 'InputParser');
            obj.InputParser = pfInputParser;
        end
        
        function set.Resampler(obj, resampler)
            validateattributes(resampler, {'matlabshared.tracking.internal.Resampler'}, {'scalar'}, ...
                'ParticleFilter', 'Resampler');
            obj.Resampler = resampler;
        end
        
        function set.StateEstimator(obj, estimator)
            validateattributes(estimator, {'matlabshared.tracking.internal.StateEstimator'}, {'scalar'}, ...
                'ParticleFilter', 'StateEstimator');
            obj.StateEstimator = estimator;
        end
    end
    
    %% Default Values
    % Derived classes can override these methods, if required.
    methods (Access = {?matlabshared.tracking.internal.ParticleFilter, ?matlab.unittest.TestCase})
        function numStateVariables = defaultNumStateVariables(~)
            %defaultNumStateVariables The default value for the NumStateVariables property
            numStateVariables = [];
        end
        
        function numParticles = defaultNumParticles(~)
            %defaultNumParticles The default value for the NumParticles property
            numParticles = [];
        end
        
        function stateTransFcn = defaultStateTransitionFcn(~)
            %defaultStateTransitionFcn The default value for the StateTransitionFcn property
            stateTransFcn = [];
        end
        
        function measLhoodFcn = defaultMeasurementLikelihoodFcn(~)
            %defaultMeasurementLikelihoodFcn The default value for the MeasurementLikelihoodFcn property
            measLhoodFcn = [];
        end
        
        function isVarCircular = defaultIsStateVariableCircular(~)
            %defaultIsStateVariableCircular The default value for the IsStateVariableCircular property
            isVarCircular = [];
        end
        
        function stateMean = defaultStateMean(~)
            %defaultStateMean The initial state's mean value
            %   The default is a zero mean.
            stateMean = [];
        end
        
        function stateCov = defaultStateCovariance(~)
            %defaultStateCovariance The initial covariance around DefaultStateMean
            %   The default covariance is a variance of 1 for each state variable.
            stateCov = [];
        end
        
        function resamplePolicy = defaultResamplingPolicy(~)
            %defaultResamplingPolicy The object determining when resampling should occur
            resamplePolicy = matlabshared.tracking.internal.ResamplingPolicy;
        end
        
        function resampleMethod = defaultResamplingMethod(~)
            %defaultResamplingMethod The default resampling method
            resampleMethod = 'multinomial';
        end
        
        function estMethod = defaultStateEstimationMethod(~)
            %defaultStateEstimationMethod The default state estimation method
            estMethod = 'mean';
        end
        
        function stateOrientation = defaultStateOrientation(~)
            %defaultStateOrientation The default state orientation
            stateOrientation = 'column';
        end
    end
    
    %% Internal Methods
    methods (Access = protected)
        function sampleUniform(obj, stateBounds, isCircVar)
            %sampleUniform Sample uniformly within the given state bounds
            %   This function assigns initial values to the particles.
            
            assert(size(stateBounds,1) == length(isCircVar));
            
            numCircular = sum(isCircVar);
            numNonCircular = length(isCircVar) - numCircular;
            
            % Sample for non-circular state variables
            if numNonCircular > 0
                obj.UniformDistribution.reset(numNonCircular);
                obj.UniformDistribution.RandomVariableLimits = stateBounds(~isCircVar,:);
                obj.InternalParticles = obj.ParticleManager.setStates(obj.InternalParticles, ~isCircVar, ...
                    obj.UniformDistribution.sample(obj.NumParticles, obj.ParticleManager.StateOrientation));
            end
            
            % Sample for circular state variables
            if numCircular > 0
                obj.WrappedUniformDistribution.reset(numCircular);
                obj.WrappedUniformDistribution.RandomVariableLimits = stateBounds(isCircVar,:);
                obj.InternalParticles = obj.ParticleManager.setStates(obj.InternalParticles, isCircVar, ...
                    obj.WrappedUniformDistribution.sample(obj.NumParticles, obj.ParticleManager.StateOrientation));
            end
        end
        
        function sampleGaussian(obj, initialMean, initialCovariance, isCircVar)
            %sampleGaussian Sample the multivariate Gaussian distribution with given mean and covariance
            %   This function assigns initial values to the particles.
            
            assert(length(initialMean) == length(isCircVar));
            assert(length(initialMean) == length(initialCovariance));
            
            numCircular = sum(isCircVar);
            numNonCircular = length(isCircVar) - numCircular;
            
            % Sample for non-circular state variables
            if numNonCircular > 0
                obj.NormalDistribution.reset(numNonCircular);
                obj.NormalDistribution.Mean = initialMean(~isCircVar);
                obj.NormalDistribution.Covariance = initialCovariance(~isCircVar, ~isCircVar);
                obj.InternalParticles = obj.ParticleManager.setStates(obj.InternalParticles, ~isCircVar, ...
                    obj.NormalDistribution.sample(obj.NumParticles, obj.ParticleManager.StateOrientation));
            end
            
            % Sample for circular state variables
            if numCircular > 0
                obj.WrappedNormalDistribution.reset(numCircular);
                obj.WrappedNormalDistribution.Mean = initialMean(isCircVar);
                obj.WrappedNormalDistribution.Covariance = initialCovariance(isCircVar, isCircVar);
                obj.InternalParticles = obj.ParticleManager.setStates(obj.InternalParticles, isCircVar, ...
                    obj.WrappedNormalDistribution.sample(obj.NumParticles, obj.ParticleManager.StateOrientation));
            end
        end
        
        function resample(obj)
            %RESAMPLE Resample the current set of particles
            %   Resampling is only executed if the ResamplingPolicy
            %   verifies that a resampling trigger has been reached.
            
            isTriggered = obj.ResamplingPolicy.isResamplingTriggered(obj.InternalWeights);
            
            if isTriggered
                % Resample all particles. This also equalizes all weights.
                if coder.target('MATLAB')
                    sampleIndices = obj.Resampler.resample(obj.InternalWeights, obj.NumParticles);
                else
                    sampleIndices = obj.resampleCodegen;
                end
                obj.InternalParticles = obj.ParticleManager.resampleParticles(obj.InternalParticles, sampleIndices);
                obj.InternalWeights = obj.ParticleManager.getUniformWeights(obj.NumParticles, class(obj.InternalWeights));
            end
        end
        
        function stateEstObj = initializeStateEstimator(~, stateEstimationMethod)
            %initializeStateEstimator Initialize the state estimator object
            %   The type of the object is determined by the current setting
            %   of the StateEstimationMethod
            
            switch stateEstimationMethod
                case 'mean'
                    stateEstObj = matlabshared.tracking.internal.MeanStateEstimator;
                case 'maxweight'
                    stateEstObj = matlabshared.tracking.internal.MaxWeightStateEstimator;
                otherwise
                    assert(false);
            end
        end
                
        function propGroups = getPropertyGroups(obj)
            %getPropertyGroups Custom display for the object
            %
            % Do not calculate State and StateCovariance when displaying
            % the object
            callGetStateEstimateStr = getString(message('shared_tracking:particle:CallGetStateEstimate', ...
                obj.getFormattedMethodName(class(obj), 'getStateEstimate') ));            
            S = struct(...
                'NumStateVariables', obj.NumStateVariables,...
                'NumParticles', obj.NumParticles,...
                'StateTransitionFcn', obj.StateTransitionFcn,...
                'MeasurementLikelihoodFcn', obj.MeasurementLikelihoodFcn,...
                'IsStateVariableCircular', obj.IsStateVariableCircular,...
                'ResamplingPolicy', obj.ResamplingPolicy,...
                'ResamplingMethod', obj.ResamplingMethod,...
                'StateEstimationMethod', obj.StateEstimationMethod,...
                'StateOrientation', obj.StateOrientation,...
                'Particles', obj.Particles,...
                'Weights', obj.Weights,...
                'State', callGetStateEstimateStr,...
                'StateCovariance', callGetStateEstimateStr);
            propGroups = matlab.mixin.util.PropertyGroup(S);
        end
        
        function predictParticles = invokeStateTransitionFcn(obj, varargin)
            %invokeStateTransitionFcn
            % Subclasses can call user specified state transition fcn with
            % different syntaxes.
            
            predictParticles = obj.StateTransitionFcn(obj.InternalParticles, varargin{:});
        end
        
        function lhood = invokeMeasurementLikelihoodFcn(obj, measurement, varargin)
            %invokeMeasurementLikelihoodFcn
            % Subclasses can call user specified measurement likelihood fcn
            % with different syntaxes.
            
            lhood = obj.MeasurementLikelihoodFcn(obj.InternalParticles, measurement, varargin{:});
        end
        
        function assertInitializeIsCalledAtLeastOnce(obj)
            %assertInitializeIsCalledAtLeastOnce Ensure that initialize has been called
            %   Various PF operations require initialize() to be called
            %   first, at least once. Check this via a property that is
            %   only settable in initialize(), and is surely set when
            %   initialize() is called.
            
            coder.internal.assert(coder.internal.is_defined(obj.ParticleManager), ...
                'shared_tracking:particle:MustInitializeBeforeThisOperation',...
                obj.getFormattedMethodName(class(obj), 'initialize') );        
        end
    end
    
    %% Code Generation Helpers
    methods (Access = {?matlabshared.tracking.internal.ParticleFilter, ?matlab.unittest.TestCase})
        function sampleIndices = resampleCodegen(obj)
            %resampleCodegen Resample method used in code generation
            %   Since code generation only allows assigning a single object type
            %   to variables and properties, we cannot pre-cache the
            %   Resampler. For code generation we construct and evaluate
            %   the resampling object on each invocation.
            %
            % This method must be kept in sync with initializeResampler
            % method
            
            sampleIndices = ones(1,obj.NumParticles);
            
            switch obj.InternalResamplingMethod
                case 'multinomial'
                    resampleObj = matlabshared.tracking.internal.MultinomialResampler;
                    sampleIndices = resampleObj.resample(obj.InternalWeights, obj.NumParticles);
                case 'residual'
                    resampleObj = matlabshared.tracking.internal.ResidualResampler;
                    sampleIndices = resampleObj.resample(obj.InternalWeights, obj.NumParticles);
                case 'systematic'
                    resampleObj = matlabshared.tracking.internal.SystematicResampler;
                    sampleIndices = resampleObj.resample(obj.InternalWeights, obj.NumParticles);
                case 'stratified'
                    resampleObj = matlabshared.tracking.internal.StratifiedResampler;
                    sampleIndices = resampleObj.resample(obj.InternalWeights, obj.NumParticles);
                otherwise
                    assert(false);
            end           
        end
        
        function [stateEst, stateCov] = estimateCodegen(obj)
            %estimateCodegen State estimation method used in code generation
            %   Since code generation only allows assigning a single object type
            %   to variables and properties, we cannot pre-cache the
            %   StateEstimator. For code generation we construct and evaluate
            %   the estimation object on each invocation.
            
            stateEst = 0;
            stateCov = 0;
            
            switch obj.InternalStateEstimationMethod
                case 'mean'
                    stateEstObj = matlabshared.tracking.internal.MeanStateEstimator;
                    [stateEst,stateCov] = stateEstObj.estimate(...
                        obj.ParticleManager, obj.InternalParticles, ...
                        obj.InternalWeights, obj.InternalIsStateVariableCircular);
                case 'maxweight'
                    stateEstObj = matlabshared.tracking.internal.MaxWeightStateEstimator;
                    [stateEst,stateCov] = stateEstObj.estimate(...
                        obj.ParticleManager, obj.InternalParticles, ...
                        obj.InternalWeights, obj.InternalIsStateVariableCircular);
                otherwise
                    assert(false);
            end
        end
    end
    
    %% PF block specific, and shared utilities
    methods(Hidden, Static)
        function str = getFormattedMethodName(objClass, methodName)
            % getFormattedMethodName Return a link or plain text reference to a particle filter method
            %    ParticleFilter has various messages that can contain
            %    hyperlinks that refer users to a particular method.
            %    Display links only when the feature is enabled in MATLAB.
            %    Otherwise display the method name in plain text.
            if feature('hotlinks')
                str = sprintf('<a href="matlab:helpPopup %s/%s" style="font-weight:bold">%s</a>',objClass,methodName,methodName);
            else
                str = methodName;
            end
        end
        
        function resampleObj = initializeResampler(resamplingMethod)
            %initializeResampler Initialize the resampler object
            %
            % This method must be kept in sync with resampleCodegen method
            
            switch resamplingMethod
                case 'multinomial'
                    resampleObj = matlabshared.tracking.internal.MultinomialResampler;
                case 'residual'
                    resampleObj = matlabshared.tracking.internal.ResidualResampler;
                case 'systematic'
                    resampleObj = matlabshared.tracking.internal.SystematicResampler;
                case 'stratified'
                    resampleObj = matlabshared.tracking.internal.StratifiedResampler;
                otherwise
                    assert(false);
            end
        end
        
        function particleManager = initializeParticleManager(isStateOrientationColumn)
            if isStateOrientationColumn
                particleManager = matlabshared.tracking.internal.ParticleManagerColumn;
            else
                particleManager = matlabshared.tracking.internal.ParticleManagerRow;
            end
        end
        
        
        function particles = pfBlockPredict(stateTransitionFcnH,particles,pS,varargin)
            % pfBlockPredict Prediction step for PF block
            %
            % This fcn must be kept in sync with the predict() method
            %
            % Inputs:
            %    particles - Particles before prediction
            %    pS        - Structure containing nontunable parameters
            %                 FcnName - Name of the state transition fcn, a Simulink fcn
            %                 IsStateOrientationColumn - particles is [Ns Np] if true
            %                                            particles is [Np Ns] if false
            %                 IsStateVariableCircular - [1 Ns] logical. 
            %                                           Indicates the circular states

            %#codegen
            coder.internal.prefer_const(pS);
            
            %% Setup
            % Particle manager to handle row vs column orientation
            particleManager = matlabshared.tracking.internal.ParticleFilter.initializeParticleManager(pS.IsStateOrientationColumn);
            
            %% Prediction
            % Evolve state of each particle
            particles = stateTransitionFcnH(particles,varargin{:});
            % Wrap all circular variables
            if any(pS.IsStateVariableCircular)
                particles = particleManager.setStates(...
                    particles, pS.IsStateVariableCircular, ...
                    matlabshared.tracking.internal.wrapToPi(particleManager.getStates(particles, pS.IsStateVariableCircular))...
                    );
            end
        end
        
        function [particles,weights,intervalCounter] = ...
                pfBlockCorrectAndResample(measLikelihoodFcnH,particles,weights,intervalCounter,yMeas,pM,varargin)
            % pfBlockCorrectAndResample Correction & resampling steps for the PF block
            %
            % This fcn must be kept in sync with the correct() method
            %
            % Inputs:
            %    measLikelihoodFcnH - Handle to measurement likelihood fcn
            %    particles       - Particles
            %    weights         - Weights
            %    intervalCounter - If using 'interval' resampling policy, the value of
            %                      the counter is how many correct operations were done
            %                      since the last resample operation.
            %    yMeas           - Measurement sensor
            %    pM              - Structure containing nontunable parameters
            %                        FcnName - Name of the meas. l. fcn
            %                        IsStateOrientationColumn - particles is [Ns Np] if true
            %                                                   particles is [Np Ns] if false
            %                        DataType                - 'double' or 'single'
            
            %#codegen
            coder.internal.prefer_const(pM);

            %%%%%%%%%%
            % Setup
            %%%%%%%%%%
            % Particle manager to handle row vs column orientation
            particleManager = matlabshared.tracking.internal.ParticleFilter.initializeParticleManager(pM.IsStateOrientationColumn);
            % Get the resampler
            resampler = matlabshared.tracking.internal.ParticleFilter.initializeResampler(pM.ResamplingMethod);

            %%%%%%%%%%%%
            % Correction
            %%%%%%%%%%%%
            % Get likelihoods
            lhood = measLikelihoodFcnH(particles, yMeas, varargin{:});
            % Add some small fraction to the likelihoods to avoid a
            % singularity when the weights are normalized.
            lhood = lhood + 1e-99;
            % Ensure the result follows the orientation of weight
            % regardless of the orientation of likelihood vector
            weights = particleManager.weightTimesLikelihood(weights, lhood);
            % Normalize weights, so they sum up to 1
            weights = weights / sum(weights);
            
            %%%%%%%%%%%%
            % Resampling
            %%%%%%%%%%%%
            isTriggered = false;
            switch pM.TriggerMethod
                case 'interval'
                    [isTriggered,intervalCounter] = matlabshared.tracking.internal.ResamplingPolicy.checkIntervalTrigger(intervalCounter, pM.SamplingInterval);
                case 'ratio'
                    isTriggered = matlabshared.tracking.internal.ResamplingPolicy.checkRatioTrigger(weights, pM.MinEffectiveParticleRatio);
                otherwise
                    assert(false);
            end
            if isTriggered
                sampleIndices = resampler.resample(weights, pM.NumParticles);
                particles = particleManager.resampleParticles(particles, sampleIndices);
                weights = particleManager.getUniformWeights(pM.NumParticles, class(weights));
            end
        end
    end
end
