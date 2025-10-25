classdef UnscentedKalmanFilter < handle
    %
    
    % Leave the above row empty to suppress the message: "Help for X is
    % inherited from superclass matlabshared.tracking.internal.UnscentedKalmanFilter"
    
    %UnscentedKalmanFilter   Unscented Kalman filter for object tracking
    %   This unscented Kalman filter is designed for tracking. You can use
    %   it to predict object's future location, to reduce noise in the
    %   detected location, or to help associate multiple objects with their
    %   tracks. The unscented Kalman filter is used for tracking objects
    %   that move according to a nonlinear motion model, or that are
    %   measured by a nonlinear measurement model.
    %
    %   The unscented Kalman filter algorithm implements a discrete time,
    %   nonlinear State-Space System described as follows.
    %
    %   Additive noise models:
    %      x(k) = f(x(k-1), u(k-1)) + w(k-1)         (state equation)
    %      z(k) = h(x(k)) + v(k)                     (measurement equation)
    %
    %   Non-additive noise models:
    %      x(k) = f(x(k-1), w(k-1), u(k-1))          (state equation)
    %      z(k) = h(x(k), v(k))                      (measurement equation)
    %
    %   The unscented Kalman filter attempts to estimate the uncertainty
    %   about the state, and its propagation through the nonlinear state
    %   and measurement equations, using a fixed number of "Sigma Points".
    %   These points are chosen using the Unscented Transformation, and are
    %   governed by three parameters: Alpha, Beta, and Kappa. The valid
    %   ranges of values for these parameters are (default values are in
    %   parentheses):
    %       0 <  Alpha <= 1     (1e-3)
    %       0 <= Beta           (2)
    %       0 <= Kappa <= 3     (0)
    %   See [1,2] for more information about these parameters.
    %
    %   The unscented Kalman filter algorithm involves two steps.
    %      * Predict: Using the current state to predict the next state.
    %      * Correct, also known as update: Using the current measurement,
    %           such as the detected object location, to correct the state.
    %
    %
    %   Constructing an UnscentedKalmanFilter object:
    %
    %   UKF = UnscentedKalmanFilter returns an unscented Kalman filter
    %   object with default state transition function and measurement
    %   function and assumes an additive noise model.
    %
    %   UKF = UnscentedKalmanFilter(StateTransitionFcn, MeasurementFcn,
    %   State) lets you specify the state transition function, f, and the
    %   measurement function, h. Both must be specified as
    %   function_handles. In addition, it lets you specify an initial value
    %   for the state.
    %
    %   UKF = UnscentedKalmanFilter(..., Name, Value) configures the
    %   unscented Kalman filter object properties, specified as one or more
    %   name-value pair arguments. Unspecified properties have default
    %   values.
    %
    %   Using the predict method:
    %
    %   [x_pred, P_pred] = predict(UKF) returns the prediction of state and
    %   state estimation error covariance at the next time step for a model
    %   with additive noise. The internal state and state covariance are
    %   overwritten by the prediction results.
    %
    %   [x_pred, P_pred] = predict(UKF, varargin) additionally, lets you
    %   specify any parameters that will be passed to and used by the
    %   @StateTransitionFcn.
    %
    %   Using the correct method:
    %
    %   [x_corr, P_corr] = correct(UKF, z) returns the correction of the
    %   state and the state estimation error covariance based on the
    %   current measurement z, an N-element vector. The internal state and
    %   covariance are overwritten by the corrected values.
    %
    %   [x_corr, P_corr] = correct(UKF, z, varargin) additionally, lets you
    %   specify any parameters that will be passed to and used by the
    %   @MeasurementFcn
    %
    %   Notes:
    %   ======
    %   * If the measurement exists, e.g., the object has been detected,
    %     you can call the predict method and the correct method together.
    %     If the measurement is missing, you can call the predict method
    %     but not the correct method.
    %
    %      If the object tracked by UKF is detected
    %         predict(UKF);
    %         trackedLocation = correct(UKF, objectLocation);
    %      Else
    %         trackedLocation = predict(UKF);
    %      End
    %
    %   UnscentedKalmanFilter methods:
    %
    %   predict  - Predicts the state and state estimation error covariance
    %   correct  - Corrects the state and state estimation error covariance
    %
    %   UnscentedKalmanFilter properties:
    %
    %   HasAdditiveProcessNoise     - True if process noise is additive
    %   StateTransitionFcn          - Promotes the state to next time step, (f)
    %   HasAdditiveMeasurementNoise - True if measurement noise is additive
    %   MeasurementFcn              - Calculates the measurement, (h)
    %   HasMeasurementWrapping      - True if the measurement wraps (read only)
    %   State                       - State, (x)
    %   StateCovariance             - State estimation error covariance, (P)
    %   ProcessNoise                - Process noise covariance, (Q)
    %   MeasurementNoise            - Measurement noise covariance, (R)
    %   Alpha                       - Unscented transformation parameter alpha
    %   Beta                        - Unscented transformation parameter beta
    %   Kappa                       - Unscented transformation parameter kappa
    
    %   References:
    %   [1] Eric A. Wan and Rudolph van der Merwe, "The Unscented Kalman
    %       Filter for Nonlinear Estimation", Adaptive Systems for Signal
    %       Processing, Communications, and Control, pages 153-158,
    %       AS-SPCC, IEEE, 2000.
    %   [2] Wan, Merle "The Unscented Kalman Filter", chapter in Kalman
    %       Filtering and Neural Networks, John Wiley & Sons, Inc., 2001
    %   [3] Sarkka S., "Recursive Bayesian Inference on Stochastic
    %       Differential Equations", Doctoral Dissertation, Helsinki
    %       University of Technology, 2006.
    %   [4] Rudolph van der Merwe and Eric A. Wan. 
    %       "The square-root unscented Kalman filter for state and parameter-estimation." 
    %       2001 IEEE international conference on acoustics, speech, and signal processing.
    %       Proceedings. Vol. 6. IEEE, 2001.
    
    %   Copyright 2016-2020 The MathWorks, Inc.
    
    %#codegen
    %#ok<*EMCLS>
    %#ok<*EMCA>
    %#ok<*MCSUP>
    
    %------------------------------------------------------------------------
    % Public properties
    %------------------------------------------------------------------------
    properties(Access=public, Dependent)
        %HasAdditiveProcessNoise A Boolean flag that defines whether the
        %noise affecting the state transition is additive (true) or
        %non-additive (false).
        %
        %This property can only be set during filter construction.
        HasAdditiveProcessNoise;
    end
    
    properties(Access=public)
        %StateTransitionFcn A function calculating the state at the next
        %time step (f).
        %   Specify the transition of state between times as a function
        %   that calculates an M dimensional state vector at time k given
        %   the state vector at time k-1. The function may take additional
        %   input parameters if needed, e.g., control inputs or the size of
        %   the time step.
        %
        %   If HasAdditiveProcessNoise is true, the function should have
        %   one of the following signatures:
        %       x(k) = StateTransitionFcn(x(k-1))
        %       x(k) = StateTransitionFcn(x(k-1), parameters)
        %   where:
        %       x(k) is the (estimated) state at time k.
        %       'parameters' are any additional arguments that are needed
        %       by the state transition function.
        %
        %   If HasAdditiveProcessNoise is false, the function should have
        %   one of the following signatures:
        %       x(k) = StateTransitionFcn(x(k-1), w(k-1))
        %       x(k) = StateTransitionFcn(x(k-1), w(k-1), parameters)
        %   where:
        %       x(k) is the (estimated) state at time k.
        %       w(k) is the process noise at time k.
        %       'parameters' are any additional arguments that are needed
        %       by the state transition function.
        StateTransitionFcn;
    end
    
    properties(Access=public, Dependent)
        %HasAdditiveMeasurementNoise A Boolean flag that defines whether
        %the noise affecting the measurement is additive (true) or
        %non-additive (false).
        %
        %This property can only be set during filter construction.
        HasAdditiveMeasurementNoise;
    end
    
    properties(Access=public)
        %MeasurementFcn A function calculating the measurement, (h).
        %   Specify the transition from state to measurement as a function
        %   that produces an N-element measurement vector for an
        %   M-element state. The function may take additional input
        %   parameters if needed, e.g., in order to specify the sensor
        %   position.
        %
        %   If HasAdditiveMeasurementNoise is true, the function should
        %   have one of the following signatures:
        %       z(k) = MeasurementFcn(x(k))
        %       z(k) = MeasurementFcn(x(k), parameters)
        %   where:
        %       x(k) is the (estimated) state at time k.
        %       z(k) is the (estimated) measurement at time k.
        %       parameters are any additional arguments that are needed by
        %       the measurement function.
        %
        %   If HasAdditiveMeasurementNoise is false, the function should
        %   have one of the following signatures:
        %       z(k) = MeasurementFcn(x(k), v(k))
        %       z(k) = MeasurementFcn(x(k), v(k), parameters)
        %   where:
        %       x(k) is the (estimated) state at time k.
        %       z(k) is the (estimated) measurement at time k.
        %       v(k) is the measurement noise at time k.
        %       parameters are any additional arguments that are needed by
        %       the measurement function.
        MeasurementFcn;
        
        %Alpha A parameter that determines the spread of the Sigma Points
        %      around the state. It is usually a small positive value.
        %
        %   Default: Alpha = 1e-3
        Alpha = 1e-3;
        
        %Beta A parameter that incorporates knowledge about the distribution of
        %     the state in the generation of the sigma points. For Gaussian
        %     distributions, Beta = 2 is optimal.
        %
        %   Default: Beta = 2
        Beta = 2;
        
        %Kappa A secondary scaling parameter used in the generation of the
        %      sigma points and is usually set to 0.
        %
        %   Default: Kappa = 0;
        Kappa = 0;
    end
    
    %------------------------------------------------------------------------
    % Dependent properties whose values are stored in other hidden properties
    %------------------------------------------------------------------------
    properties(Access=public, Dependent)
        %State The state (x)
        %   Specify the state as an M-element vector.
        State;
        
        %StateCovariance State estimation error covariance (P)
        %   Specify the covariance of the state estimation error as a
        %   scalar or an M-by-M matrix. M is the number of states. If you
        %   specify it as a scalar it will be extended to an M-by-M
        %   diagonal matrix.
        %
        %   Default: 1
        StateCovariance;
    end
    
    properties(Dependent)
        %ProcessNoise Process noise covariance (Q)
        %   If HasAdditiveProcessNoise is true: specify the covariance of
        %   process noise as a scalar or an M-by-M matrix, where M is the
        %   dimension of the State. If you specify it as a scalar it will
        %   be extended to an M-by-M diagonal matrix.
        %
        %   If HasAdditiveProcessNoise is false: specify the covariance of
        %   process noise as a W-by-W matrix, where W is the number of the
        %   process noise terms. In this case, ProcessNoise must be
        %   specified before the first call to the predict method. After
        %   the first assignment, you can specify it also as a scalar which
        %   will be extended to a W-by-W matrix.
        %
        %   Default: 1
        ProcessNoise;
        %MeasurementNoise Measurement noise covariance (R)
        %   If HasAdditiveMeasurementNoise is true: specify the covariance
        %   of measurement noise as a scalar or an N-by-N matrix, where N
        %   is the dimension of the measurements. If you specify it as a
        %   scalar it will be extended to an N-by-N diagonal matrix.
        %
        %   If HasAdditiveMeasurementNoise is false: specify the covariance
        %   of the measurement noise as a V-by-V matrix, where V is the
        %   number of the measurement noise terms. In this case,
        %   MeasurementNoise must be specified before the first call to the
        %   correct method. After the first assignment, you can specify it
        %   also as a scalar which will be extended to a V-by-V matrix.
        %
        %   Default: 1
        MeasurementNoise;
    end

    properties(SetAccess = protected, Dependent)
        %HasMeasurementWrapping True if the measurement wraps
        % Set this property to true if the measurement wraps. If set to
        % true, the MeasurementFcn must return two output arguments, the
        % first argument is the measurement, whereas the second output
        % argument provides the measurement bounds as an M-by-2 matrix,
        % where M is the measurement size. On each row, the first and
        % second elements are the minimum and maximum bound, respectively,
        % for the corresponding measurement dimension. You can use Inf to
        % indicate elements that are unbounded.
        % For example, a measurement function returns the azimuth and range
        % of an object relative to the sensor as [az;r]. The azimuth angle
        % wraps between -180 and 180 while the range is unbounded and
        % nonnegative. The measurement function must return as a 2nd output
        % argument  [-180 180; 0 Inf].
        % 
        % Default: false
        HasMeasurementWrapping;
    end
    
    %----------------------------------------------------------------------
    % Properties which are hidden and dependent
    %----------------------------------------------------------------------
    
    properties(Access = protected, Dependent = true)
       
        % Protected and Dependent properties for State Covariance
        pStateCovariance;
        pStateCovarianceScalar;
        
        % Protected and Dependent properties for Process Noise
        pProcessNoise;
        pProcessNoiseScalar;
        
        % Protected and Dependent properties for Measurement Noise
        pMeasurementNoise;
        pMeasurementNoiseScalar;
    end   
    
    %------------------------------------------------------------------------
    % Hidden properties used by the object
    %------------------------------------------------------------------------
    properties(Access=protected)
        pM; % Length of state
        pN; % Length of measurement
        pW; % Length of process noise
        pV; % Length of measurement noise
        pState;
        pSqrtStateCovariance;
        pSqrtStateCovarianceScalar;
        pIsSetStateCovariance = false();
        pSqrtProcessNoise;
        pSqrtProcessNoiseScalar;
        pIsSetProcessNoise = false();
        pSqrtMeasurementNoise;
        pSqrtMeasurementNoiseScalar;
        pIsSetMeasurementNoise = false();
        pHasPrediction = false();
        pIsValidStateTransitionFcn = false(); % False until validation
        pIsValidMeasurementFcn = false(); % False until validation
        pIsStateColumnVector = true();
        pPredictor;
        pCorrector;
        pDataType;
        pIsFirstCallPredict = true(); % false after calling predict once
        pIsFirstCallCorrect = true(); % false after calling correct once
        pVersion; % Property indicating version of UKF object
        pCrossCov; % Property to store the cross covariance from previous predict
    end
    
    %------------------------------------------------------------------------
    % Constant properties which store the default values
    %------------------------------------------------------------------------
    properties(Hidden, Constant=true, GetAccess=public) %Provide access to test cases
        constAlpha                          = 1e-3;
        constBeta                           = 2;
        constKappa                          = 0;
        constStateCovariance                = 1;
        constProcessNoise                   = 1;
        constMeasurementNoise               = 1;
        constHasAdditiveMeasurementNoise    = true;
        constHasAdditiveProcessNoise        = true;
        constDataType                       = 'double';
        constHasMeasurementWrapping         = false;
    end
    
    methods
        %----------------------------------------------------------------------
        % Constructor
        %----------------------------------------------------------------------
        function obj = UnscentedKalmanFilter(varargin)
            %
            
            % Leave the above row empty to suppress the message: "Help for X is
            % inherited from superclass matlabshared.tracking.internal.UnscentedKalmanFilter"
            
            % The object can be constructed with either 0, 2 or 3 inputs
            % before the first Name-Value pair. Therefore, the constructor
            % should fail if the first Name-Value pair is in place 2 (after
            % one input) or more than 4 (after more than 3 inputs).
            firstNVIndex = matlabshared.tracking.internal.findFirstNVPair(varargin{:});
            
            coder.internal.errorIf(firstNVIndex==2 || firstNVIndex>4, ...
                'shared_tracking:UnscentedKalmanFilter:invalidInputsToConstructor', firstNVIndex-1);
            
            % Parse the inputs.
            if isempty(coder.target)  % Simulation
                [stateTransitionFcn, measurementFcn, state, stateCovariance, ...
                    processNoise, measurementNoise, Alpha, Beta, Kappa, ...
                    hasAdditiveProcessNoise, hasAdditiveMeasurementNoise, dataType, ...
                    hasWrapping] ...
                    = parseInputsSimulation(obj, varargin{:});
            else                      % Code generation
                [stateTransitionFcn, measurementFcn, state, stateCovariance, ...
                    processNoise, measurementNoise, Alpha, Beta, Kappa, ...
                    hasAdditiveProcessNoise, hasAdditiveMeasurementNoise, dataType, ...
                    hasWrapping] ...
                    = parseInputsCodegen(obj, varargin{:});
            end
            
            % Set the HasAdditiveProcessNoise and
            % HasAdditiveMeasurementNoise properties before all else. These
            % are non-tunable, and needed for correct setting of the
            % remaining of the properties.
            %
            % For codegen support, these must be set during construction.
            % They cannot be changed later.
            obj.setPredictor(hasAdditiveProcessNoise);
            obj.setCorrector(hasAdditiveMeasurementNoise, hasWrapping);
            
            % Data type is determined by the state property. Rules for data
            % classes.
            % * All of the properties can be either double or single.
            %   Mixture of double and single is allowed on constructor
            %   call, but all the values will be converted to the class of
            %   the state.
            % * All of the inputs, including z, z_matrix, and u, can be
            %   double, single, or integer.
            % * The outputs have the same class as state.
            if ~isempty(state)
                classToUse = class(state);
            elseif ~isempty(dataType)
                classToUse = char(dataType); % use char even if dataType is string
            else
                classToUse = obj.constDataType;
            end
            obj.pDataType = classToUse;
            
            % Process the state and state covariance
            if ~isempty(state)
                % Set state first so that filter knows state dimensions
                obj.State = cast(state, classToUse);
            end
            
            % Initialization for pSqrtStateCovarianceScalar
            obj.pSqrtStateCovarianceScalar = cast(obj.constStateCovariance, classToUse);
            
            if ~isempty(stateCovariance)
                % Validation and scalar expansion in set.X
                obj.StateCovariance = cast(stateCovariance, classToUse);
            elseif coder.internal.is_defined(obj.pM)
                % User did not provide P, but we know the state dims M.
                % Make the default assignment
                obj.StateCovariance = matlabshared.tracking.internal.expandScalarValue(...
                    cast(obj.constStateCovariance, classToUse), ...
                    [obj.pM, obj.pM]);
            end
            
            % Copy StateTransitionFcn and MeasurementFcn. The validation is
            % done on set.X
            %
            % Do not initialize the properties for code generation, since
            % function handles can only be assigned once.
            if ~isempty(stateTransitionFcn)
                obj.StateTransitionFcn = stateTransitionFcn;
            end
            if ~isempty(measurementFcn)
                obj.MeasurementFcn     = measurementFcn;
            end
            
            % Since there is no way of validating the function handles
            % before the first call that uses them, keep their IsValid
            % state as false.
            obj.pIsValidMeasurementFcn = false;
            obj.pIsValidStateTransitionFcn = false;
            
            % Validate and copy the Unscented Transformation parameters:
            % Alpha, Beta and Kappa. Validation is done in the set method.
            obj.Alpha = cast(Alpha, classToUse);
            obj.Beta  = cast(Beta, classToUse);
            obj.Kappa = cast(Kappa, classToUse);
            
            % Set the ProcessNoise. The validations and scalar expansion
            % (if needed) are in the set.ProcessNoise
            %
            % pSqrtProcessNoiseScalar: See notes for pSqrtMeasurementNoiseScalar below 
            obj.pSqrtProcessNoiseScalar = cast(obj.constProcessNoise, classToUse);
            
            if ~isempty(processNoise)
                obj.ProcessNoise = cast(processNoise, classToUse);
            elseif coder.internal.is_defined(obj.pW)
                % User did not provide Q, but we know the noise dims W.
                % Make the default assignment.
                obj.ProcessNoise = matlabshared.tracking.internal.expandScalarValue(...
                    cast(obj.constProcessNoise, classToUse), ...
                    [obj.pW, obj.pW]);
            end
            
            % Set the MeasurementNoise. The validations and scalar expansion
            % (if needed) are in set.MeasurementNoise
            %
            % Always set pMeasurementNoiseScalar: For additive noise, when
            % the measurement dimensions are known and user didn't set
            % MeasurementNoise, this is scalar expanded in correct() or
            % distance(). Set it to the default value. If the user provided
            % another scalar value, this is overwritten in
            % set.MeasurementNoise.
            %
            % Assign MeasurementNoise only if user provided it. Otherwise
            % we don't know its dimensions. For codegen support we must
            % make the assignment only when the dimensions are known

            % Don't set pV as tunable or non-tunable on construction, just set
            % the noise directly for now. The decision of pV non-tunability is
            % deferred until setMeasurementSizes is called, or any
            % measurement-related methods (correct/residual etc.) is called.
            if ~isempty(measurementNoise)
                measurementNoise = matlabshared.tracking.internal.cholPSD(cast(measurementNoise,classToUse));
                if isscalar(measurementNoise)
                    obj.pSqrtMeasurementNoiseScalar = measurementNoise;
                else
                    obj.pSqrtMeasurementNoise = measurementNoise;
                    obj.pSqrtMeasurementNoiseScalar = cast(-1,classToUse);
                end
            elseif coder.internal.is_defined(obj.pV)
                % User did not provide R, but we know the noise dims V.
                % Make the default assignment.
                obj.MeasurementNoise = matlabshared.tracking.internal.expandScalarValue(...
                    cast(obj.constMeasurementNoise, classToUse), ...
                    [obj.pV, obj.pV]);
            elseif obj.HasAdditiveMeasurementNoise
                obj.pSqrtMeasurementNoiseScalar = cast(obj.constMeasurementNoise, classToUse);
            end
            
            % Keeps track of prediction state
            obj.pHasPrediction = false;
            
            % Indicate current version of UKF object
            %   Evolution of UKF Objects
            %   * (V1) - R2016b to R2020a : Initial version with non-square-root
            %                               implementation
            %   * (V2) - R2020b : Square-root and version properties added
            obj.pVersion = 2;
        end
        
        %----------------------------------------------------------------------
        % Predict method
        %----------------------------------------------------------------------
        function [x_pred, P_pred] = predict(obj, varargin)
            % predict Predicts the state and state estimation error covariance
            %   [x_pred, P_pred] = predict(obj) returns x_pred, the
            %   prediction of the state, and P_pred, the prediction of the
            %   state estimation error covariance at the next time step.
            %   The internal state and covariance of the unscented Kalman
            %   filter are overwritten by the prediction results.
            %
            %   [x_pred, P_pred] = predict(obj, varargin) additionally,
            %   lets you specify any input arguments that will be passed to
            %   the StateTransitionFcn.
            
            % correct must be called with a single object
            coder.internal.errorIf(numel(obj) > 1, ...
                'shared_tracking:UnscentedKalmanFilter:NonScalarFilter', ...
                'unscented Kalman filter', 'predict');
            
            % Ensure:
            % * Dimensions of x, P, Q are known and corresponding protected
            % properties are defined,
            % * Necessary scalar expansions are performed
            ensureStateAndStateCovarianceIsDefined(obj);
            ensureProcessNoiseIsDefined(obj);
            
            if obj.pIsFirstCallPredict
                % Validate StateTransitionFcn
                % 1) Must be defined
                % 2) Number of inputs must match the expected value
                % 3) Must return data of pState's class, and dimensions of
                % State is as expected
                %
                % 1)
                if ~obj.pIsValidStateTransitionFcn
                    coder.internal.errorIf(isempty(obj.StateTransitionFcn),...
                        'shared_tracking:UnscentedKalmanFilter:undefinedStateTransitionFcn');
                end
                % 2)
                narginExpected = obj.pPredictor.getExpectedNargin(nargin);
                narginActual = nargin(obj.StateTransitionFcn);
                coder.internal.errorIf(narginActual ~= narginExpected && ...
                    narginActual >= 0, ... %negative if varies
                    'shared_tracking:UnscentedKalmanFilter:invalidNumInputsToPredict',...
                    'StateTransitionFcn');
                % 3)
                if ~obj.pIsValidStateTransitionFcn
                    coder.internal.errorIf(...
                        obj.pPredictor.validateStateTransitionFcn(obj.StateTransitionFcn,obj.pState,obj.pW,varargin{:}),...
                        'shared_tracking:UnscentedKalmanFilter:StateNonMatchingSizeOrClass',...
                        'StateTransitionFcn', 'State', numel(obj.pState));
                    obj.pIsValidStateTransitionFcn = true;
                end
                obj.pIsFirstCallPredict = false();
            end
            
            % Perform the UKF prediction
            [obj.pState, obj.pSqrtStateCovariance, obj.pCrossCov] = ...
                obj.pPredictor.predict(...
                obj.pSqrtProcessNoise, ...
                obj.pState, ...
                obj.pSqrtStateCovariance, ...
                obj.Alpha, ...
                obj.Beta, ...
                obj.Kappa, ...
                obj.StateTransitionFcn, ...
                varargin{:});
            obj.pHasPrediction = true;
            
            % obj.State outputs the estimated state in the orientation of
            % initial state provided by the user
            if nargout
                x_pred = obj.State;
                if nargout > 1
                    P_pred = obj.StateCovariance;
                end
            end
        end
        
        %----------------------------------------------------------------------
        % Correct method
        %----------------------------------------------------------------------
        function [x_corr, P_corr] = correct(obj, z, varargin)
            % correct Corrects the state and state estimation error covariance
            %   [x_corr, P_corr] = correct(obj, z) returns x_corr, the
            %   correction of the state, and P_corr, the correction of the
            %   state estimation error covariance based on the current
            %   measurement z, an N-element vector. The internal state and
            %   covariance of the unscented Kalman filter are overwritten
            %   by the corrected values.
            %
            %   [x_corr, P_corr] = correct(obj, z, varargin) additionally
            %   allows you to specify any additional arguments required by
            %   MeasurementFcn to produce a measurement.
            
            % correct must be called with a single object
            coder.internal.errorIf(numel(obj) > 1, ...
                'shared_tracking:UnscentedKalmanFilter:NonScalarFilter', ...
                'unscented Kalman filter', 'correct');
            
            % Validate z. Skip the size check if it's not known yet (first
            % call to correct)
            if coder.internal.is_defined(obj.pN)
                matlabshared.tracking.internal.validateInputSizeAndType...
                    ('z', 'UnscentedKalmanFilter', z, obj.pN);
            else
                matlabshared.tracking.internal.validateInputSizeAndType...
                    ('z', 'UnscentedKalmanFilter', z);
            end
            
            % Measurements z can be a row or column vector. 
            %
            % Validate z, x, P, R
            validateMeasurementAndRelatedProperties(obj, z, 'correct', varargin{:});
            
            % Perform the UKF correction
            [obj.pState, obj.pSqrtStateCovariance] = ...
                obj.pCorrector.correct(...
                z, ...
                getSqrtMeasurementNoise(obj), ...
                obj.pState, ...
                obj.pSqrtStateCovariance, ...
                obj.Alpha, ...
                obj.Beta, ...
                obj.Kappa, ...
                obj.MeasurementFcn, ...
                varargin{:});
            obj.pHasPrediction = false;
           
            % obj.State outputs the estimated state in the orientation of
            % initial state provided by the user
            if nargout
                x_corr = obj.State;
                if nargout > 1
                    P_corr = obj.StateCovariance;
                end
            end
        end
        
       %----------------------------------------------------------------------
       % Residual method
       %----------------------------------------------------------------------
       function [res, S] = residual(obj, z, varargin)
           % residual Computes the residual of measurement z and the
           % filter.
           %   [res, S] = residual(obj, z) computes a residual, res, and
           %   the residual matrix, S, where:
           %       res = z-h(obj.State), h is the measurement function
           %       S = Rp+R, where Rp is the state covariance matrix
           %       projected onto the measurement space using the unscented
           %       transformation.
           %
           %   [...] = residual(obj, z_matrix, varargin) allows
           %   passing additional parameters that will be used by the
           %   UKF.MeasurementFcn. 
           
           cond = (numel(obj) > 1);
           coder.internal.errorIf(cond, ...
               'shared_tracking:UnscentedKalmanFilter:NonScalarFilter', ...
               'unscented Kalman filter', 'residual');
           
            % Validate z. Skip the size check if it's not known yet (first
            % call to residual)
           if coder.internal.is_defined(obj.pN)
               matlabshared.tracking.internal.validateInputSizeAndType...
                   ('z', 'residual', z, obj.pN);
           else
               matlabshared.tracking.internal.validateInputSizeAndType...
                   ('z', 'residual', z);
           end
           
           % Measurements z can be a row or column vector.
           %
           % Validate z, x, P, R
           validateMeasurementAndRelatedProperties(obj, z,'residual', varargin{:});
           
           % Call residual method
           [res,S] = ...
                obj.pCorrector.residual(...
                z, ...
                getSqrtMeasurementNoise(obj), ...
                obj.pState, ...
                obj.pSqrtStateCovariance, ...
                obj.Alpha, ...
                obj.Beta, ...
                obj.Kappa, ...
                obj.MeasurementFcn, ...
                varargin{:});
           
        end
       
        function newUKF = clone(UKF)
            % clone Create a copy of the filter
            %
            % newUKF = clone(UKF)
            
            % Make sure that the method was called with a single object
            cond = (numel(UKF) > 1);
            coder.internal.errorIf(cond, ...
                'shared_tracking:UnscentedKalmanFilter:NonScalarFilter', ...
                'unscented Kalman filter', 'clone');
            
            coder.inline('never');
            
            % Use str2func to get the correct object type. When called from
            % a subclass, the resulting object will be of the same subclass
            obj = str2func(coder.const(class(UKF)));
            % Construct the basic filter. The properties assigned here are:
            % * pDataType: Guaranteed to be defined (after construction). It
            % must be set immediately as it impacts the types of default
            % floating point assignments in the constructor.
            % * HasAdditiveProcessNoise, HasAdditiveProcessNoise: These set
            % pPredictor, pCorrector which must be set before other
            % properties
            newUKF = obj(...
                'HasAdditiveProcessNoise', UKF.HasAdditiveProcessNoise,...
                'HasAdditiveMeasurementNoise', UKF.HasAdditiveMeasurementNoise,...
                'DataType', UKF.pDataType, 'HasMeasurementWrapping', UKF.HasMeasurementWrapping);
            % Copy all protected/private properties
            %
            % ppProperties holds the list of all private/protected that may
            % not be set during construction
            ppProperties = coder.const({...
                'pIsSetStateCovariance', 'pIsSetProcessNoise', 'pIsSetMeasurementNoise',...
                'pM','pN','pV','pW',...
                'pState', 'pIsStateColumnVector',...
                'StateTransitionFcn','MeasurementFcn',...
                'pSqrtStateCovariance','pSqrtStateCovarianceScalar',... % pXScalar must be assigned after pX, as set.pX can overwrite pXScalar
                'pSqrtProcessNoise','pSqrtProcessNoiseScalar',...
                'pSqrtMeasurementNoise','pSqrtMeasurementNoiseScalar',...
                'pHasPrediction',...
                'pIsValidStateTransitionFcn','pIsValidMeasurementFcn',...
                'Alpha','Beta','Kappa',...
                'pIsFirstCallPredict','pIsFirstCallCorrect','pCrossCov'});
            for kk = coder.unroll(1:numel(ppProperties))
                % Copy only if the prop was set in the source obj
                if coder.internal.is_defined(UKF.(ppProperties{kk}))
                    newUKF.(ppProperties{kk}) = UKF.(ppProperties{kk});
                end
            end
        end
    end
    
    methods
        %----------------------------------------------------------------------
        function set.State(obj, value)
            validateattributes(value, ...
                {obj.pDataType}, {'real', 'finite', 'nonsparse', 'vector'},...
                'UnscentedKalmanFilter', 'State');
            % Validate dimensions only when it is known
            if coder.internal.is_defined(obj.pM)
                coder.internal.assert(isscalar(value) || numel(value)==obj.pM, ...
                    'shared_tracking:UnscentedKalmanFilter:invalidStateDims', obj.pM);
            else
                % State dims M unknown. The first set operation defines it
                obj.pM = numel(value);
            end
            
            if isscalar(value)
                % Scalar expand
                obj.pState = matlabshared.tracking.internal.expandScalarValue...
                    (value, [obj.pM, 1]);
            else
                obj.pState = value(:);
                % Store the state orientation. Filter will output states in
                % the same orientation
                if iscolumn(value)
                    obj.pIsStateColumnVector = true();
                else
                    obj.pIsStateColumnVector = false();
                end
            end
        end
        
        %----------------------------------------------------------------------
        function value = get.State(obj)
            % Show a clear error message if pState is empty and we are
            % doing codegen.
            %
            % In MATLAB we can display []
            coder.internal.assert(isempty(coder.target) || coder.internal.is_defined(obj.pState),...
                'shared_tracking:UnscentedKalmanFilter:getUndefinedState');
            
            if obj.pIsStateColumnVector % User expects state to be a column vector
                value = obj.pState;
            else % User expects state to be a row vector
                value = obj.pState.';
            end
        end
        
        %----------------------------------------------------------------------
        function set.StateCovariance(obj, value)
            % Validating that the new state covariance has the correct
            % attributes and dimensions
            validateattributes(value, ...
                {obj.pDataType}, ...
                {'real', 'finite', 'nonsparse', '2d', 'nonempty', 'square'},...
                'UnscentedKalmanFilter', 'StateCovariance');
            % Check dims only if # of states is known
            if coder.internal.is_defined(obj.pM)
                matlabshared.tracking.internal.validateDataDims...
                    ('StateCovariance', value, [obj.pM, obj.pM]);
            end
            matlabshared.tracking.internal.isSymmetricPositiveSemiDefinite...
                ('StateCovariance', value);
            
            % Square root factorization
            value = matlabshared.tracking.internal.cholPSD(value);
            
            % Ensure that value is lower triangular
            if ~istril(value)
                [~,R] = qr(value.');
                value = R.';
            end
            
            if isscalar(value)
                % Store the scalar separately. get.StateCovariance or
                % pSqrtStateCovariance will scalar expand as necessary
                obj.pSqrtStateCovarianceScalar = value(1);
            else
                obj.pSqrtStateCovariance = value;
                obj.pM = size(value,1);
            end
        end
        
        %----------------------------------------------------------------------
        function value = get.StateCovariance(obj)
            % Get state covariance
            if isempty(coder.target)
                % MATLAB
                %
                % Return scalar if pIsSetStateCovariance was not set
                % before. This is either the default value (from
                % constProcessNoise), or a user assigned scalar value                
                if isempty(obj.pM)
                    value = obj.pStateCovarianceScalar;
                else
                    stateCovarianceScalarExpandIfNecessary(obj);
                    value = obj.pStateCovariance;
                end
            else
                % Codegen
                %
                % State covariance dims must be already defined at compile time
                coder.internal.assert(coder.internal.is_defined(obj.pM),...
                    'shared_tracking:UnscentedKalmanFilter:getUndefinedStateCovariance');
                stateCovarianceScalarExpandIfNecessary(obj);
                value = obj.pStateCovariance;
            end
        end
        
        %----------------------------------------------------------------------
        function set.ProcessNoise(obj, value)
            validateattributes(value, ...
                {obj.pDataType}, ...
                {'real', 'finite', 'nonsparse', '2d', 'nonempty','square'},...
                'UnscentedKalmanFilter', 'ProcessNoise');
            if coder.internal.is_defined(obj.pW)
                matlabshared.tracking.internal.validateDataDims('ProcessNoise', value, [obj.pW obj.pW]);
            end
            matlabshared.tracking.internal.isSymmetricPositiveSemiDefinite('ProcessNoise', value);
            
            % Set the process noise dimensions if
            % * There is non-additive process noise, and dims were unknown
            % * The provided Q is not scalar
            if (~obj.HasAdditiveProcessNoise && ~coder.internal.is_defined(obj.pW)) || ~isscalar(value)
                obj.pW = size(value,1);
            end            
            
            % Square root factorization
            value = matlabshared.tracking.internal.cholPSD(value);
            
            if isscalar(value)
                % Store the scalar separately. get.ProcessNoise or
                % pSqrtProcessNoise will scalar expand as necessary
                obj.pSqrtProcessNoiseScalar = value(1);
            else
                obj.pSqrtProcessNoise = value;
            end
        end
        
        %----------------------------------------------------------------------
        function value = get.ProcessNoise(obj)
            % Get process noise covariance
            
            if isempty(coder.target)
                % MATLAB
                %
                % Return scalar if process noise dims are not known. This
                % is either the default value (from constProcessNoise), or
                % a user assigned scalar value
                if isempty(obj.pW)
                    value = obj.pProcessNoiseScalar;
                else                    
                    processNoiseScalarExpandIfNecessary(obj);
                    value = obj.pProcessNoise;
                end
            else
                % Codegen
                %
                % Process noise dims must be already defined at compile time
                coder.internal.assert(coder.internal.is_defined(obj.pW),...
                    'shared_tracking:UnscentedKalmanFilter:getUndefinedProcessNoise');
                processNoiseScalarExpandIfNecessary(obj);
                value = obj.pProcessNoise;
            end
        end
        
        %----------------------------------------------------------------------
        function set.MeasurementNoise(obj, value)
            validateattributes(value, ...
                {obj.pDataType}, ...
                {'real', 'finite', 'nonsparse', '2d', 'nonempty', 'square'},...
                'UnscentedKalmanFilter', 'MeasurementNoise');
            
            matlabshared.tracking.internal.validateDataAttributes('MeasurementNoise', value);
            %Every time the measurement function changes, this size may change so no size checking
            if obj.pIsValidMeasurementFcn && coder.internal.is_defined(obj.pV)
                % Skipping this check when meas. fcn is not valid allows
                % users to change the dimensions of R when they change the
                % meas. fcn (not supported in codegen)
                matlabshared.tracking.internal.validateDataDims('MeasurementNoise', value, [obj.pV obj.pV]);
            end
            matlabshared.tracking.internal.isSymmetricPositiveSemiDefinite('MeasurementNoise', value);
            
            % Set the measurement dimensions if:
            % * There is non-additive measurement noise, and this is the
            % first assignment of R
            % * The provided R is not scalar
            if (~obj.HasAdditiveMeasurementNoise && ~coder.internal.is_defined(obj.pV)) || ~isscalar(value)
                obj.pV = size(value,1);
            end
            
            % Square root factorization
            value = matlabshared.tracking.internal.cholPSD(value);
            
            if isscalar(value)
                % Store the scalar separately. get.MeasurementNoise or
                % pSqrtMeasurementNoise will scalar expand as necessary
                obj.pSqrtMeasurementNoiseScalar = value(1);
            else
                obj.pSqrtMeasurementNoiseScalar = cast(-1,obj.pDataType);
                ensureMeasurementNoiseIsDefined(obj);
                setSqrtMeasurementNoise(obj, value);
            end
        end
        
        %----------------------------------------------------------------------
        function value = get.MeasurementNoise(obj)
            % Get measurement noise covariance
            
            % if pSqrt is defined, but pV is undefined, set it now.
            if coder.internal.is_defined(obj.pSqrtMeasurementNoise) && ~coder.internal.is_defined(obj.pV)
                obj.pV = size(obj.pSqrtMeasurementNoise,1);
            end

            if isempty(coder.target)
                % MATLAB
                %
                % Return scalar if meas noise dims are not known. This is
                % either the default value (from constMeasurementNoise), or
                % a user assigned scalar value
                if isempty(obj.pV)
                    value = obj.pMeasurementNoiseScalar;
                else
                    ensureMeasurementNoiseIsDefined(obj);
                    value = obj.pMeasurementNoise;
                end
            else
                % Codegen
                %
                % Meas noise dims must be already defined at compile time
                coder.internal.assert(coder.internal.is_defined(obj.pV),...
                    'shared_tracking:UnscentedKalmanFilter:getUndefinedMeasurementNoise');
                ensureMeasurementNoiseIsDefined(obj);
                value = obj.pMeasurementNoise;
            end
        end
        
        %----------------------------------------------------------------------
        function set.StateTransitionFcn(obj, value)
            validateattributes(value, {'function_handle'},...
                {'nonempty'}, 'UnscentedKalmanFilter', 'StateTransitionFcn');
            obj.pIsValidStateTransitionFcn = false;
            obj.StateTransitionFcn = value;
        end
        
        %----------------------------------------------------------------------
        function set.MeasurementFcn(obj, value)
            validateattributes(value, {'function_handle'}, ...
                {'nonempty'}, 'UnscentedKalmanFilter', 'measurementFcn');
            obj.pIsValidMeasurementFcn = false;
            obj.MeasurementFcn = value;
        end
        
        %----------------------------------------------------------------------
        function set.Alpha(obj, value)
            validateattributes(value, {obj.pDataType},...
                {'real','scalar','positive','<=',1},...
                'UnscentedKalmanFilter', 'Alpha');
            obj.Alpha = value;
        end
        
        %----------------------------------------------------------------------
        function set.Beta(obj, value)
            validateattributes(value,  {obj.pDataType},...
                {'real','scalar','finite','nonnegative'}, 'UnscentedKalmanFilter', 'Beta');
            obj.Beta = value;
        end
        
        %----------------------------------------------------------------------
        function set.Kappa(obj, value)
            validateattributes(value, {obj.pDataType},...
                {'real','scalar','nonnegative','<=',3},...
                'UnscentedKalmanFilter', 'Kappa');
            obj.Kappa = value;
        end
        
        %----------------------------------------------------------------------
        function set.HasAdditiveProcessNoise(~, ~)
            
            % Note: HasAdditiveProcessNoise depends on pPredictor, which is
            % set via setPredictor() during construction
            ex = MException(message('shared_tracking:UnscentedKalmanFilter:PropertyOnlySettableDuringConstruction',...
                'HasAdditiveProcessNoise'));
            throwAsCaller(ex);
        end
        
        %----------------------------------------------------------------------
        function value = get.HasAdditiveProcessNoise(obj)
            value = obj.pPredictor.HasAdditiveNoise;
        end
        
        %----------------------------------------------------------------------
        function set.HasAdditiveMeasurementNoise(~, ~)
            
            % Note: HasAdditiveMeasurementNoise depends on pCorrector,
            % which is set via setCorrector() during construction
            ex = MException(message('shared_tracking:UnscentedKalmanFilter:PropertyOnlySettableDuringConstruction',...
                'HasAdditiveMeasurementNoise'));
            throwAsCaller(ex);
        end
        
        %----------------------------------------------------------------------
        function value = get.HasAdditiveMeasurementNoise(obj)
            value = obj.pCorrector.HasAdditiveNoise;
        end
        
        %----------------------------------------------------------------------
        function set.pM(obj,value)
            % Set the number of states in the state transition model
            obj.pM = value;
            % If the process model has additive noise, the number of
            % process noise terms pW is equal to pM
            if obj.HasAdditiveProcessNoise
                obj.pW = value;
            end
        end
        
        function set.pN(obj,value)
            % Set the number of measurements in the measurement model
            obj.pN = value;
            % If the measurement model has additive noise, the number of
            % measurement noise terms pV is equal to pN
            if obj.HasAdditiveMeasurementNoise
                obj.pV = value;
            end
        end
        
        %----------------------------------------------------------------------
         function set.pSqrtStateCovariance(obj, value)
            assert(~isempty(value));
            obj.pSqrtStateCovariance = value;
            obj.pIsSetStateCovariance = true();
                       
            % Discard previous scalar assignments
            obj.pSqrtStateCovarianceScalar = cast(-1,obj.pDataType);            
        end
        
        %----------------------------------------------------------------------
        % Get and Set methods for pStateCovarianceScalar
        function value = get.pStateCovarianceScalar(obj)
            value = obj.pSqrtStateCovarianceScalar*obj.pSqrtStateCovarianceScalar.';
        end
        
        function set.pStateCovarianceScalar(obj,value)
           obj.pSqrtStateCovarianceScalar = matlabshared.tracking.internal.cholPSD(value); 
        end
        
        %----------------------------------------------------------------------
        % Get and Set methods for pStateCovariance
        function value = get.pStateCovariance(obj)
            value = obj.pSqrtStateCovariance*obj.pSqrtStateCovariance.';
        end 
        
        function set.pStateCovariance(obj,value)
           obj.pSqrtStateCovariance = matlabshared.tracking.internal.cholPSD(value); 
        end
               
        %----------------------------------------------------------------------               
        function set.pSqrtProcessNoise(obj, value)
            assert(~isempty(value));
            obj.pSqrtProcessNoise = value;
            obj.pIsSetProcessNoise = true();
            
            % Discard previous scalar assignments
            obj.pSqrtProcessNoiseScalar = cast(-1,obj.pDataType);
         end
        
        %----------------------------------------------------------------------  
        % Get and Set methods for pProcessNoiseScalar
        function value = get.pProcessNoiseScalar(obj)
            value =  obj.pSqrtProcessNoiseScalar*obj.pSqrtProcessNoiseScalar.';
        end
         
        function set.pProcessNoiseScalar(obj,value)
            obj.pSqrtProcessNoiseScalar = matlabshared.tracking.internal.cholPSD(value);
        end
        
        %----------------------------------------------------------------------
        % Get and Set methods for pProcessNoise
        function value = get.pProcessNoise(obj)
            value =  obj.pSqrtProcessNoise*obj.pSqrtProcessNoise.';
        end
        
        function set.pProcessNoise(obj,value)
            obj.pSqrtProcessNoise =  matlabshared.tracking.internal.cholPSD(value);
        end

        %----------------------------------------------------------------------  
        % Get and Set methods for pMeasurementNoiseScalar
        function value = get.pMeasurementNoiseScalar(obj)
            if ~coder.internal.is_defined(obj.pSqrtMeasurementNoiseScalar)
                obj.pSqrtMeasurementNoiseScalar = cast(obj.constMeasurementNoise,obj.pDataType);
            end
            value =  obj.pSqrtMeasurementNoiseScalar*obj.pSqrtMeasurementNoiseScalar.';
        end
         
        function set.pMeasurementNoiseScalar(obj,value)
            obj.pSqrtMeasurementNoiseScalar = matlabshared.tracking.internal.cholPSD(value);
        end
        
        %----------------------------------------------------------------------
        % Get and Set methods for pMeasurementNoise
        function value = get.pMeasurementNoise(obj)
            valueSqrt = getSqrtMeasurementNoise(obj);
            value =  valueSqrt*valueSqrt.';
        end
        
        function set.pMeasurementNoise(obj,value)
            obj.pSqrtMeasurementNoiseScalar = cast(-1,obj.pDataType);
            ensureMeasurementNoiseIsDefined(obj);
            setSqrtMeasurementNoise(obj,matlabshared.tracking.internal.cholPSD(value));
        end

        function value = get.HasMeasurementWrapping(obj)
            value = obj.pCorrector.HasMeasurementWrapping;
        end
    end
    
    methods (Access = protected)
        function val = getSqrtMeasurementNoise(obj)
            if coder.target('MATLAB')
                val = obj.pSqrtMeasurementNoise;
            else
                if coder.internal.isConst(size(obj.pSqrtMeasurementNoise))
                    n = obj.pV;
                    assert(n <= size(obj.pSqrtMeasurementNoise,1));
                    val = obj.pSqrtMeasurementNoise(1:n,1:n);
                else
                    val = obj.pSqrtMeasurementNoise;
                end
            end
        end

        function setSqrtMeasurementNoise(obj, val)
            if coder.target('MATLAB')
                obj.pSqrtMeasurementNoise = val;
            else
                if coder.internal.is_defined(obj.pSqrtMeasurementNoise) && coder.internal.isConst(size(obj.pSqrtMeasurementNoise))
                    n = obj.pV;
                    assert(n <= size(obj.pSqrtMeasurementNoise,1)); % enforced in setMeasurementSizes
                    assert(size(val,1) <= n);
                    obj.pSqrtMeasurementNoise(1:n,1:n) = val;
                else
                    obj.pSqrtMeasurementNoise = val;
                end
            end
        end
    end
    
    methods(Hidden)
        function setMeasurementSizes(obj, measurementSize, measurementNoiseSize)
            % Sets the sizes of the measurement (pN) and measurement noise
            % (pV). Both have to be a real, positive, integer, scalar.
            validateattributes(measurementSize, {'numeric'}, {'real', ...
                'positive', 'integer', 'scalar'}, 'UnscentedKalmanFilter');
            validateattributes(measurementNoiseSize, {'numeric'}, {'real', ...
                'positive', 'integer', 'scalar'}, 'UnscentedKalmanFilter');
            coder.internal.assert(~obj.HasAdditiveMeasurementNoise || measurementSize==measurementNoiseSize,...
                'shared_tracking:KalmanFilter:IncompatibleMeasSizeAndNoiseSize');
            obj.pN = measurementSize;
            obj.pV = measurementNoiseSize;
        end
        
        function setStateSizes(obj, stateSize, processNoiseSize)
            % Sets the sizes of the state (pM) and process noise
            % (pW). Both have to be a real, positive, integer, scalar.
            validateattributes(stateSize, {'numeric'}, {'real', ...
                'positive', 'integer', 'scalar'}, 'UnscentedKalmanFilter');
            validateattributes(processNoiseSize, {'numeric'}, {'real', ...
                'positive', 'integer', 'scalar'}, 'UnscentedKalmanFilter');
            obj.pM = stateSize;
            obj.pW = processNoiseSize;
        end
    end
    
    methods(Access=private)
        %----------------------------------------------------------------------
        % Parse inputs for simulation
        %----------------------------------------------------------------------
        function [stateTransitionFcn, measurementFcn, state, stateCovariance, ...
                processNoise, measurementNoise, alpha, beta, kappa, ...
                hasAdditiveProcessNoise, hasAdditiveMeasurementNoise, dataType, ...
                hasWrapping] ...
                = parseInputsSimulation(obj, varargin)
            
            % Instantiate an input parser
            parser = inputParser;
            parser.FunctionName = mfilename;
            
            % Specify the optional parameters.
            %
            % Specify defaults only if they are numeric properties whose
            % dimensions are known. All other properties can only be
            % assigned once for codegen support. [] is interpreted as 'not
            % specified, skip assignment' in the constructor.
            parser.addOptional('StateTransitionFcn', []);
            parser.addOptional('MeasurementFcn',     []);
            parser.addOptional('State',              []);
            parser.addParameter('StateCovariance',   []);
            parser.addParameter('ProcessNoise',      []);
            parser.addParameter('MeasurementNoise',  []);
            parser.addParameter('Alpha',             obj.constAlpha);
            parser.addParameter('Beta',              obj.constBeta);
            parser.addParameter('Kappa',             obj.constKappa);
            parser.addParameter('HasAdditiveProcessNoise', ...
                obj.constHasAdditiveProcessNoise);
            parser.addParameter('HasAdditiveMeasurementNoise', ...
                obj.constHasAdditiveMeasurementNoise);
            parser.addParameter('DataType', obj.constDataType);
            parser.addParameter('HasMeasurementWrapping', obj.constHasMeasurementWrapping);
            
            % Parse parameters
            parse(parser, varargin{:});
            r = parser.Results;
            
            stateTransitionFcn      =  r.StateTransitionFcn;
            measurementFcn          =  r.MeasurementFcn;
            state                   =  r.State;
            stateCovariance         =  r.StateCovariance;
            processNoise            =  r.ProcessNoise;
            measurementNoise        =  r.MeasurementNoise;
            alpha                   =  r.Alpha;
            beta                    =  r.Beta;
            kappa                   =  r.Kappa;
            hasAdditiveProcessNoise =  r.HasAdditiveProcessNoise;
            hasAdditiveMeasurementNoise = r.HasAdditiveMeasurementNoise;
            dataType                = r.DataType;
            hasWrapping             = r.HasMeasurementWrapping;
        end
        
        %----------------------------------------------------------------------
        % Parse inputs for code generation
        %----------------------------------------------------------------------
        function [stateTransitionFcn, measurementFcn, state, stateCovariance, ...
                processNoise, measurementNoise, alpha, beta, kappa, ...
                hasAdditiveProcessNoise, hasAdditiveMeasurementNoise, dataType, ...
                hasWrapping] ...
                = parseInputsCodegen(obj, varargin)
            
            coder.internal.prefer_const(varargin); % Required: g1381035
            
            % Find the position of the first name-property pair, firstPNIndex
            firstNVIndex = matlabshared.tracking.internal.findFirstNVPair(varargin{:});
            
            parms = struct( ...
                'StateTransitionFcn',           uint32(0), ...
                'MeasurementFcn',               uint32(0), ...
                'State',                        uint32(0), ...
                'StateCovariance',              uint32(0), ...
                'ProcessNoise',                 uint32(0), ...
                'MeasurementNoise',             uint32(0), ...
                'Alpha',                        uint32(0), ...
                'Beta',                         uint32(0), ...
                'Kappa',                        uint32(0), ...
                'HasAdditiveProcessNoise',      uint32(0), ...
                'HasAdditiveMeasurementNoise',  uint32(0),...
                'DataType',                     uint32(0),...
                'HasMeasurementWrapping',       uint32(0));
            
            popt = struct( ...
                'CaseSensitivity', false, ...
                'StructExpand',    true, ...
                'PartialMatching', false);
            
            % If user specifies (StateTransitionFcn, MeasurementFcn, State)
            % both via initial 3 input arguments, and the NV-pairs, the
            % NV-pair takes over. This is the behavior in inputParser used
            % in parseInputsSimulation, MATLAB NVPair parser.
            %
            % Do the same in codegen via setting default values of
            % mentioned properties first from the optional arguments.
            % NV-pair parser overrides this, if user specifies them.
            %
            % For the remaining properties: Specify defaults only if they
            % are numeric properties whose dimensions are known. All other
            % properties can only be assigned once for codegen support. []
            % is interpreted as 'not specified, skip assignment' in the
            % constructor.
            if firstNVIndex == 1 % Can't assign function_handles on codegen
                defaultStateTransitionFcn = [];
                defaultMeasurementFcn     = [];
                defaultState              = []; %We don't know the size of the state
            elseif firstNVIndex == 3 % State may be provided as Name-value pair
                defaultStateTransitionFcn = varargin{1};
                defaultMeasurementFcn     = varargin{2};
                defaultState              = []; %We don't know the size of the state
            else % The other option is that all three required inputs are provided.
                defaultStateTransitionFcn = varargin{1};
                defaultMeasurementFcn     = varargin{2};
                defaultState              = varargin{3};
            end
            
            optarg           = eml_parse_parameter_inputs(parms, popt, ...
                varargin{firstNVIndex:end});
            stateTransitionFcn = eml_get_parameter_value(optarg.StateTransitionFcn,...
                defaultStateTransitionFcn, varargin{firstNVIndex:end});
            measurementFcn = eml_get_parameter_value(optarg.MeasurementFcn,...
                defaultMeasurementFcn, varargin{firstNVIndex:end});
            state = eml_get_parameter_value(optarg.State,...
                defaultState, varargin{firstNVIndex:end});
            stateCovariance  = eml_get_parameter_value(optarg.StateCovariance,...
                [], varargin{firstNVIndex:end});
            processNoise     = eml_get_parameter_value(optarg.ProcessNoise,...
                [], varargin{firstNVIndex:end});
            measurementNoise = eml_get_parameter_value(optarg.MeasurementNoise,...
                [], varargin{firstNVIndex:end});
            alpha            = eml_get_parameter_value(optarg.Alpha,...
                obj.constAlpha, varargin{firstNVIndex:end});
            beta             = eml_get_parameter_value(optarg.Beta,...
                obj.constBeta, varargin{firstNVIndex:end});
            kappa            = eml_get_parameter_value(optarg.Kappa,...
                obj.constKappa, varargin{firstNVIndex:end});
            hasAdditiveProcessNoise = ...
                eml_get_parameter_value(optarg.HasAdditiveProcessNoise,...
                obj.constHasAdditiveProcessNoise, varargin{firstNVIndex:end});
            hasAdditiveMeasurementNoise = ...
                eml_get_parameter_value(optarg.HasAdditiveMeasurementNoise,...
                obj.constHasAdditiveMeasurementNoise, varargin{firstNVIndex:end});
            dataType = ...
                eml_get_parameter_value(optarg.DataType,...
                obj.constDataType, varargin{firstNVIndex:end});
            hasWrapping = ...
                eml_get_parameter_value(optarg.HasMeasurementWrapping,...
                obj.constHasMeasurementWrapping, varargin{firstNVIndex:end});
        end
        
        function setCorrector(obj, hasAdditiveMeasurementNoise, hasWrapping)
            validateattributes(hasAdditiveMeasurementNoise, ...
                {'numeric', 'logical'},...
                {'scalar','binary'},...
                'UnscentedKalmanFilter', 'HasAdditiveMeasurementNoise');
            validateattributes(hasWrapping, ...
                {'numeric', 'logical'},...
                {'scalar', 'binary'},...
                'UnscentedKalmanFilter', 'HasMeasurementWrapping');
            if hasAdditiveMeasurementNoise
                obj.pCorrector = matlabshared.tracking.internal.UKFCorrectorAdditive();
            else
                obj.pCorrector = matlabshared.tracking.internal.UKFCorrectorNonAdditive();
            end
            obj.pCorrector.HasMeasurementWrapping = hasWrapping;
        end
        
        function setPredictor(obj, hasAdditiveProcessNoise)
            validateattributes(hasAdditiveProcessNoise, {'numeric', 'logical'},...
                {'scalar','binary'},...
                'UnscentedKalmanFilter', 'HasAdditiveProcessNoise');
            if hasAdditiveProcessNoise
                obj.pPredictor = matlabshared.tracking.internal.UKFPredictorAdditive();
            else
                obj.pPredictor = matlabshared.tracking.internal.UKFPredictorNonAdditive();
            end
        end
    end
    
    methods (Access = protected)
         function stateCovarianceScalarExpandIfNecessary(obj)
            % Scalar expand P if necessary: The default, or a user provided
            % scalar, is stored in obj.pSqrtStateCovarianceScalar
            if ~obj.pIsSetStateCovariance || obj.pSqrtStateCovarianceScalar ~= -1
                obj.pSqrtStateCovariance = matlabshared.tracking.internal.expandScalarValue(...
                    obj.pSqrtStateCovarianceScalar, ...
                    [obj.pM, obj.pM]);
            else
                % Ascertain MLCoder that pSqrtStateCovariance is defined
                coder.assumeDefined(obj.pSqrtStateCovariance);
            end
        end
        
        function processNoiseScalarExpandIfNecessary(obj)
            % Scalar expand, if necessary: The default, or a user provided
            % scalar, is stored in obj.pSqrtProcessNoiseScalar
            if (~obj.pIsSetProcessNoise || obj.pSqrtProcessNoiseScalar ~= -1)
                obj.pSqrtProcessNoise = matlabshared.tracking.internal.expandScalarValue(...
                    obj.pSqrtProcessNoiseScalar, ...
                    [obj.pW, obj.pW]);
            else
                % Ascertain MLCoder that pSqrtProcessNoise is defined
                coder.assumeDefined(obj.pSqrtProcessNoise);
            end
        end
        
        function measurementNoiseScalarExpandIfNecessary(obj)
            % Ascertain MLCoder: pSqrtMeasurementNoise is defined in all code paths
            coder.assumeDefined(obj.pSqrtMeasurementNoise);

            % Scalar expand, if necessary: The default, or a user provided
            % scalar, is stored in obj.pSqrtMeasurementNoiseScalar
            if obj.pSqrtMeasurementNoiseScalar > 0
                n = obj.pV;

                % if constant size pSqrtMeasurementNoise was provided, use it
                % as the bound for scalar expansion.
                if ~coder.target('MATLAB') && coder.internal.isConst(size(obj.pSqrtMeasurementNoise))
                    assert(n <= size(obj.pSqrtMeasurementNoise,1));
                end

                setSqrtMeasurementNoise(obj, matlabshared.tracking.internal.expandScalarValue...
                    (obj.pSqrtMeasurementNoiseScalar, [n n]));
                obj.pSqrtMeasurementNoiseScalar = cast(-1,obj.pDataType);
            end
        end
        
        %--------------------------------------------------------------------
        % saveobj to make sure that the filter is saved correctly.
        %--------------------------------------------------------------------
        function sobj = saveobj(UKF)
            sobj = struct(...
                'HasAdditiveProcessNoise',     UKF.HasAdditiveProcessNoise, ...
                'StateTransitionFcn',          UKF.StateTransitionFcn, ...
                'HasAdditiveMeasurementNoise', UKF.HasAdditiveMeasurementNoise, ...
                'MeasurementFcn',              UKF.MeasurementFcn, ...
                'State',                       UKF.State, ...
                'StateCovariance',             UKF.StateCovariance, ...
                'ProcessNoise',                UKF.ProcessNoise, ...
                'MeasurementNoise',            UKF.MeasurementNoise, ...
                'Alpha',                       UKF.Alpha, ...
                'Beta',                        UKF.Beta, ...
                'Kappa',                       UKF.Kappa, ...
                'pM',                          UKF.pM, ...
                'pN',                          UKF.pN, ...
                'pW',                          UKF.pW, ...
                'pV',                          UKF.pV, ...
                'pState',                      UKF.pState, ...
                'pSqrtStateCovariance',        UKF.pSqrtStateCovariance, ...
                'pSqrtStateCovarianceScalar',  UKF.pSqrtStateCovarianceScalar, ...
                'pSqrtProcessNoise',           UKF.pSqrtProcessNoise, ...
                'pSqrtProcessNoiseScalar',     UKF.pSqrtProcessNoiseScalar, ...
                'pSqrtMeasurementNoise',       UKF.pSqrtMeasurementNoise, ...
                'pSqrtMeasurementNoiseScalar', UKF.pSqrtMeasurementNoiseScalar, ...
                'pHasPrediction',              UKF.pHasPrediction, ...
                'pIsValidStateTransitionFcn',  UKF.pIsValidStateTransitionFcn, ...
                'pIsValidMeasurementFcn',      UKF.pIsValidMeasurementFcn, ...
                'pIsStateColumnVector',        UKF.pIsStateColumnVector,...
                'pDataType',                   UKF.pDataType,...
                'pVersion',                    UKF.pVersion,...
                'pIsFirstCallPredict',         UKF.pIsFirstCallPredict,...
                'pIsFirstCallCorrect',         UKF.pIsFirstCallCorrect,...
                'pCrossCov',                   UKF.pCrossCov,...
                'HasMeasurementWrapping',      UKF.HasMeasurementWrapping);
            % No need to save:
            % * pPredictor, pCorrector: These are (Static) classes with
            % constant properties. All required information is stored
            % in HasAdditiveProcessNoise and HasAdditiveMeasurementNoise.
            % Setting these during loadobj suffices.
            % * pIsSetStateCovariance, pIsSetMeasurementNoise,
            % pIsSetProcessNoise: New in 18b. Practically these are
            % dependent properties. Their default value is false(), and
            % they are automatically set to true() whenever the
            % corresponding properties are assigned (i.e. when they were
            % not empty) during load.
        end
        
        function loadobjHelper(UKF,sobj)
            % Helper for loadobj to maximize the shared code between
            % subclasses
            
            % Subclasses must:
            % * Construct object of the correct type, with DataType,
            % HasAdditiveProcessNoise, HasAdditiveMeasurementNoise
            % specified as NV pairs
            % * Call this method
            
            % Tunable, always-known-dimension public properties
            UKF.Alpha                      = sobj.Alpha;
            UKF.Beta                       = sobj.Beta;
            UKF.Kappa                      = sobj.Kappa;
            
            % Nontunable public properties
            if ~isempty(sobj.StateTransitionFcn)
                UKF.StateTransitionFcn = sobj.StateTransitionFcn;
            end
            if ~isempty(sobj.MeasurementFcn)
                UKF.MeasurementFcn = sobj.MeasurementFcn;
            end
            
            % Tunable protected/private properties
            UKF.pHasPrediction             = sobj.pHasPrediction;
            UKF.pIsValidStateTransitionFcn = sobj.pIsValidStateTransitionFcn;
            UKF.pIsValidMeasurementFcn     = sobj.pIsValidMeasurementFcn;
            UKF.pIsFirstCallPredict        = sobj.pIsFirstCallPredict;
            UKF.pIsFirstCallCorrect        = sobj.pIsFirstCallCorrect;
            
            % Nontunable or fixed-dimension-but-might-be-unset
            % protected/private properties
            if ~isempty(sobj.pM)
                UKF.pM = sobj.pM;
            end
            if ~isempty(sobj.pN)
                UKF.pN = sobj.pN;
            end
            if ~isempty(sobj.pW)
                UKF.pW = sobj.pW;
            end
            if ~isempty(sobj.pV)
                UKF.pV = sobj.pV;
            end
            if ~isempty(sobj.pIsStateColumnVector)
                UKF.pIsStateColumnVector = sobj.pIsStateColumnVector;
            end
            if ~isempty(sobj.pState)
                UKF.pState = sobj.pState;
            end
            
            % Determine if object originated in the Square-root version
            if isfield(sobj,'pVersion') && (sobj.pVersion == 2)
                loadSqrtObj(UKF,sobj);
            else
                loadNonSqrtObj(UKF,sobj);
            end
            
            % Load the pCrossCov property if exists
            if isfield(sobj,'pCrossCov') && ~isempty(sobj.pCrossCov)
                UKF.pCrossCov = sobj.pCrossCov;
            end
            
            % Omitted protected properties:
            % * pDataType: Set during object construction via NV pairs
            % * pPredictor: Set during object construction via NV pairs,
            % through HasAdditiveProcessNoise
            % * pCorrector: Set during object construction via NV pairs,
            % through HasAdditiveMeasurementNoise
            % * pIsSetStateCovariance, pIsSetMeasurementNoise,
            % pIsSetProcessNoise: New in 18b. Practically these are
            % dependent properties. Their default value is false(), and
            % they are automatically set to true() whenever the
            % corresponding properties are assigned (i.e. when they were
            % not empty) during load.
        end  
        
        function loadSqrtObj(UKF,sobj)
            % For objects originating in the Square-root version

            % Non-scalar properties
            if ~isempty(sobj.pSqrtStateCovariance)                 
                % isempty check is a must-have for pIsSetStateCovariance
                % being loaded correctly                
                UKF.pSqrtStateCovariance = sobj.pSqrtStateCovariance;
            end

            if ~isempty(sobj.pSqrtProcessNoise)                 
                % isempty check is a must-have for pIsSetStateCovariance
                % being loaded correctly                
                UKF.pSqrtProcessNoise = sobj.pSqrtProcessNoise;
            end

            if ~isempty(sobj.pSqrtMeasurementNoise)                 
                % isempty check is a must-have for pIsSetStateCovariance
                % being loaded correctly                
                UKF.pSqrtMeasurementNoise = sobj.pSqrtMeasurementNoise;
            end

            % The following (tunable protected) need to be loaded last.
            % Each pXScalar property has a corresponding pX property that
            % overwrites it in set.pX. Assigning pXScalar last ensures they
            % were not overwritten

            % Scalar properties
            UKF.pSqrtStateCovarianceScalar = sobj.pSqrtStateCovarianceScalar;          
            UKF.pSqrtProcessNoiseScalar = sobj.pSqrtProcessNoiseScalar;          
            UKF.pSqrtMeasurementNoiseScalar = sobj.pSqrtMeasurementNoiseScalar;            
        end
        
        function loadNonSqrtObj(UKF,sobj)
            % For objects originating in the non-square-root version
            
            % Non-scalar properties
            if ~isempty(sobj.pStateCovariance)
                % isempty check is a must-have for pIsSetStateCovariance
                % being loaded correctly
                UKF.pSqrtStateCovariance = matlabshared.tracking.internal.cholPSD(sobj.pStateCovariance);
            end
            
            if ~isempty(sobj.pProcessNoise)
                % isempty check is a must-have for pIsSetStateCovariance
                % being loaded correctly
                UKF.pSqrtProcessNoise = matlabshared.tracking.internal.cholPSD(sobj.pProcessNoise);
            end
            
            if ~isempty(sobj.pMeasurementNoise)
                % isempty check is a must-have for pIsSetStateCovariance
                % being loaded correctly
                UKF.pSqrtMeasurementNoise = matlabshared.tracking.internal.cholPSD(sobj.pMeasurementNoise);
            end
            
            % The following (tunable protected) need to be loaded last.
            % Each pXScalar property has a corresponding pX property that
            % overwrites it in set.pX. Assigning pXScalar last ensures they
            % were not overwritten
            
            % Scalar properties           
            if (sobj.pStateCovarianceScalar >= 0)
                UKF.pSqrtStateCovarianceScalar = matlabshared.tracking.internal.cholPSD(sobj.pStateCovarianceScalar);
            else
                UKF.pSqrtStateCovarianceScalar = sobj.pStateCovarianceScalar;
            end           
            
            if (sobj.pProcessNoiseScalar >= 0)
                UKF.pSqrtProcessNoiseScalar = matlabshared.tracking.internal.cholPSD(sobj.pProcessNoiseScalar);
            else
                UKF.pSqrtProcessNoiseScalar = sobj.pProcessNoiseScalar;
            end            
            
            if (sobj.pMeasurementNoiseScalar >= 0)
                UKF.pSqrtMeasurementNoiseScalar = matlabshared.tracking.internal.cholPSD(sobj.pMeasurementNoiseScalar);
            else
                UKF.pSqrtMeasurementNoiseScalar = sobj.pMeasurementNoiseScalar;
            end            
        end
        
        function ensureStateAndStateCovarianceIsDefined(obj)
            % Ensure that state dimension pM, state x, state covariance P
            % are defined before we perform a predict or correct operation.
            %
            % Perform scalar expansion if M is defined, but P do not have
            % the correct dimensions.
            
            % State must be defined by the user
            coder.internal.assert(coder.internal.is_defined(obj.pState) && ...
                coder.internal.is_defined(obj.pM),...
                'shared_tracking:UnscentedKalmanFilter:UnknownNumberOfStates');
            
            % Scalar expand P if necessary
            stateCovarianceScalarExpandIfNecessary(obj);
        end
        
        function ensureProcessNoiseIsDefined(obj)
            % Ensure that process noise covariance dimension pW,
            % measurement noise covariance Q are defined before we perform
            % a predict operation.
            %
            % Perform scalar expansion if pW is defined, but Q is not
            % assigned
            
            coder.internal.assert(coder.internal.is_defined(obj.pW),...
                'shared_tracking:UnscentedKalmanFilter:UnknownNumberOfProcessNoiseInputs');
            
            % Scalar expand Q if necessary
            processNoiseScalarExpandIfNecessary(obj);
        end
        
        function validateMeasurementFcn(obj,z,fname,varargin)
            % Validate MeasurementFcn
            % 1) Must be defined
            % 2) Number of inputs must match the expected value
            % 3) Must return data of pState's class, and dimensions of
            % measurements is as expected
            %
            % Inputs:
            %    z: Measurements as a vector
            %    varargin: Extra input arguments to MeasurementFcn
            
            %
            % 1)
            if ~obj.pIsValidMeasurementFcn
                coder.internal.errorIf(isempty(obj.MeasurementFcn),...
                    'shared_tracking:UnscentedKalmanFilter:undefinedMeasurementFcn');
            end
            % 2)
            narginExpected = numel(varargin) + obj.pCorrector.getNumberOfMandatoryInputs();
            narginActual = nargin(obj.MeasurementFcn);
            coder.internal.errorIf(narginActual >= 0 && ... %negative if varies
                narginActual ~= narginExpected, ...
                'shared_tracking:UnscentedKalmanFilter:invalidNumInputsToCorrect',...
                fname,'MeasurementFcn');
            % 3)
            if ~obj.pIsValidMeasurementFcn
                coder.internal.errorIf(...
                    obj.pCorrector.validateMeasurementFcn(obj,z,varargin{:}),...
                    'shared_tracking:UnscentedKalmanFilter:MeasurementNonMatchingSizeOrClass',...
                    'MeasurementFcn');
                obj.pIsValidMeasurementFcn = true;
            end
        end
        
        function  validateMeasurementAndRelatedProperties(obj,z,fname,varargin)
            % Validate MeasurementFcn, State, StateCovariance, MeasurementNoise
            %
            % Inputs:
            %    z        - Measurement vector, provided by user. 
            %    varargin - Optional inputs for user provided measurement
            %               function (in obj.MeasurementFcn)
            %
            % * Validate the type and size of the user provided measurement
            % * Ensure MeasurementFcn is defined. If possible (it's not
            % varargin) validate the # of inputs to MeasurementFcn
            % * Ensure that the dimensions of x, P, R are known, and the
            % corresponding protected properties are defined
            %
            % Validations are performed only once, or when necessary.
            ensureStateAndStateCovarianceIsDefined(obj);
            if obj.pIsFirstCallCorrect
                validateMeasurementFcn(obj,z,fname,varargin{:});
                obj.pIsFirstCallCorrect = false();
            end
            obj.pN = numel(z);
            ensureMeasurementNoiseIsDefined(obj);
        end
    end
    
    methods ( Access = {?matlabshared.tracking.internal.UnscentedKalmanFilter, ?matlabshared.tracking.internal.UKFCorrector})
        function ensureMeasurementNoiseIsDefined(obj)
            % Ensure that measurement noise covariance dimension pV,
            % measurement noise covariance R are defined before we perform
            % a correct or distance operation.
            %
            % Perform scalar expansion if pV is defined, but R is not
            % assigned
            
            % pV was not defined during construction even if MeasurementNoise
            % was set. Now, set it if it was supposed to be set earlier.
            if ~coder.internal.is_defined(obj.pV)
                if coder.internal.is_defined(obj.pSqrtMeasurementNoise)
                    obj.pV = size(obj.pSqrtMeasurementNoise,1);
                elseif coder.internal.is_defined(obj.pSqrtMeasurementNoiseScalar)
                    obj.pV = 1;
                end
            end

            % if pSqrtMeasurementNoise hasn't been defined yet, we define
            % it using pV. This is just enforcing the size, actual value will
            % be set by scalar expansion or otherwise during run-time.
            if ~coder.internal.is_defined(obj.pSqrtMeasurementNoise)
                n = obj.pV;
                obj.pSqrtMeasurementNoise = coder.nullcopy(zeros(n,n,obj.pDataType));
            end
            coder.internal.assert(coder.internal.is_defined(obj.pV),...
                'shared_tracking:UnscentedKalmanFilter:UnknownNumberOfMeasurementNoiseInputs');
            
            % Scalar expand R if necessary
            measurementNoiseScalarExpandIfNecessary(obj);
        end
    end
    
    methods (Static)
        %--------------------------------------------------------------------
        % loadobj to make sure that the filter is loaded correctly.
        % This method cannot be inherited from the superclass because the
        % correct object type (phased.UnscentedKalmanFilter) has to be
        % created. Note: the saveobj method is inherited as is from the
        % superclass.
        %--------------------------------------------------------------------
        function retUKF = loadobj(sobj)
            % Assign the properties that the remaining ones depend on
            if isfield(sobj,'HasMeasurementWrapping')
                hasWrap = sobj.HasMeasurementWrapping;
            else
                hasWrap = false;
            end
            retUKF = matlabshared.tracking.internal.UnscentedKalmanFilter...
                ('DataType', sobj.pDataType, ...
                'HasAdditiveProcessNoise', sobj.HasAdditiveProcessNoise, ...
                'HasAdditiveMeasurementNoise', sobj.HasAdditiveMeasurementNoise,...
                'HasMeasurementWrapping', hasWrap);
            % Load the remaining properties
            loadobjHelper(retUKF,sobj);
        end
        
        function props = matlabCodegenNontunableProperties(~)
            % Let the coder know about non-tunable parameters so that it
            % can generate more efficient code.
            props = {'pM','pW',...
                'pIsStateColumnVector',...
                'HasAdditiveProcessNoise','HasAdditiveMeasurementNoise',...
                'StateTransitionFcn','MeasurementFcn',...
                'pDataType'};
            % pPredictor, pCorrector: These are non-tunable but codegen
            % does not allow specifying class-valued properties as
            % nontunable
        end

        function props = matlabCodegenSoftNontunableProperties(~)
            props = {'pN','pV'};
        end
    end
end
