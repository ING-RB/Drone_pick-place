classdef ExtendedKalmanFilter < handle
   %

   % Leave the above row empty to suppress the message: "Help for X is
   % inherited from superclass matlabshared.tracking.internal.ExtendedKalmanFilter"

   %ExtendedKalmanFilter extended Kalman filter for object tracking
   %   This extended Kalman filter is designed for tracking. You can use
   %   it to predict object's future location, to reduce noise in the
   %   detected location, or to help associate multiple objects with their
   %   tracks. The extended Kalman filter is used for tracking objects
   %   that move according to a nonlinear motion model, or that are
   %   measured by a nonlinear measurement model.
   %
   %   Additive noise models:
   %      x(k) = f(x(k-1), u(k-1)) + w(k-1)         (state equation)
   %      z(k) = h(x(k)) + v(k)                     (measurement equation)
   %
   %   Non-additive noise models:
   %      x(k) = f(x(k-1), w(k-1), u(k-1))          (state equation)
   %      z(k) = h(x(k), v(k))                      (measurement equation)
   %
   %   The extended Kalman filter uses a first order Taylor series to
   %   approximate the propagation of the uncertainty in the state through
   %   the nonlinear state and measurement equations. Thus, the extended
   %   Kalman filter requires the following Jacobians to be evaluated at
   %   the state estimate:
   %
   %       Jfx = df/dx                         (state transition Jacobian)
   %       Jhx = dh/dx                         (measurement Jacobian)
   %
   %   The extended Kalman filter algorithm involves two steps.
   %      * Predict: Using the current state to predict the next state.
   %      * Correct, also known as update: Using the current measurement,
   %           such as the detected object location, to correct the state.
   %
   %   obj = ExtendedKalmanFilter returns an extended Kalman filter object
   %   with default state transition function and measurement function and
   %   assumes an additive noise model.
   %
   %   obj = ExtendedKalmanFilter(StateTransitionFcn, MeasurementFcn, State)
   %   lets you specify the state transition function, f, and the
   %   measurement model, h. Both must be specified as function_handles.
   %   In addition, it lets you specify an initial value for the state.
   %
   %   obj = ExtendedKalmanFilter(..., Name, Value) configures the
   %   extended Kalman filter object properties, specified as one or more
   %   name-value pair arguments. Unspecified properties have default
   %   values.
   %
   %   predict method syntax:
   %
   %   [x_pred, P_pred] = predict(obj) returns the prediction of the state
   %   and state estimation error covariance at the next time step. The
   %   internal state and covariance of Kalman filter are overwritten by
   %   the prediction results.
   %
   %   [x_pred, P_pred] = predict(obj, varargin) additionally, lets you
   %   specify additional inputs that will be passed to and used by the
   %   StateTransitionFcn.
   %
   %   correct method syntax:
   %
   %   [x_corr, P_corr] = correct(obj, z) returns the correction of the
   %   state and state estimation error covariance based on the current
   %   measurement z, an N-element vector. The internal state and
   %   covariance of Kalman filter are overwritten by the corrected
   %   values.
   %
   %   [x_corr, P_corr] = correct(obj, z, varargin) additionally, lets you
   %   specify input arguments that will be passed to and used by the
   %   MeasurementFcn
   %
   %   Notes:
   %   ======
   %   * If the measurement exists, e.g., the object has been detected,
   %     you can call the predict method and the correct method together.
   %     If the measurement is missing, you can call the predict method
   %     but not the correct method.
   %
   %       If the object is detected
   %          predict(extendedKalmanFilter);
   %          trackedLocation = correct(extendedKalmanFilter, objectLocation);
   %       Else
   %          trackedLocation = predict(extendedKalmanFilter);
   %       End
   %
   %   ExtendedKalmanFilter methods:
   %
   %   predict  - Predicts the state and state estimation error covariance
   %   correct  - Corrects the state and state estimation error covariance
   %
   %   ExtendedKalmanFilter properties:
   %
   %   HasAdditiveProcessNoise     - True if process noise is additive
   %   StateTransitionFcn          - Promotes the state to next time step, (f)
   %   HasAdditiveMeasurementNoise - True if measurement noise is additive
   %   MeasurementFcn              - Calculates the measurement, (h)
   %   State                       - State, (x)
   %   StateCovariance             - State estimation error covariance, (P)
   %   ProcessNoise                - Process noise covariance, (Q)
   %   MeasurementNoise            - Measurement noise covariance, (R)
   %   StateTransitionJacobianFcn  - State transition Jacobian matrix, (df/dx)
   %   MeasurementJacobianFcn      - Measurement Jacobian matrix, (dh/dx)
   %   HasMeasurementWrapping      - True if the measurement wraps (read only)

   %   References:
   %
   %   [1] Samuel Blackman and Robert Popoli, "Design and Analysis of Modern
   %       Tracking Systems", Artech House, 1999.

   %   Copyright 2016-2023 The MathWorks, Inc.

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
      %time step, (f).
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
      %   that produces an N-element measurement vector for an M-element
      %   state. The function may take additional input parameters if
      %   needed, e.g., in order to specify the sensor position.
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

      %StateTransitionJacobianFcn Jacobian of StateTransitionFcn
      %   Specify the function that calculates the Jacobian of the
      %   StateTransitionFcn, f. This function must take the same input
      %   arguments as the StateTransitionFcn. If not specified, the
      %   Jacobian will be numerically computed at every call to predict,
      %   which may increase processing time and numerical inaccuracy.
      %
      %   If HasAdditiveProcessNoise is true, the function should have
      %   one of the following signatures:
      %       dfdx(k) = StateTransitionJacobianFcn(x(k))
      %       dfdx(k) = StateTransitionJacobianFcn(x(k), parameters)
      %   where:
      %       dfdx(k)    - Jacobian of StateTransitionFcn with respect
      %                    to states x, df/dx, evaluated at x(k). An
      %                    M-by-M matrix where M is the number of states.
      %       x(k)       - Estimated state at time k.
      %       parameters - Any additional arguments that are needed
      %                    by the state transition function.
      %
      %   If HasAdditiveProcessNoise is false, the function should have
      %   one of the following signatures:
      %       [dfdx(k), dfdw(k)] = StateTransitionJacobianFcn(x(k), w(k))
      %       [dfdx(k), dfdw(k)] = ...
      %           StateTransitionJacobianFcn(x(k), w(k), parameters)
      %   where:
      %       dfdx(k)    - Jacobian of StateTransitionFcn with respect
      %                    to states x, df/dx, evaluated at x(k), w(k).
      %                    An M-by-M matrix where M is the number of
      %                    states.
      %       dfdw(k)    - Jacobian of StateTransitionFcn with respect to
      %                    process noise w, df/dw, evaluated at x(k),
      %                    w(k).
      %                    An M-by-W matrix where W is the number of
      %                    process noise terms in w.
      %       x(k)       - Estimated state at time k.
      %       w(k)       - Process noise at time k.
      %       parameters - Any additional arguments that are needed
      %                    by the state transition function.
      %
      %   Default: StateTransitionJacobianFcn = []
      StateTransitionJacobianFcn = [];

      %MeasurementJacobianFcn Jacobian of MeasurementFcn
      %   Specify the function that calculates the Jacobian of the
      %   MeasurementFcn, h. This function must take the same input
      %   arguments as the MeasurementFcn. If not specified, the
      %   Jacobian will be numerically computed at every call to correct,
      %   which may increase processing time and numerical inaccuracy.
      %
      %   If HasAdditiveMeasurementNoise is true, the function should
      %   have one of the following signatures:
      %       dhdx(k) = MeasurementJacobianFcn(x(k))
      %       dhdx(k) = MeasurementJacobianFcn(x(k), parameters)
      %   where:
      %       dhdx(k)    - Jacobian of MeasurementFcn with respect to
      %                    states x, dh/dx, evaluated at x(k). An N-by-M
      %                    matrix where N is the number of measurements,
      %                    M is the number of states.
      %       x(k)       - Estimated state at time k.
      %       parameters - Any additional arguments that are needed
      %                    by the measurement function.
      %
      %   If HasAdditiveMeasurementNoise is false, the function should
      %   have one of the following signatures:
      %       [dhdx(k), dhdv(k)] = MeasurementJacobianFcn(x(k), v(k))
      %       [dhdx(k), dhdv(k)] = ...
      %           MeasurementJacobianFcn(x(k), v(k), parameters)
      %   where:
      %       dhdx(k)    - Jacobian of MeasurementFcn with respect to
      %                    states x, dh/dx, evaluated at x(k), v(k). An
      %                    N-by-M matrix. N is the number of
      %                    measurements, M is the number of states.
      %       dhdv(k)    - Jacobian of MeasurementFcn with respect to
      %                    measurement noise v, dh/dv, evaluated at x(k),
      %                    v(k). An N-by-V matrix where V is the number
      %                    of measurement noise terms in v.
      %       x(k)       - Estimated state at time k.
      %       v(k)       - Measurement noise at time k.
      %       parameters - Any additional arguments that are needed
      %                    by the measurement function.
      %
      %   Default: MeasurementJacobianFcn = []
      MeasurementJacobianFcn = [];

   end

   %------------------------------------------------------------------------
   % Dependent properties whose values are stored in other hidden properties
   %------------------------------------------------------------------------
   properties(Access=public, Dependent=true)
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
   properties(Dependent=true)
      %ProcessNoise Process noise covariance (Q)
      %   If HasAdditiveProcessNoise is true: specify the covariance of
      %   process noise as a scalar or an M-by-M matrix. If you specify
      %   it as a scalar it will be extended to an M-by-M diagonal
      %   matrix.
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
      %   of measurement noise as a scalar or an N-by-N matrix. If you
      %   specify it as a scalar it will be extended to an N-by-N
      %   diagonal matrix.
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

   %----------------------------------------------------------------------
   % Hidden properties used by the object
   %----------------------------------------------------------------------
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
      pHasPrediction;
      pHasStateTransitionJacobianFcn = false;
      pHasMeasurementJacobianFcn = false;
      pIsValidStateTransitionFcn = false(); % True if StateTransitionFcn was validated
      pIsValidMeasurementFcn = false(); % True if MeasurementFcn was validated
      pIsStateColumnVector = true();
      pPredictor;
      pCorrector;
      pDataType;
      pIsFirstCallPredict = true(); % false after calling predict once
      pIsFirstCallCorrect = true(); % false after calling correct once
      pVersion; % Property indicating version of EKF object
      pJacobian; % Property to store the last Jacobian from predict
   end

   %------------------------------------------------------------------------
   % Constant properties which store the default values
   %------------------------------------------------------------------------
   properties(Hidden, GetAccess=public, Constant=true)
      constStateCovariance                = 1;
      constProcessNoise                   = 1;
      constMeasurementNoise               = 1;
      constHasStateTransitionJacobianFcn  = false;
      constHasMeasurementJacobianFcn      = false;
      constHasAdditiveMeasurementNoise    = true;
      constHasAdditiveProcessNoise        = true;
      constDataType                       = 'double';
      constHasMeasurementWrapping         = false;
   end

   methods
      %----------------------------------------------------------------------
      % Constructor
      %----------------------------------------------------------------------
      function obj = ExtendedKalmanFilter(varargin)

         %

         % Leave the above row empty to suppress the message: "Help for X is
         % inherited from superclass matlabshared.tracking.internal.ExtendedKalmanFilter"

         % The object can be constructed with either 0, 2 or 3 inputs
         % before the first Name-Value pair. Therefore, the constructor
         % should fail if the first Name-Value pair is in place 2 (after
         % one input) or more than 4 (after more than 3 inputs).
         firstNVIndex = matlabshared.tracking.internal.findFirstNVPair(varargin{:});

         coder.internal.errorIf(firstNVIndex==2 || firstNVIndex>4, ...
            'shared_tracking:ExtendedKalmanFilter:invalidInputsToConstructor', firstNVIndex-1);

         % Parse the inputs.
         if isempty(coder.target)  % Simulation
            [stateTransitionFcn, measurementFcn, state, stateCovariance,...
               processNoise, measurementNoise, stateTransitionJacobianFcn,...
               measurementJacobianFcn, hasAdditiveProcessNoise, ...
               hasAdditiveMeasurementNoise, dataType, hasWrapping] ...
               = parseInputsSimulation(obj, varargin{:});
         else                      % Code generation
            [stateTransitionFcn, measurementFcn, state, stateCovariance,...
               processNoise, measurementNoise, stateTransitionJacobianFcn,...
               measurementJacobianFcn, hasAdditiveProcessNoise, ...
               hasAdditiveMeasurementNoise, dataType, hasWrapping] ...
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
         obj.setCorrector(hasAdditiveMeasurementNoise,hasWrapping);

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
         if ~isempty(stateTransitionJacobianFcn)
            obj.StateTransitionJacobianFcn = stateTransitionJacobianFcn;
         end
         if ~isempty(measurementJacobianFcn)
            obj.MeasurementJacobianFcn     = measurementJacobianFcn;
         end

         % Since there is no way of validating the function handles
         % before the first call that uses them, keep their IsValid
         % state as false.
         obj.pIsValidMeasurementFcn = false;
         obj.pIsValidStateTransitionFcn = false;

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

         % Indicate current version of EKF object
         %   Evolution of EKF Objects
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
         %   The internal state and covariance of Kalman filter are
         %   overwritten by the prediction results.
         %
         %   [x_pred, P_pred] = predict(obj, varargin) additionally,
         %   lets you specify additional parameters that will be used by
         %   StateTransitionFcn.

         % predict must be called with a single object
         coder.internal.errorIf(numel(obj) > 1, ...
            'shared_tracking:ExtendedKalmanFilter:NonScalarFilter', ...
            'extended Kalman filter', 'predict');

         ensureFilterPredictionReadiness(obj, varargin{:});

         % Perform the EKF prediction
         [obj.pState, obj.pSqrtStateCovariance, obj.pJacobian] = ...
            obj.pPredictor.predict(...
            obj.pSqrtProcessNoise, ...
            obj.pState, ...
            obj.pSqrtStateCovariance, ...
            obj.StateTransitionFcn, ...
            obj.StateTransitionJacobianFcn, ...
            varargin{:});

         obj.pHasPrediction = true;

         % obj.State outputs the estimated state in the orientation of
         % initial state provided by the user
         if nargout
            x_pred = obj.State;
            if nargout > 1
               P_pred = obj.pStateCovariance;
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
         %   covariance of Kalman filter are overwritten by the
         %   corrected values.
         %
         %   [x_corr, P_corr] = correct(obj, z, varargin) additionally
         %   allows the definition of parameters used by the
         %   MeasurementFcn in addition to obj.State. For example, the
         %   sensor's location.

         % correct must be called with a single object
         coder.internal.errorIf(numel(obj) > 1, ...
            'shared_tracking:ExtendedKalmanFilter:NonScalarFilter', ...
            'extended Kalman filter', 'correct');

         % Validate z. Skip the size check if it's not known yet (first
         % call to correct)
         if coder.internal.is_defined(obj.pN)
            matlabshared.tracking.internal.validateInputSizeAndType...
               ('z', 'ExtendedKalmanFilter', z, obj.pN);
         else
            matlabshared.tracking.internal.validateInputSizeAndType...
               ('z', 'ExtendedKalmanFilter', z);
         end

         % Measurements z can be a row or column vector.
         %
         % Validate z, x, P, R
         validateMeasurementAndRelatedProperties(obj, z, 'correct', varargin{:});

         % Perform the EKF correction
         [obj.pState, obj.pSqrtStateCovariance] = ...
            obj.pCorrector.correct(...
            z, ...
            getSqrtMeasurementNoise(obj), ...
            obj.pState, ...
            obj.pSqrtStateCovariance, ...
            obj.MeasurementFcn, ...
            obj.MeasurementJacobianFcn, ...
            varargin{:});
         obj.pHasPrediction = false;

         % obj.State outputs the estimated state in the orientation of
         % initial state provided by the user
         if nargout
            x_corr = obj.State;
            if nargout > 1
               P_corr = obj.pStateCovariance;
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
         %       S = H*P*H'+R, where H is the measurement Jacobian
         %           function, P is the state covariance and R is the
         %           measurement noise.
         %
         %   [...] = residual(obj, z, varargin) allows
         %   passing additional parameters that will be used by the
         %   EKF.MeasurementFcn.

         cond = (numel(obj) > 1);
         coder.internal.errorIf(cond, ...
            'shared_tracking:ExtendedKalmanFilter:NonScalarFilter', ...
            'extended Kalman filter', 'residual');

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
         [res, S] = obj.pCorrector.residual(...
            z, ...
            getSqrtMeasurementNoise(obj), ...
            obj.pState, ...
            obj.pSqrtStateCovariance, ...
            obj.MeasurementFcn, ...
            obj.MeasurementJacobianFcn, ...
            varargin{:});
      end

      function newEKF = clone(EKF)
         % clone Create a copy of the filter
         %
         % newEKF = clone(EKF)

         coder.inline('never');

         % clone must be called with a single object
         coder.internal.errorIf(numel(EKF) > 1, ...
            'shared_tracking:ExtendedKalmanFilter:NonScalarFilter', ...
            'extended Kalman filter', 'clone');

         % Use str2func to get the correct object type. When called from
         % a subclass, the resulting object will be of the same subclass
         obj = str2func(coder.const(class(EKF)));
         % Construct the basic filter. The properties assigned here are:
         % * pDataType: Guaranteed to be defined (after construction). It
         % must be set immediately as it impacts the types of default
         % floating point assignments in the constructor.
         % * HasAdditiveProcessNoise, HasAdditiveProcessNoise: These set
         % pPredictor, pCorrector which must be set before other
         % properties
         newEKF = obj(...
            'HasAdditiveProcessNoise', EKF.HasAdditiveProcessNoise,...
            'HasAdditiveMeasurementNoise', EKF.HasAdditiveMeasurementNoise,...
            'DataType', EKF.pDataType, ...
            'HasMeasurementWrapping', EKF.HasMeasurementWrapping);
         % Copy the rest of the properties
         %
         % ppProperties holds the list of all properties that may not be
         % set during construction
         ppProperties = coder.const({...
            'pIsSetStateCovariance', 'pIsSetProcessNoise', 'pIsSetMeasurementNoise',...
            'pM','pN','pV','pW',...
            'pState','pIsStateColumnVector',...
            'StateTransitionFcn','MeasurementFcn',...
            'pSqrtStateCovariance','pSqrtStateCovarianceScalar',... % pXScalar must be assigned after pX, as set.pX can overwrite pXScalar
            'pSqrtProcessNoise','pSqrtProcessNoiseScalar',...
            'pSqrtMeasurementNoise','pSqrtMeasurementNoiseScalar',...
            'StateTransitionJacobianFcn','MeasurementJacobianFcn',...
            'pHasPrediction',...
            'pIsValidStateTransitionFcn','pIsValidMeasurementFcn',...
            'pIsFirstCallPredict','pIsFirstCallCorrect','pJacobian'});
         for kk = coder.unroll(1:numel(ppProperties))
            % Copy only if the prop was set in the source obj
            if coder.internal.is_defined(EKF.(ppProperties{kk}))
               newEKF.(ppProperties{kk}) = EKF.(ppProperties{kk});
            end
         end
      end
   end

   methods % Auto-Diff functionality
      function [fcn, constants] = generateJacobianFcn(obj, Type, varargin)
         %generateJacobianFcn Generate state-transition or measurement function Jacobian.
         %
         %  [FCN_S, CONST] = generateJacobianFcn(OBJ, 'state', Us1, ..., Usn)
         %     generates MATLAB functions which compute the state-transition function's Jacobian
         %     based on the auto-differentiation (also known as autodiff, AD, or algorithmic
         %     differentiation) techniques. A MATLAB function file named
         %     "stateTransitionJacobianFcn.m" is created, along with a supporting file named
         %     "stateTransitionJacobianFcnAD.m", in the current working directory. FCN_S is an
         %     anonymous function that wraps "stateTransitionJacobianFcn.m". You can set the value
         %     of OBJ.StateTransitionJacobianFcn property to FCN_S.
         %
         %     Us1, ..., Usn are the additional input arguments used by the PREDICT method of OBJ.
         %     See the documentation for extendedKalmanFilter/predict for more information.
         %
         %     stateTransitionJacobianFcn is a function with signature:
         %             dx = fcn(OBJ,  Us1, ..., Usn, CONST) (if OBJ.HasAdditiveProcessNoise is TRUE)
         %        [dx,dw] = fcn(OBJ,w,Us1, ..., Usn, CONST) (if OBJ.HasAdditiveProcessNoise is FALSE)
         %     where CONST are certain additional constants that are used for computing the Jacobian
         %     matrix.
         %
         %  [FCN_M, CONST] = generateJacobianFcn(OBJ, 'measurement', Um1, ..., Umn)
         %     generates a MATLAB function which computes the measurement function's Jacobian based
         %     on the auto-differentiation techniques. A MATLAB function file named
         %     "measurementJacobianFcn.m" is created, along with a supporting file named
         %     "measurementJacobianFcnAD.m", in the current working directory. FCN_M is an
         %     anonymous function that wraps "measurementJacobianFcn.m". You can set the value
         %     of OBJ.MeasurementJacobianFcn property to FCN_M.
         %
         %     Um1, ..., Umn are the additional input arguments used by the CORRECT method of OBJ.
         %     See the documentation for extendedKalmanFilter/correct for more information.
         %
         %     measurementJacobianFcn is a function with signature:
         %             dy = fcn(OBJ,  Um1, ..., Umn, CONST) (if OBJ.HasAdditiveMeasurementNoise is TRUE)
         %        [dy,dv] = fcn(OBJ,v,Um1, ..., Umn, CONST) (if OBJ.HasAdditiveMeasurementNoise is FALSE)
         %     where CONST are certain additional constants that are used for computing the Jacobian
         %     matrix.
         %
         %  [FCN, ...] = generateJacobianFcn(..., 'FileName', FILENAME)
         %     specifies the name of the generated function. FILENAME can be a fully qualified name
         %     of the file containing absolute or relative path to the desired folder. If the chosen
         %     folder is not on MATLAB path, the returned output FCN is []. In order to
         %     generate a valid function handle, you must perform the following steps: 
         %     1. Copy the two generated files to a folder on MATLAB path. 
         %     2. Run:
         %         [~,FcnName] = fileparts(FILENAME);
         %         FCN = @(varargin)FcnName(varargin{:},CONST); 
         %
         % See also extendedKalmanFilter, extendedKalmanFilter/predict, extendedKalmanFilter/correct.
         
         coder.internal.assert(isempty(coder.target),'shared_tracking:ExtendedKalmanFilter:AutoDiff_GenFcnCoderSupport')
         if isempty(coder.target)
            narginchk(2,Inf)
            ni = nargin;
            validateattributes(Type,["char","string"],"scalartext","generateJacobianFcn","Type")
            Type = string(lower(Type));
            if ~any(Type==["state","measurement"])
               error(message('shared_tracking:ExtendedKalmanFilter:AutoDiff_FcnType',"state","measurement"))
            end

            jacPath = pwd;
            STATE = Type=="state";
            if STATE
               jacName = "stateTransitionJacobianFcn";
               MainFcn = obj.StateTransitionFcn;
               d = obj.pW;
               namepfx = 'Us';
               nonadd_pfx = 'w';
            else
               jacName = "measurementJacobianFcn";
               MainFcn = obj.MeasurementFcn;
               d = obj.pV;
               namepfx = 'Um';
               nonadd_pfx = 'v';
            end

            if ni>=4 && (ischar(varargin{end-1}) || isstring(varargin{end-1})) && ...
                  strcmpi(varargin{end-1},'FileName')
               v = varargin{end};
               try
                  [jacPath_,jacName,ext] = fileparts(v);
               catch E
                  throw(E)
               end
               if strlength(ext)>0 && ~strcmp(ext,'.m')
                  error(message('shared_tracking:ExtendedKalmanFilter:AutoDiff_FileExt'))
               end
               if ~isempty(jacPath_)
                  jacPath = string(jacPath_);
               end
               varargin = varargin(1:end-2);
            end

            % Create inputInfoStruct to be passed on to the internal generateJacobianFile
            nInputs = length(varargin);
            inputInfo = localAutoDiffStruct('',false,[1 1],[]);
            inputInfo = repmat(inputInfo,[nInputs,1]);

            % Set inputInfo
            inputInfo(1) = localAutoDiffStruct('x',true,[obj.pM,1],[]); 

            if (STATE && obj.HasAdditiveProcessNoise) || (~STATE && obj.HasAdditiveMeasurementNoise)
               for i = 1:length(varargin)
                  inputInfo(i + 1) = localAutoDiffStruct([namepfx,int2str(i)], false, size(varargin{i}), []);
               end
            else
               inputInfo(2) = localAutoDiffStruct(nonadd_pfx,true,[d 1],[]);
               for i = 1:length(varargin)
                  inputInfo(i + 2) = localAutoDiffStruct([namepfx,int2str(i)],false,size(varargin{i}),[]);
               end
            end

            constants = controllib.internal.util.generateJacobianFile(...
               MainFcn,jacName,inputInfo,Path=jacPath);

            % create function handle
            if exist(jacName,'file')==2
               fcn = eval(sprintf('@(varargin)%s(varargin{:},constants)',jacName));
            else
               warning(message('shared_tracking:ExtendedKalmanFilter:AutoDiff_Path',jacPath,jacName,"{:}"))
               fcn = [];
            end
         end
      end
   end

   methods
      %----------------------------------------------------------------------
      function set.State(obj, value)
         validateattributes(value, ...
            {obj.pDataType}, {'real', 'finite', 'nonsparse', 'vector'},...
            'ExtendedKalmanFilter', 'State');
         % Validate dimensions only when it is known
         if coder.internal.is_defined(obj.pM)
            coder.internal.assert(isscalar(value) || numel(value)==obj.pM, ...
               'shared_tracking:ExtendedKalmanFilter:invalidStateDims', obj.pM);
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
            'shared_tracking:ExtendedKalmanFilter:getUndefinedState');

         if obj.pIsStateColumnVector % User expects state to be a column vector
            value = obj.pState;
         else % User expects state to be a row vector
            value = obj.pState.';
         end
      end

      %----------------------------------------------------------------------
      function set.StateTransitionJacobianFcn(obj, value)
         % There are two valid options for StateTransitionJacobianFcn: an
         % empty value and a function_handle
         if isa(value, 'function_handle')
            validateattributes(value, {'function_handle'},...
               {'nonempty'}, 'ExtendedKalmanFilter', 'StateTransitionJacobianFcn');
            obj.StateTransitionJacobianFcn      = value;
            obj.pHasStateTransitionJacobianFcn  = true;
         elseif isempty(value)
            validateattributes(value, {'numeric'},...
               {}, 'ExtendedKalmanFilter', 'StateTransitionJacobianFcn');
            obj.StateTransitionJacobianFcn      = value;
            obj.pHasStateTransitionJacobianFcn  = false;
         else
            error(message('shared_tracking:ExtendedKalmanFilter:invalidJacobianType',...
               'StateTransitionJacobianFcn'))
         end
      end

      %----------------------------------------------------------------------
      function set.MeasurementJacobianFcn(obj, value)
         % There are two valid options for StateTransitionJacobianFcn: an
         % empty value and a function_handle
         if isa(value, 'function_handle')
            validateattributes(value, {'function_handle'},...
               {'nonempty'}, 'ExtendedKalmanFilter', 'MeasurementJacobianFcn');
            obj.MeasurementJacobianFcn      = value;
            obj.pHasMeasurementJacobianFcn  = true;
         elseif isempty(value)
            validateattributes(value, {'numeric'},...
               {}, 'ExtendedKalmanFilter', 'MeasurementJacobianFcn');
            obj.MeasurementJacobianFcn      = value;
            obj.pHasMeasurementJacobianFcn  = false;
         else
            error(message('shared_tracking:ExtendedKalmanFilter:invalidJacobianType',...
               'MeasurementJacobianFcn'))
         end
      end

      %----------------------------------------------------------------------
      function set.StateCovariance(obj, value)
         % Validating that the new state covariance has the correct
         % attributes and dimensions
         validateattributes(value, ...
            {obj.pDataType}, ...
            {'real', 'finite', 'nonsparse', '2d', 'nonempty', 'square'},...
            'ExtendedKalmanFilter', 'StateCovariance');
         % Check dims only if # of states is known
         if coder.internal.is_defined(obj.pM)
            matlabshared.tracking.internal.validateDataDims...
               ('StateCovariance', value, [obj.pM, obj.pM]);
         end
         matlabshared.tracking.internal.isSymmetricPositiveSemiDefinite...
            ('StateCovariance', value);

         % Square root factorization
         value = matlabshared.tracking.internal.cholPSD(value);

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
               'shared_tracking:ExtendedKalmanFilter:getUndefinedStateCovariance');
            stateCovarianceScalarExpandIfNecessary(obj);
            value = obj.pStateCovariance;
         end
      end

      %----------------------------------------------------------------------
      function set.ProcessNoise(obj, value)
         validateattributes(value, ...
            {obj.pDataType}, ...
            {'real', 'finite', 'nonsparse', '2d', 'nonempty','square'},...
            'ExtendedKalmanFilter', 'ProcessNoise');
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
               'shared_tracking:ExtendedKalmanFilter:getUndefinedProcessNoise');
            processNoiseScalarExpandIfNecessary(obj);
            value = obj.pProcessNoise;
         end
      end

      %----------------------------------------------------------------------
      function set.MeasurementNoise(obj, value)
         validateattributes(value, ...
            {obj.pDataType}, ...
            {'real', 'finite', 'nonsparse', '2d', 'nonempty', 'square'},...
            'ExtendedKalmanFilter', 'MeasurementNoise');
         % Every time the measurement function changes, this size may change so no size checking
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
               'shared_tracking:ExtendedKalmanFilter:getUndefinedMeasurementNoise');
            
            ensureMeasurementNoiseIsDefined(obj);
            value = obj.pMeasurementNoise;
         end
      end

      %----------------------------------------------------------------------
      function set.StateTransitionFcn(obj, value)
         validateattributes(value, {'function_handle'},...
            {'nonempty'}, 'ExtendedKalmanFilter', 'StateTransitionFcn');
         obj.pIsValidStateTransitionFcn = false;
         obj.StateTransitionFcn = value;
      end

      %----------------------------------------------------------------------
      function set.MeasurementFcn(obj, value)
         validateattributes(value, {'function_handle'}, ...
            {'nonempty'}, 'ExtendedKalmanFilter', 'measurementFcn');
         obj.pIsValidMeasurementFcn = false;
         obj.MeasurementFcn = value;
      end

      %----------------------------------------------------------------------
      function set.HasAdditiveProcessNoise(~, ~)

         % Note: HasAdditiveProcessNoise depends on pPredictor, which is
         % set via setPredictor() during construction
         ex = MException(message('shared_tracking:ExtendedKalmanFilter:PropertyOnlySettableDuringConstruction',...
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
         ex = MException(message('shared_tracking:ExtendedKalmanFilter:PropertyOnlySettableDuringConstruction',...
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
            'positive', 'integer', 'scalar'}, 'ExtendedKalmanFilter');
         validateattributes(measurementNoiseSize, {'numeric'}, {'real', ...
            'positive', 'integer', 'scalar'}, 'ExtendedKalmanFilter');
         coder.internal.assert(~obj.HasAdditiveMeasurementNoise || measurementSize==measurementNoiseSize,...
            'shared_tracking:KalmanFilter:IncompatibleMeasSizeAndNoiseSize');
         obj.pN = measurementSize;
         obj.pV = measurementNoiseSize;
      end

      function setStateSizes(obj, stateSize, processNoiseSize)
         % Sets the sizes of the state (pM) and process noise
         % (pW). Both have to be a real, positive, integer, scalar.
         validateattributes(stateSize, {'numeric'}, {'real', ...
            'positive', 'integer', 'scalar'}, 'ExtendedKalmanFilter');
         validateattributes(processNoiseSize, {'numeric'}, {'real', ...
            'positive', 'integer', 'scalar'}, 'ExtendedKalmanFilter');
         obj.pM = stateSize;
         obj.pW = processNoiseSize;
      end
   end

   methods(Access=private)
      %----------------------------------------------------------------------
      % Parse inputs for simulation
      %----------------------------------------------------------------------
      function [stateTransitionFcn, measurementFcn, state, ...
            stateCovariance, processNoise, measurementNoise, ...
            stateTransitionJacobianFcn, measurementJacobianFcn, ...
            hasAdditiveProcessNoise, hasAdditiveMeasurementNoise, dataType, hasWrapping] ...
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
         parser.addParameter('HasAdditiveProcessNoise', obj.constHasAdditiveProcessNoise);
         parser.addParameter('HasAdditiveMeasurementNoise', obj.constHasAdditiveMeasurementNoise);
         parser.addParameter('StateTransitionJacobianFcn', []);
         parser.addParameter('MeasurementJacobianFcn', []);
         parser.addParameter('DataType', obj.constDataType);
         parser.addParameter('HasMeasurementWrapping', obj.constHasMeasurementWrapping);

         % Parse parameters
         parse(parser, varargin{:});
         r = parser.Results;

         stateTransitionFcn            =  r.StateTransitionFcn;
         measurementFcn                =  r.MeasurementFcn;
         state                         =  r.State;
         stateCovariance               =  r.StateCovariance;
         processNoise                  =  r.ProcessNoise;
         measurementNoise              =  r.MeasurementNoise;
         stateTransitionJacobianFcn    =  r.StateTransitionJacobianFcn;
         measurementJacobianFcn        =  r.MeasurementJacobianFcn;
         hasAdditiveProcessNoise       =  r.HasAdditiveProcessNoise;
         hasAdditiveMeasurementNoise   =  r.HasAdditiveMeasurementNoise;
         dataType                      =  r.DataType;
         hasWrapping                   =  r.HasMeasurementWrapping;
      end

      %----------------------------------------------------------------------
      % Parse inputs for code generation
      %----------------------------------------------------------------------
      function [stateTransitionFcn, measurementFcn, state, ...
            stateCovariance, processNoise, measurementNoise, ...
            stateTransitionJacobianFcn, measurementJacobianFcn, ...
            hasAdditiveProcessNoise, hasAdditiveMeasurementNoise, dataType, hasWrapping] ...
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
            'StateTransitionJacobianFcn',   uint32(0), ...
            'MeasurementJacobianFcn',       uint32(0), ...
            'HasAdditiveProcessNoise',      uint32(0), ...
            'HasAdditiveMeasurementNoise',  uint32(0), ...
            'DataType',                     uint32(0), ...
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
         stateTransitionJacobianFcn = eml_get_parameter_value(optarg.StateTransitionJacobianFcn,...
            [], varargin{firstNVIndex:end});
         measurementJacobianFcn = eml_get_parameter_value(optarg.MeasurementJacobianFcn,...
            [], varargin{firstNVIndex:end});
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
            {'scalar', 'binary'},...
            'ExtendedKalmanFilter', 'HasAdditiveMeasurementNoise');
         validateattributes(hasWrapping, ...
            {'numeric', 'logical'},...
            {'scalar', 'binary'},...
            'ExtendedKalmanFilter', 'HasMeasurementWrapping');
         if hasAdditiveMeasurementNoise
            obj.pCorrector = matlabshared.tracking.internal.EKFCorrectorAdditive();
         else
            obj.pCorrector = matlabshared.tracking.internal.EKFCorrectorNonAdditive();
         end
         obj.pCorrector.HasMeasurementWrapping = hasWrapping;
      end


      function setPredictor(obj, hasAdditiveProcessNoise)
         validateattributes(hasAdditiveProcessNoise, ...
            {'numeric', 'logical'},...
            {'scalar', 'binary'},...
            'ExtendedKalmanFilter', 'HasAdditiveProcessNoise');
         if hasAdditiveProcessNoise
            obj.pPredictor = matlabshared.tracking.internal.EKFPredictorAdditive();
         else
            obj.pPredictor = matlabshared.tracking.internal.EKFPredictorNonAdditive();
         end
      end

   end

   methods (Access = protected)
      function ensureFilterPredictionReadiness(obj, varargin)
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
                  'shared_tracking:ExtendedKalmanFilter:undefinedStateTransitionFcn');
            end
            % 2)
            narginExpected = obj.pPredictor.getExpectedNargin(nargin);
            narginActual = nargin(obj.StateTransitionFcn);
            coder.internal.errorIf(narginActual ~= narginExpected && ...
               narginActual >= 0, ... %negative if varies
               'shared_tracking:ExtendedKalmanFilter:invalidNumInputsToPredict',...
               'StateTransitionFcn');
            % 3)
            if ~obj.pIsValidStateTransitionFcn
               coder.internal.errorIf(...
                  obj.pPredictor.validateStateTransitionFcn(obj.StateTransitionFcn,obj.pState,obj.pW,varargin{:}),...
                  'shared_tracking:ExtendedKalmanFilter:StateNonMatchingSizeOrClass',...
                  'StateTransitionFcn', 'State', numel(obj.pState));
               obj.pIsValidStateTransitionFcn = true;
            end

            % Validate StateTransitionJacobianFcn
            % (obj.pHasStateTransitionJacobianFcn = true only when Jacobian is
            % specified)
            if obj.pHasStateTransitionJacobianFcn
               validateStateTransitionJacobianFcn(obj,varargin{:});
            end

            obj.pIsFirstCallPredict = false();
         end
      end

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
      function sobj = saveobj(EKF)
         sobj = struct(...
            'HasAdditiveProcessNoise',     EKF.HasAdditiveProcessNoise, ...
            'StateTransitionFcn',          EKF.StateTransitionFcn, ...
            'HasAdditiveMeasurementNoise', EKF.HasAdditiveMeasurementNoise, ...
            'MeasurementFcn',              EKF.MeasurementFcn, ...
            'StateTransitionJacobianFcn',  EKF.StateTransitionJacobianFcn, ...
            'MeasurementJacobianFcn',      EKF.MeasurementJacobianFcn, ...
            'State',                       EKF.State, ...
            'StateCovariance',             EKF.StateCovariance, ...
            'ProcessNoise',                EKF.ProcessNoise, ...
            'MeasurementNoise',            EKF.MeasurementNoise, ...
            'pM',                          EKF.pM, ...
            'pN',                          EKF.pN, ...
            'pW',                          EKF.pW, ...
            'pV',                          EKF.pV, ...
            'pState',                      EKF.pState, ...
            'pSqrtStateCovariance',        EKF.pSqrtStateCovariance, ...
            'pSqrtStateCovarianceScalar',  EKF.pSqrtStateCovarianceScalar, ...
            'pSqrtProcessNoise',           EKF.pSqrtProcessNoise, ...
            'pSqrtProcessNoiseScalar',     EKF.pSqrtProcessNoiseScalar, ...
            'pSqrtMeasurementNoise',       EKF.pSqrtMeasurementNoise, ...
            'pSqrtMeasurementNoiseScalar', EKF.pSqrtMeasurementNoiseScalar, ...
            'pHasPrediction',              EKF.pHasPrediction, ...
            'pIsValidStateTransitionFcn',  EKF.pIsValidStateTransitionFcn, ...
            'pIsValidMeasurementFcn',      EKF.pIsValidMeasurementFcn, ...
            'pIsStateColumnVector',        EKF.pIsStateColumnVector,...
            'pDataType',                   EKF.pDataType,...
            'pVersion',                    EKF.pVersion,...
            'pIsFirstCallPredict',         EKF.pIsFirstCallPredict,...
            'pIsFirstCallCorrect',         EKF.pIsFirstCallCorrect,...
            'pJacobian',                   EKF.pJacobian,...
            'HasMeasurementWrapping',      EKF.HasMeasurementWrapping);
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

      function loadobjHelper(EKF,sobj)
         % Helper for loadobj to maximize the shared code between
         % subclasses

         % Subclasses must:
         % * Construct object of the correct type, with DataType,
         % HasAdditiveProcessNoise, HasAdditiveMeasurementNoise
         % specified as NV pairs
         % * Call this method

         % Tunable, always-known-dimension public properties
         %
         % None

         % Nontunable public properties
         if ~isempty(sobj.StateTransitionFcn)
            EKF.StateTransitionFcn = sobj.StateTransitionFcn;
         end
         if ~isempty(sobj.MeasurementFcn)
            EKF.MeasurementFcn = sobj.MeasurementFcn;
         end
         if ~isempty(sobj.StateTransitionJacobianFcn)
            EKF.StateTransitionJacobianFcn = sobj.StateTransitionJacobianFcn;
         end
         if ~isempty(sobj.MeasurementJacobianFcn)
            EKF.MeasurementJacobianFcn = sobj.MeasurementJacobianFcn;
         end

         % Tunable protected/private properties
         EKF.pHasPrediction             = sobj.pHasPrediction;
         EKF.pIsValidStateTransitionFcn = sobj.pIsValidStateTransitionFcn;
         EKF.pIsValidMeasurementFcn     = sobj.pIsValidMeasurementFcn;
         EKF.pIsFirstCallPredict        = sobj.pIsFirstCallPredict;
         EKF.pIsFirstCallCorrect        = sobj.pIsFirstCallCorrect;

         % Nontunable or fixed-dimension-but-might-be-unset
         % protected/private properties
         if ~isempty(sobj.pM)
            EKF.pM = sobj.pM;
         end
         if ~isempty(sobj.pN)
            EKF.pN = sobj.pN;
         end
         if ~isempty(sobj.pW)
            EKF.pW = sobj.pW;
         end
         if ~isempty(sobj.pV)
            EKF.pV = sobj.pV;
         end
         if ~isempty(sobj.pIsStateColumnVector)
            EKF.pIsStateColumnVector = sobj.pIsStateColumnVector;
         end
         if ~isempty(sobj.pState)
            EKF.pState = sobj.pState;
         end

         % Determine if object originated in the Square-root version
         if isfield(sobj,'pVersion') && (sobj.pVersion == 2)
            loadSqrtObj(EKF,sobj);
         else
            loadNonSqrtObj(EKF,sobj);
         end

         % Load the pJacobian property if exists
         if isfield(sobj,'pJacobian') && ~isempty(sobj.pJacobian)
            EKF.pJacobian = sobj.pJacobian;
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

      function loadSqrtObj(EKF,sobj)
         % For objects originating in the Square-root version

         % Non-scalar properties
         if ~isempty(sobj.pSqrtStateCovariance)
            % isempty check is a must-have for pIsSetStateCovariance
            % being loaded correctly
            EKF.pSqrtStateCovariance = sobj.pSqrtStateCovariance;
         end

         if ~isempty(sobj.pSqrtProcessNoise)
            % isempty check is a must-have for pIsSetStateCovariance
            % being loaded correctly
            EKF.pSqrtProcessNoise = sobj.pSqrtProcessNoise;
         end

         if ~isempty(sobj.pSqrtMeasurementNoise)
            % isempty check is a must-have for pIsSetStateCovariance
            % being loaded correctly
            EKF.pSqrtMeasurementNoise = sobj.pSqrtMeasurementNoise;
         end

         % The following (tunable protected) need to be loaded last.
         % Each pXScalar property has a corresponding pX property that
         % overwrites it in set.pX. Assigning pXScalar last ensures they
         % were not overwritten

         % Scalar properties
         EKF.pSqrtStateCovarianceScalar = sobj.pSqrtStateCovarianceScalar;
         EKF.pSqrtProcessNoiseScalar = sobj.pSqrtProcessNoiseScalar;
         EKF.pSqrtMeasurementNoiseScalar = sobj.pSqrtMeasurementNoiseScalar;
      end

      function loadNonSqrtObj(EKF,sobj)
         % For objects originating in the non-square-root version

         % Non-scalar properties
         if ~isempty(sobj.pStateCovariance)
            % isempty check is a must-have for pIsSetStateCovariance
            % being loaded correctly
            EKF.pSqrtStateCovariance = matlabshared.tracking.internal.cholPSD(sobj.pStateCovariance);
         end

         if ~isempty(sobj.pProcessNoise)
            % isempty check is a must-have for pIsSetStateCovariance
            % being loaded correctly
            EKF.pSqrtProcessNoise = matlabshared.tracking.internal.cholPSD(sobj.pProcessNoise);
         end

         if ~isempty(sobj.pMeasurementNoise)
            % isempty check is a must-have for pIsSetStateCovariance
            % being loaded correctly
            EKF.pSqrtMeasurementNoise = matlabshared.tracking.internal.cholPSD(sobj.pMeasurementNoise);
         end

         % The following (tunable protected) need to be loaded last.
         % Each pXScalar property has a corresponding pX property that
         % overwrites it in set.pX. Assigning pXScalar last ensures they
         % were not overwritten

         % Scalar properties
         if (sobj.pStateCovarianceScalar >= 0)
            EKF.pSqrtStateCovarianceScalar = matlabshared.tracking.internal.cholPSD(sobj.pStateCovarianceScalar);
         else
            EKF.pSqrtStateCovarianceScalar = sobj.pStateCovarianceScalar;
         end

         if (sobj.pProcessNoiseScalar >= 0)
            EKF.pSqrtProcessNoiseScalar = matlabshared.tracking.internal.cholPSD(sobj.pProcessNoiseScalar);
         else
            EKF.pSqrtProcessNoiseScalar = sobj.pProcessNoiseScalar;
         end

         if (sobj.pMeasurementNoiseScalar >= 0)
            EKF.pSqrtMeasurementNoiseScalar = matlabshared.tracking.internal.cholPSD(sobj.pMeasurementNoiseScalar);
         else
            EKF.pSqrtMeasurementNoiseScalar = sobj.pMeasurementNoiseScalar;
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
            'shared_tracking:ExtendedKalmanFilter:UnknownNumberOfStates');

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
            'shared_tracking:ExtendedKalmanFilter:UnknownNumberOfProcessNoiseInputs');

         % Scalar expand Q if necessary
         processNoiseScalarExpandIfNecessary(obj);
      end

      function validateStateTransitionJacobianFcn (obj,varargin)
         % Validate StateTransitionJacobianFcn
         % 1) Number of inputs must match the expected value
         % 3) Must return data of pState's class and of appropriate
         % dimensions
         %
         % Inputs:
         %    varargin: Extra input arguments to StateTransitionFcn

         % 1)
         narginExpected = obj.pPredictor.getExpectedNargin(nargin);
         narginActual = nargin(obj.StateTransitionJacobianFcn);
         coder.internal.errorIf(narginActual ~= narginExpected && ...
            narginActual >= 0, ... %negative if varies
            'shared_tracking:ExtendedKalmanFilter:invalidNumInputsToPredict',...
            'StateTransitionJacobianFcn');
         % 2)
         coder.internal.errorIf(...
            obj.pPredictor.validateStateTransitionJacobianFcn(obj.StateTransitionJacobianFcn,obj.pState,obj.pW,varargin{:}),...
            'shared_tracking:ExtendedKalmanFilter:StateTransitionJacobianNonMatchingSizeOrClass',...
            'StateTransitionJacobianFcn', numel(obj.State));
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

         % 1)
         if ~obj.pIsValidMeasurementFcn
            coder.internal.errorIf(isempty(obj.MeasurementFcn),...
               'shared_tracking:ExtendedKalmanFilter:undefinedMeasurementFcn');
         end
         % 2)
         narginExpected = numel(varargin) + obj.pCorrector.getNumberOfMandatoryInputs();
         narginActual = nargin(obj.MeasurementFcn);
         coder.internal.errorIf(narginActual >= 0 && ... %negative if varies
            narginActual ~= narginExpected,...
            'shared_tracking:ExtendedKalmanFilter:invalidNumInputsToCorrect',...
            fname,'MeasurementFcn');
         % 3)
         if ~obj.pIsValidMeasurementFcn
            coder.internal.errorIf(...
               obj.pCorrector.validateMeasurementFcn(obj,z,varargin{:}),...
               'shared_tracking:ExtendedKalmanFilter:MeasurementNonMatchingSizeOrClass',...
               'MeasurementFcn');
            obj.pIsValidMeasurementFcn = true;
         end
      end

      function validateMeasurementJacobianFcn(obj,z,fname,varargin)
         % Validate MeasurementJacobianFcn
         % 1) Number of inputs must match the expected value
         % 2) Must return data of pState's class and of appropriate
         % dimensions
         %
         % Inputs:
         %    z: Measurements as a vector
         %    varargin: Extra input arguments to MeasurementFcn

         % 1)
         narginExpected = numel(varargin) + obj.pCorrector.getNumberOfMandatoryInputs();
         narginActual = nargin(obj.MeasurementJacobianFcn);
         coder.internal.errorIf(narginActual >= 0 && ... %negative if varies
            narginActual ~= narginExpected,...
            'shared_tracking:ExtendedKalmanFilter:invalidNumInputsToCorrect',...
            fname,'MeasurementJacobianFcn');
         % 2)
         coder.internal.errorIf(...
            obj.pCorrector.validateMeasurementJacobianFcn(obj,z,varargin{:}),...
            'shared_tracking:ExtendedKalmanFilter:MeasurementJacobianNonMatchingSizeOrClass',...
            'MeasurementJacobianFcn',intnumel(z),intnumel(obj.State));
      end

      function  validateMeasurementAndRelatedProperties(obj,z,fname,varargin)
         % Validate MeasurementFcn, State, StateCovariance, MeasurementNoise
         %
         % Inputs:
         %    z        - Measurement vector, provided by user.
         %    fname    - Name of function calling the validation,
         %               expecting correct or correctjpda
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

            % Validate MeasurementFcn
            validateMeasurementFcn(obj,z,fname,varargin{:});

            % Validate MeasurementJacobianFcn
            % (obj.pHasMeasurementJacobianFcn = true only when Jacobian is
            % specified).
            if obj.pHasMeasurementJacobianFcn
               validateMeasurementJacobianFcn(obj,z,fname,varargin{:});
            end

            obj.pIsFirstCallCorrect = false();
         end
         obj.pN = numel(z);
         ensureMeasurementNoiseIsDefined(obj);
      end
   end

   methods ( Access = {?matlabshared.tracking.internal.ExtendedKalmanFilter, ?matlabshared.tracking.internal.EKFCorrector})
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
            'shared_tracking:ExtendedKalmanFilter:UnknownNumberOfMeasurementNoiseInputs');

         % Scalar expand R if necessary
         measurementNoiseScalarExpandIfNecessary(obj);
      end
   end


   methods (Static = true)
      function retEKF = loadobj(sobj)
         % Assign the properties that the remaining ones depend on
         if isfield(sobj,'HasMeasurementWrapping')
            hasWrap = sobj.HasMeasurementWrapping;
         else
            hasWrap = false;
         end
         retEKF = matlabshared.tracking.internal.ExtendedKalmanFilter...
            ('DataType', sobj.pDataType, ...
            'HasAdditiveProcessNoise', sobj.HasAdditiveProcessNoise, ... % set pPredictor
            'HasAdditiveMeasurementNoise', sobj.HasAdditiveMeasurementNoise, ...
            'HasMeasurementWrapping', hasWrap); % set pCorrector
         % Load the remaining properties
         loadobjHelper(retEKF,sobj);
      end
   end

   methods(Static,Hidden)
      function props = matlabCodegenNontunableProperties(~)
         % Let the coder know about non-tunable parameters so that it
         % can generate more efficient code.
         props = {'pM','pW',...
            'pIsStateColumnVector',...
            'HasAdditiveProcessNoise','HasAdditiveMeasurementNoise',...
            'StateTransitionFcn','MeasurementFcn',...
            'StateTransitionJacobianFcn','MeasurementJacobianFcn',...
            'pHasStateTransitionJacobianFcn','pHasMeasurementJacobianFcn',...
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

% A local function to calculate numel(in) with guaranteed integer casting
% in generated code
function n = intnumel(in)
if coder.target('MATLAB')
   n = numel(in);
else
   n = coder.internal.indexInt(numel(in));
end
end

function S = localAutoDiffStruct(Name,IsDecisionVar,Dim,DecisionIndex)

S = struct('VariableName',Name,...
   'IsDecisionVariable',IsDecisionVar,...
   'Dimension',Dim,...
   'DecisionIndex',DecisionIndex);
end
