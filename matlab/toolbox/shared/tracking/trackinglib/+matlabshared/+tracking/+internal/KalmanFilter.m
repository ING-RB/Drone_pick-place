%

% Leave the above row empty to suppress the message: "Help for X is
% inherited from superclass matlabshared.tracking.internal.KalmanFilter"

% This is a general purpose Kalman filter which can be used to estimate the
% state of state-space systems which may transition according to the
% following models:
% 
% Type 1. Additive noise with no control input
% x(k) = A*x(k-1) + w(k);
% 
% Type 2. Non additive noise with no control input
% x(k) = A*x(k-1) + G*w(k);
% 
% Type 3. Additive noise with control input
% x(k) = A*x(k-1) + B*u(k-1) + w(k);
% 
% Type 4. Non additive noise with control input
% x(k) = A*x(k-1) + B*u(k-1) + G*w(k)
%
% A = StateTransitionModel
% B = ControlModel
% G = ProcessNoiseModel
% ProcessNoise = variance(w(k)) 
%
% Similarly, the state may be observed using one of the following two
% models
% Type 1. Additive noise
% y(k) = H*x(k) + v(k);
%
% Type 2. Non-additive noise
% y(k) = H*x(k) + G2*v(k);
% 
% H = MeasurementModel
% G2 = MeasurementNoiseModel


%#codegen
%#ok<*EMCLS>
%#ok<*EMCA>
%#ok<*MCSUP>
classdef KalmanFilter < handle

  properties(SetAccess = public)
      %StateTransitionModel Model of state transition between time steps (A)
      %   Specify the transition of state between times as an M-by-M matrix,
      %   where M is the number of states.
      %
      %   Default: [1 1 0 0; 0 1 0 0; 0 0 1 1; 0 0 0 1]
      StateTransitionModel;
      
      %ControlModel Model relating control input to state (B)
      %   Specify the transition from control input to state as an M-by-L
      %   matrix, where M is the number of states and L is the number of
      %   control inputs.
      %
      %   Default: []
      ControlModel;
  end
  
  %------------------------------------------------------------------------
  % Dependent properties whose values are stored in other hidden properties
  %------------------------------------------------------------------------
  properties(Dependent=true)
    %State The state (x)
    %   Specify the state as a scalar or an M-element vector.
    %   If you specify it as a scalar it will be extended to an M-element
    %   vector.
    % 
    %   Default: 0
    State;
    %StateCovariance State estimation error covariance (P)
    %   Specify the covariance of the state estimation error as a scalar or
    %   an M-by-M matrix, where M is the number of states. If you specify
    %   it as a scalar it will be extended to an M-by-M diagonal matrix.
    %
    %   Default: 1
    StateCovariance;
    
    %MeasurementNoise Measurement noise covariance (R)
    %   Specify the covariance of measurement noise as a scalar or an
    %   N-by-N matrix, where N is the number of measurements. If you
    %   specify it as a scalar it will be extended to an N-by-N diagonal
    %   matrix.
    % 
    %   Default: 1
    MeasurementNoise;

    %MeasurementModel Model relating state to measurements (H)
    %   Specify the transition from state to measurement as an N-by-M
    %   matrix, where N is the number of measurements and M is the number
    %   of states.
    %
    %   Default: [1 0 0 0; 0 0 1 0]
    MeasurementModel;
  end
  
  properties (Abstract, Dependent = true)
      %ProcessNoise Process noise covariance (Q)
      %   Specify the covariance of process noise as a scalar or an M-by-M
      %   matrix, where M is the number of states. If you specify it as a
      %   scalar it will be extended to an M-by-M diagonal matrix.
      %
      %   Default: 1
      ProcessNoise;
  end

  % Settable by public class inheriting from this class in the constructor.
  properties (Access = protected)
      ProcessNoiseModel % G matrix
      MeasurementNoiseModel % J matrix
  end

  %------------------------------------------------------------------------
  % Hidden properties used by the object
  %------------------------------------------------------------------------
  properties(Access=protected)
      pM;   % Length of state
      pN;   % Length of measurement
      pL;   % Length of control input
      pW;   % Length of process noise
      pV;   % Length of measurement noise
      pHasControlInput;
      pState;
      pStateCovariance;
      pProcessNoise;
      pMeasurementModel;
      pMaxMeasurementModelSize;
      pMeasurementNoise;
      pMaxMeasurementNoiseSize;
      pHasPrediction;
      pMeasurement;
      pControlInput;
      pIsStateColumnVector;
      pHasProcessNoiseModel;
      pHasMeasurementNoiseModel;
  end
  
  %------------------------------------------------------------------------
  % Constant properties which store the default values
  %------------------------------------------------------------------------
  properties(Hidden, Access=private, Constant=true)
      constStateTransitionModel = [1 1 0 0; 0 1 0 0; 0 0 1 1; 0 0 0 1];
      constMeasurementModel     = [1 0 0 0; 0 0 1 0];
      constControlModel         = [];
      constState                = 0;
      constStateCovariance      = 1;
      constProcessNoise         = 1;
      constMeasurementNoise     = 1;
  end
  
  methods

    %----------------------------------------------------------------------
    % Constructor
    %----------------------------------------------------------------------
    function obj = KalmanFilter(varargin)
        inputs = parseInputs(obj, varargin{:});

        % Set properties using inputs
        setProperties(obj, inputs);
    end
    
    %----------------------------------------------------------------------
    % Predict method
    %----------------------------------------------------------------------
    function [x_pred, P_pred] = predict(obj, varargin)
        %PREDICT Predicts the state and state error covariance
        
        % The following are available syntaxes for using the predict
        % method in your public class. 
        %  
        % 1. ProcessNoiseModel is "empty" and ControlModel is "empty"
        % [x_pred, P_pred] = predict(obj);
        % [x_pred, P_pred] = predict(obj, A);
        % [x_pred, P_pred] = predict(obj, A, Q);  
        % 
        % 2. ProcessNoiseModel is "empty", ControlModel is specified
        % [x_pred, P_pred] = predict(obj, u);
        % [x_pred, P_pred] = predict(obj, u, A, B);
        % [x_pred, P_pred] = predict(obj, u, A, B, Q); 
        % 
        % 3. ProcessNoiseModel is specified, ControlModel is "empty"
        % [x_pred, P_pred] = predict(obj)
        % [x_pred, P_pred] = predict(obj, A);
        % [x_pred, P_pred] = predict(obj, A, G);
        %
        % 4. ProcessNoiseModel is specified, ControlModel is specified
        % [x_pred, P_pred] = predict(obj, u);
        % [x_pred, P_pred] = predict(obj, u, A, B);
        % [x_pred, P_pred] = predict(obj, u, A, B, G);
        % 
        % A - StateTransitionModel
        % B - ControlModel
        % Q - ProcessNoise
        % G - ProcessNoiseModel

        % Make sure that the method was called with a single object
        cond = (numel(obj) > 1);
        coder.internal.errorIf(cond, ...
            'shared_tracking:dims:NonScalarFilter', ...
            'Kalman filter', 'predict');

        coder.internal.errorIf(nargin>5, ...
            'shared_tracking:KalmanFilter:invalidNumInputsToPredict');
 
        parseInputsToPredict(obj, varargin{:});

        x = obj.pState;
        P = obj.pStateCovariance;
        
        % Prediction equations
        x = obj.StateTransitionModel*x;
  
        % Use control input on state if provided
        if obj.pHasControlInput
            u = cast(varargin{1},'like',x); % Already validated earlier
            x = x + obj.ControlModel * u(:);
        end

        if obj.pHasProcessNoiseModel
            P = obj.StateTransitionModel*P*obj.StateTransitionModel' +...
                obj.ProcessNoiseModel*obj.pProcessNoise*obj.ProcessNoiseModel';
        else
            P = obj.StateTransitionModel*P*obj.StateTransitionModel' +...
                obj.pProcessNoise;
        end

        % Ensure symmetric
        P = (P + P')*0.5;

        % State is a column vector internally; but it is a row vector for
        % output.
        obj.pState = x;
        obj.pStateCovariance = P;
        obj.pHasPrediction = true;

        if nargout > 0 % Save time if outputs are not asked for.
            x_pred = obj.State; % This will return the right orientation
            P_pred = obj.pStateCovariance;
        end
    end
    
    %----------------------------------------------------------------------
    % Correct method
    %----------------------------------------------------------------------
    function [x_corr, P_corr] = correct(obj, z, MeasurementCovariance)
        %CORRECT Corrects the state and state error covariance
        %   [x_corr, P_corr] = correct(obj, z) returns the correction
        %   of state, x_corr, and state estimation error covariance, P_corr,
        %   based on the current measurement z, an N-element vector.
        %
        %   [x_corr, P_corr] = correct(obj, z, zcov) additionally, allows you
        %   to specify the measurement covariance, zcov. If zcov is
        %   specified, it will replace the internal MeasurementNoise
        %   property, otherwise, all the measurements will be assumed to have
        %   the object's MeasurementNoise property.
        %
        %   The internal state and covariance of Kalman filter are
        %   overwritten by the corrected values.

        % Make sure that the method was called with a single object
        cond = (numel(obj) > 1);
        coder.internal.errorIf(cond, ...
            'shared_tracking:dims:NonScalarFilter', ...
            'Kalman filter', 'correct');

        matlabshared.tracking.internal.validateInputSizeAndType('z', 'KalmanFilter', z, obj.pN);
        % Input z_input can be a row vector or a column vector. Internally,
        % it is always a column vector.

        if nargin == 3
            obj.MeasurementNoise = MeasurementCovariance; % checking is done in the set method
        end

        gain_numerator = obj.pStateCovariance * obj.MeasurementModel';
        if obj.pHasMeasurementNoiseModel
            J = obj.MeasurementNoiseModel;
            residualCovariance = obj.MeasurementModel * obj.pStateCovariance ...
                * obj.MeasurementModel' + J*obj.MeasurementNoise*J';
        else
            residualCovariance = obj.MeasurementModel * obj.pStateCovariance ...
                * obj.MeasurementModel' + obj.MeasurementNoise;
        end

        zIn = cast(z,class(obj.pState));
        gain = gain_numerator / residualCovariance;
        x = obj.pState + gain * (zIn(:) - obj.MeasurementModel * obj.pState);
        P_corr = obj.pStateCovariance...
            - gain * obj.MeasurementModel * obj.pStateCovariance;
        obj.pState(:) = x;
        P_corr = (P_corr+P_corr')*0.5; % Verify numerical symmetry
        obj.pStateCovariance = P_corr;
        obj.pHasPrediction = false;
        if nargout > 0
            x_corr = obj.State;
        end
    end
    
    %----------------------------------------------------------------------
    % Distance method
    %----------------------------------------------------------------------
    function d = distance(obj, z_matrix, ~)
      %DISTANCE Computes distances between measurements and Kalman filter
      %   d = distance(obj, z_matrix) computes a distance between one or
      %   more measurements supplied by the z_matrix and the measurement
      %   predicted by the Kalman filter object. This computation takes
      %   into account the covariance of the predicted state and the
      %   process noise. Each row of the input z_matrix must contain a
      %   measurement of length N, where N is the number of rows in the
      %   MeasurementModel property. The distance method returns a row
      %   vector where each element is a distance associated with the
      %   corresponding measurement input. 
      
      % The procedure for computing the distance is described in Page 93 of
      % "Multiple-Target Tracking with Radar Applications" by Samuel
      % Blackman.
      
      % Make sure that the method was called with a single object
      cond = (numel(obj) > 1);
      coder.internal.errorIf(cond, ...
          'shared_tracking:dims:NonScalarFilter', ...
          'Kalman filter', 'distance');

      % The third argument is ignored. It is there only for commonality
      % with the other tracking filters. Add a check that no one called the
      % function with 3 inputs
      if nargin > 2 
          coder.internal.error('MATLAB:TooManyInputs');
      end
      
      matlabshared.tracking.internal.validateMeasurementMatrix(z_matrix, 'KalmanFilter', obj.pN);
      
      residualCovariance = obj.MeasurementModel * obj.pStateCovariance ...
        * obj.MeasurementModel' + obj.MeasurementNoise;
      z_e = obj.MeasurementModel * obj.pState;

      if isempty(z_matrix)
          d = zeros(1,0,'like',obj.StateTransitionModel);
      elseif iscolumn(z_matrix)
          d = zeros(1,1,'like',obj.StateTransitionModel);
          d(1) = matlabshared.tracking.internal.normalizedDistance(cast(z_matrix,'like',obj.StateTransitionModel), z_e, residualCovariance);
      else % z_matrix is numMeasurements-by-measurementSize
          len = size(z_matrix, 1);
          d = zeros(1, len,'like',obj.StateTransitionModel);
          z_in = cast(z_matrix,'like',obj.StateTransitionModel);
          for idx = 1:len
              d(idx) = matlabshared.tracking.internal.normalizedDistance(z_in(idx,:)', z_e, residualCovariance);
          end
      end
    end  
    
    %----------------------------------------------------------------------
    % Clone method
    %----------------------------------------------------------------------
    function newObj = clone(obj)
      %CLONE Creates a copy of the Kalman filter
      % newKF = clone(KF) returns newKF, a copy of the Kalman filter object
      % KF.
      
      % Make sure that the method was called with a single object
      coder.internal.assert(isscalar(obj), ...
          'shared_tracking:dims:NonScalarFilter', ...
          'Kalman filter', 'clone');
      
      objClass = str2func(coder.const(class(obj)));

      if isempty(obj.ControlModel)
        newObj = objClass(obj.StateTransitionModel, ...
          obj.pMeasurementModel);
      else
        newObj = objClass(obj.StateTransitionModel, ...
          obj.pMeasurementModel, obj.ControlModel);
      end
      newObj.pState            = obj.pState;
      newObj.pStateCovariance  = obj.pStateCovariance;
      newObj.pProcessNoise     = obj.pProcessNoise;
      newObj.pMeasurementNoise = obj.pMeasurementNoise;
    end

    function setMeasurementSizes(obj, measurementSize, measurementNoiseSize)
        %setMeasurementSizes Set measurement and measurement noise sizes
        % setMeasurementSizes(FILTER, N, V) sets the expected sizes of
        % measurement and measurement noise to N and V, respectively. Use
        % this function to set the expected sizes when working with
        % variable-sized measurements and before passing measurements
        % with new sizes to other object functions that use measurements
        % for example correct, distance, etc.
        validateattributes(measurementSize, {'numeric'}, {'real', ...
            'positive', 'integer', 'scalar'}, 'KalmanFilter');
        validateattributes(measurementNoiseSize, {'numeric'}, {'real', ...
            'positive', 'integer', 'scalar'}, 'KalmanFilter');
        coder.internal.assert(obj.pHasMeasurementNoiseModel || measurementSize==measurementNoiseSize,...
            'shared_tracking:KalmanFilter:IncompatibleMeasSizeAndNoiseSize');
        obj.pN(1) = measurementSize;
        obj.pV(1) = measurementNoiseSize(1);
    end
  end
  
  methods
    %----------------------------------------------------------------------
    function set.State(obj, value)
        matlabshared.tracking.internal.validateState(value, obj.pM);
        if isscalar(value)
            obj.pState = matlabshared.tracking.internal.expandScalarValue(value,[obj.pM 1]);
        else
            obj.pState = value(:);
        end
    end
    
    %----------------------------------------------------------------------
    function value = get.State(obj)
        if obj.pIsStateColumnVector
            value = obj.pState;
        else
            value = obj.pState';
        end
    end
    
    %----------------------------------------------------------------------
    function set.StateCovariance(obj, value)
        matlabshared.tracking.internal.checkCovariance('StateCovariance', ...
            value, [obj.pM, obj.pM]);

        if isscalar(value)
            obj.pStateCovariance = matlabshared.tracking.internal.expandScalarValue(value,[obj.pM obj.pM]);
        else
            obj.pStateCovariance = value;
        end
    end
    
    %----------------------------------------------------------------------
    function value = get.StateCovariance(obj)
        value = obj.pStateCovariance;
    end

    %----------------------------------------------------------------------
    function set.MeasurementNoise(obj, value)
        validateattributes(value,{'single','double'},{'2d','square'},'KalmanFilter');
        matlabshared.tracking.internal.checkCovariance('MeasurementNoise', ...
            value, [obj.pV, obj.pV]); 
        if isscalar(value)
            measurementNoiseScalarExpandIfNecessary(obj, value);
        else
            setMeasurementNoise(obj, value);
        end
    end
    
    %----------------------------------------------------------------------
    function value = get.MeasurementNoise(obj)
        if size(obj.pMeasurementNoise,1) > obj.pV
            value = obj.pMeasurementNoise(1:obj.pV,1:obj.pV);
        else
            value = obj.pMeasurementNoise;
        end
    end
    
    %----------------------------------------------------------------------
    function set.StateTransitionModel(obj, StateModelMatrix)
        validateStateTransitionModel(obj, StateModelMatrix);        
        obj.StateTransitionModel = StateModelMatrix(1:obj.pM,1:obj.pM);
    end
    
    %----------------------------------------------------------------------
    function set.MeasurementModel(obj, MeasurementModelMatrix)
        validateMeasurementModel(obj, MeasurementModelMatrix);
        if ~coder.target('MATLAB') && ~coder.internal.is_defined(obj.pMeasurementModel)
            % First setting defines the maximum size in codegen
            obj.pMeasurementModel = MeasurementModelMatrix;
        else
            % Codegen and next settings in codegen
            if ~coder.target('MATLAB')
                % If measurement model needs to be constant size, assert it
                n = obj.pN;
                assert(n <= obj.pMaxMeasurementModelSize);
                assert(size(MeasurementModelMatrix,1) <= n);
                obj.pMeasurementModel(1:n,:) = MeasurementModelMatrix;
            else
                % In MATLAB measurement model can change
                obj.pMeasurementModel = MeasurementModelMatrix;
            end
        end
    end

    %----------------------------------------------------------------------
    function value = get.MeasurementModel(obj)
        if size(obj.pMeasurementModel,1) > obj.pN
            value = obj.pMeasurementModel(1:obj.pN,1:obj.pM);
        else
            value = obj.pMeasurementModel(:,1:obj.pM);
        end
    end
    
    %----------------------------------------------------------------------
    function set.ControlModel(obj, ControlMatrix)
        validateControlModel(obj, ControlMatrix);
        obj.ControlModel = ControlMatrix;
    end

    function set.ProcessNoiseModel(obj, ProcessNoiseModel)
        if obj.pHasProcessNoiseModel
            % Size of G must be M-by-W
            validateattributes(ProcessNoiseModel,...
                {'single','double'},{'real','finite','nonsparse','size',[obj.pM obj.pW]},mfilename,'ProcessNoiseModel');
            obj.ProcessNoiseModel = ProcessNoiseModel;
        end
    end
    
    function set.MeasurementNoiseModel(obj, MeasurementNoiseModel)
        if obj.pHasMeasurementNoiseModel
            % Size of G must be N-by-V
            validateattributes(MeasurementNoiseModel,...
                {'single','double'},{'real','finite','nonsparse','size',[obj.pN obj.pV]},mfilename,'ProcessNoiseModel');
            obj.MeasurementNoiseModel = MeasurementNoiseModel;
        end
    end
  end
  
  methods(Access=protected)
      function inputs = parseInputs(obj, varargin)
          % Error if incorrect inputs are provided
          firstNVIndex = matlabshared.tracking.internal.findFirstNVPair(varargin{:});
          coder.internal.errorIf(firstNVIndex==2 || firstNVIndex>4, ...
              'shared_tracking:KalmanFilter:invalidInputsToConstructor');

          % Define optional arguments
          opArgs = struct;
          opArgs.StateTransitionModel = @(d)isnumeric(d);
          opArgs.MeasurementModel = @(d)isnumeric(d);
          opArgs.ControlModel = @(d)isnumeric(d);
          
          % Define N/V pairs
          NVPairNames = {'StateTransitionModel',...
              'MeasurementModel',...
              'ControlModel',...
              'State',...
              'StateCovariance',...
              'ProcessNoise',...
              'MeasurementNoise',...
              'ProcessNoiseModel',...
              'MeasurementNoiseModel'};

          % Define defaults
          defaults = struct;
          defaults.StateTransitionModel = obj.constStateTransitionModel;
          defaults.MeasurementModel = obj.constMeasurementModel;
          defaults.ControlModel = obj.constControlModel;
          defaults.State = obj.constState;
          defaults.StateCovariance = obj.constStateCovariance;
          defaults.ProcessNoise = obj.constProcessNoise;
          defaults.MeasurementNoise = obj.constMeasurementNoise;
          defaults.ProcessNoiseModel = [];
          defaults.MeasurementNoiseModel = [];
          
          poptions = struct('CaseSensitivity',false,...
              'PartialMatching','unique');

          % Parse
          pstruct = coder.internal.parseInputs(opArgs,NVPairNames,poptions,varargin{:});
          inputs = coder.internal.vararginToStruct(pstruct,defaults,varargin{:});
      end

      function setProcessNoise(obj, value)
          % A separate method to allow setting process noise because its
          % an abstract property.
          matlabshared.tracking.internal.checkCovariance('ProcessNoise', ...
              value, [obj.pW, obj.pW]);

          if isscalar(value)
              obj.pProcessNoise = matlabshared.tracking.internal.expandScalarValue(value,[obj.pW obj.pW]);
          else
              obj.pProcessNoise = value;
          end
      end

      function value = getProcessNoise(obj)
          value = obj.pProcessNoise;
      end

      function setProcessNoiseSize(obj, processNoiseModel, isModelProvided)
          if isModelProvided
              obj.pW = size(processNoiseModel,2);
          else
              obj.pW = obj.pM; % Same as state size
          end
      end
        
      function setMeasurementNoiseAndSize(obj, measNoiseModel, isModelProvided, classToUse)
          if isModelProvided
              obj.pMaxMeasurementNoiseSize = coder.internal.indexInt(size(measNoiseModel,2));
              obj.pV = cast(size(measNoiseModel,2),'like',obj.StateTransitionModel);
              obj.pMeasurementNoise = zeros(obj.pMaxMeasurementNoiseSize, obj.pMaxMeasurementNoiseSize, classToUse);
          else
              obj.pMaxMeasurementNoiseSize = obj.pMaxMeasurementModelSize;
              obj.pV = obj.pN; % Same as measurement size
              obj.pMeasurementNoise = zeros(obj.pMaxMeasurementNoiseSize, obj.pMaxMeasurementNoiseSize, classToUse);
          end
      end
      
      function setStateSizeAndOrientation(obj, stateTransModel, state)
          % make sure stateTransModel is square
          coder.internal.assert(size(stateTransModel,1) == size(stateTransModel,2),...
              'shared_tracking:KalmanFilter:nonSquareStateModel','StateTransitionModel');
          obj.pM = size(stateTransModel,1);
          if isscalar(state) || iscolumn(state)
              obj.pIsStateColumnVector = true;
          else
              obj.pIsStateColumnVector = false;
          end
      end

      function setMeasurementSize(obj, MeasurementModel)
          obj.pMaxMeasurementModelSize = size(MeasurementModel,1);
          obj.pN = coder.ignoreConst(cast(size(MeasurementModel,1),'like',obj.StateTransitionModel));
      end

      function validateStateTransitionModel(obj, StateModelMatrix)
          matlabshared.tracking.internal.validateDataAttributes...
              ('StateTransitionModel', StateModelMatrix);
          coder.internal.assert(all(size(StateModelMatrix) == [obj.pM obj.pM]),...
              'shared_tracking:KalmanFilter:nonMatchingStateModel', 'StateTransitionModel', obj.pM, obj.pM);
      end

      function validateMeasurementModel(obj, MeasurementModelMatrix)
          matlabshared.tracking.internal.validateDataAttributes...
              ('MeasurementModel', MeasurementModelMatrix);
          coder.internal.assert(all(size(MeasurementModelMatrix) == [obj.pN obj.pM]),...
              'shared_tracking:KalmanFilter:nonmatchingMeasurementState', 'MeasurementModel', obj.pN, obj.pM);
      end

      function validateControlModel(obj, ControlMatrix)
          matlabshared.tracking.internal.validateDataAttributes...
              ('ControlModel', ControlMatrix);
          coder.internal.assert(all(size(ControlMatrix) == [obj.pM obj.pL]),...
              'shared_tracking:KalmanFilter:nonmatchingControlState', 'ControlModel', obj.pM, obj.pL);
      end

      function setProperties(obj, inputs)
          % First set the immutable flags
          obj.pHasProcessNoiseModel = ~isempty(inputs.ProcessNoiseModel);
          obj.pHasMeasurementNoiseModel = ~isempty(inputs.MeasurementNoiseModel);
          
          % Validate data attributes of all inputs
          propsToChk = {'StateTransitionModel','MeasurementModel'...
              'MeasurementNoise','ProcessNoise','State'};
          for i = 1:numel(propsToChk)
              matlabshared.tracking.internal.validateDataAttributes(...
                  propsToChk{i},inputs.(propsToChk{i}));
          end

          % Set state and transition related properties
          % Use superior float for data type
          classToUse = superiorfloat(inputs.State,inputs.StateTransitionModel);

          % Set the size and orientation of the state
          setStateSizeAndOrientation(obj, inputs.StateTransitionModel, inputs.State);

          % Now set state size-related properties
          obj.StateTransitionModel = cast(inputs.StateTransitionModel, classToUse); 
          obj.State = cast(inputs.State, classToUse); 
          obj.StateCovariance = cast(inputs.StateCovariance,classToUse);

          % Set process noise and related properties
          setProcessNoiseSize(obj, inputs.ProcessNoiseModel, obj.pHasProcessNoiseModel);
          obj.ProcessNoiseModel = cast(inputs.ProcessNoiseModel, classToUse); 
          obj.ProcessNoise = cast(inputs.ProcessNoise, classToUse); 
          
          % Set measurement and measurement model properties
          % First set size of measurement and measurement noise
          coder.internal.assert(size(inputs.MeasurementModel,2) == size(inputs.StateTransitionModel,1),...
              'shared_tracking:KalmanFilter:nonmatchingMeasurementState', 'MeasurementModel', size(inputs.MeasurementModel,1), size(inputs.StateTransitionModel,1));
          setMeasurementSize(obj, inputs.MeasurementModel);
          setMeasurementNoiseAndSize(obj, inputs.MeasurementNoiseModel, obj.pHasMeasurementNoiseModel, classToUse);
          obj.MeasurementModel = cast(inputs.MeasurementModel, classToUse); 
          obj.MeasurementNoise = cast(inputs.MeasurementNoise, classToUse); 
          obj.MeasurementNoiseModel = cast(inputs.MeasurementNoiseModel, classToUse);

          % Set the control model
          isConstSizeControlModel = coder.internal.isConst(size(inputs.ControlModel)); % Constant size control model
          if isConstSizeControlModel && isempty(inputs.ControlModel) % Supplied as a "constant" empty
              obj.pHasControlInput = false;
              obj.pL = 0;
          else % Supplied as a varsized matrix, assume control input is available
              obj.pHasControlInput = true;
              matlabshared.tracking.internal.validateDataAttributes('ControlModel',inputs.ControlModel);
              obj.pL = size(inputs.ControlModel,2);
              obj.ControlModel = cast(inputs.ControlModel,classToUse);
          end

          % Set pHasPrediction
          obj.pHasPrediction = false;
      end
    %----------------------------------------------------------------------
    % Parse inputs for the predict method
    %----------------------------------------------------------------------
    function parseInputsToPredict(obj, varargin)
        if obj.pHasControlInput
            % When ControlModel is provided, predict can be called with the
            % following signatures:
            % predict(obj, u);
            % predict(obj, u, A, B);
            % predict(obj, u, A, B, Q);
            % predict(obj, u, A, B, G);

            % predict can have either 2, 4 or 5 inputs. Otherwise, assume
            % trying to use "non control model" signature and error
            coder.internal.assert(nargin == 2 || nargin == 4 || nargin == 5, ...
            'shared_tracking:KalmanFilter:needControlInput', 'ControlModel');
            
            % Validate second input as "control input"
            matlabshared.tracking.internal.validateInputSizeAndType...
                    ('u', 'KalmanFilter', varargin{1}, obj.pL);

            if nargin > 2
                narginchk(4,5);
                % Validation will be done by set methods
                obj.StateTransitionModel = varargin{2};
                obj.ControlModel = varargin{3}; 
                if nargin > 4
                    if obj.pHasProcessNoiseModel
                        obj.ProcessNoiseModel = varargin{4};
                    else
                        obj.ProcessNoise = varargin{4};
                    end
                end
            end
        else
           % When control model is not set, predict can be called with the
           % following signatures
           % predict(obj);
           % predict(obj, A);
           % predict(obj, A, Q);
           % predict(obj, A, G);
           
           % Error if > 3 inputs (assume trying to use control model signature)
           coder.internal.assert(nargin <= 3, ...
            'shared_tracking:KalmanFilter:needControlModel', 'ControlModel');
           
           % Set method will perform validations
           if nargin > 1
               obj.StateTransitionModel = varargin{1};
           end

           if nargin > 2
               if obj.pHasProcessNoiseModel
                   obj.ProcessNoiseModel = varargin{2};
               else
                   obj.ProcessNoise = varargin{2};
               end
           end
        end
    end

    function [A, G] = getPredictionMatrices(obj, varargin)
        A = obj.StateTransitionModel;
        if nargout > 1
            G = obj.ProcessNoiseModel;
        end
    end

    function measurementNoiseScalarExpandIfNecessary(obj, noiseScalar)
        % Ascertain MLCoder: pMeasurementNoise is defined in all code
        % paths.
        coder.assumeDefined(obj.pMeasurementNoise);

        % Scalar expand, if necessary.

        if noiseScalar > 0
            n = obj.pV;

            % if constant size pMeasurementNoise was provided, use it
            % as the bound for scalar expansion.
            if ~coder.target('MATLAB')
                assert(n <= obj.pMaxMeasurementNoiseSize);
            end

            setMeasurementNoise(obj, matlabshared.tracking.internal.expandScalarValue...
                (noiseScalar, [n n]));
        end
    end

    function setMeasurementNoise(obj,val)
        if coder.target('MATLAB')
            obj.pMeasurementNoise = val;
        else
            if coder.internal.is_defined(obj.pMeasurementNoise)
                n = obj.pV;
                assert(n <= obj.pMaxMeasurementNoiseSize); % enforced in setMeasurementSizes
                assert(size(val,1) <= n);
                obj.pMeasurementNoise(1:n,1:n) = val;
            else
                obj.pMeasurementNoise = val;
            end
        end
    end
  end

  methods (Access = protected)
      %--------------------------------------------------------------------
      % saveobj to make sure that the filter is saved correctly.
      %--------------------------------------------------------------------
      function sobj = saveobj(KF)
          sobj = struct('StateTransitionModel', KF.StateTransitionModel, ...
              'MeasurementModel',               KF.MeasurementModel, ...
              'ControlModel',                   KF.ControlModel, ...
              'State',                          KF.State, ...
              'StateCovariance',                KF.StateCovariance, ...
              'ProcessNoise',                   KF.ProcessNoise, ...
              'MeasurementNoise',               KF.MeasurementNoise, ...
              'pHasControlInput',               KF.pHasControlInput, ...
              'pState',                         KF.pState, ...
              'pStateCovariance',               KF.pStateCovariance, ...
              'pProcessNoise',                  KF.pProcessNoise, ...
              'pMeasurementNoise',              KF.pMeasurementNoise, ...
              'pMeasurementModel',              KF.pMeasurementModel, ...
              'pHasPrediction',                 KF.pHasPrediction, ...
              'pMeasurement',                   KF.pMeasurement,...
              'pControlInput',                  KF.pControlInput,...
              'ProcessNoiseModel',              KF.ProcessNoiseModel,...
              'MeasurementNoiseModel',          KF.MeasurementNoiseModel, ...
              'pN',                             KF.pN, ...
              'pV',                             KF.pV ...
              );
      end
  end
  methods (Access = protected, Static = true)
      %--------------------------------------------------------------------
      % loadobj to make sure that the filter is saved correctly.
      %--------------------------------------------------------------------
      function retKF = loadobjHelper(sobj, className)          
          STM   = sobj.StateTransitionModel;
          if isfield(sobj, 'pMeasurementModel')
              MM    = sobj.pMeasurementModel;
          else
              MM    = sobj.MeasurementModel;
          end
          CM    = sobj.ControlModel;
          ST    = sobj.State;
          STC   = sobj.StateCovariance;
          PN    = sobj.ProcessNoise;
          if isfield(sobj, 'pMeasurementNoise')
              MN = sobj.pMeasurementNoise;
          else
              MN = sobj.MeasurementNoise;
          end
          objClass = str2func(className);
          retKF = objClass(STM, MM, CM, 'State', ST, ...
              'StateCovariance', STC, 'ProcessNoise', PN, 'MeasurementNoise', MN);    
          retKF.pHasControlInput    = sobj.pHasControlInput;
          retKF.pState              = sobj.pState;
          retKF.pStateCovariance    = sobj.pStateCovariance;
          retKF.pProcessNoise       = sobj.pProcessNoise;
          retKF.pMeasurementNoise   = sobj.pMeasurementNoise;
          retKF.pHasPrediction      = sobj.pHasPrediction;
          
          if isfield(sobj, 'pN')
              retKF.pN = sobj.pN;
          end
          if isfield(sobj,'pV')
              retKF.pV = sobj.pV;
          end
      end
  end

  methods (Static, Hidden)
      function props = matlabCodegenNontunableProperties(~)
            props = {'pHasControlInput','pHasProcessNoiseModel', ...
                'pHasMeasurementNoiseModel','pIsStateColumnVector', ...
                'pMaxMeasurementModelSize','pMaxMeasurementNoiseSize'};
      end

      function props = matlabCodegenSoftNontunableProperties(~)
          % This allows us to support code generation when the KF is
          % constructed with varsize matrices, but during the execution,
          % the size is maintained. This provides backwards compatibility
          % for creating a "factory" for KF. After construction, the users
          % are expected to feed inputs respecting the size of the initial
          % matrices. 
          props = {'pM','pN','pW','pV','pL'};
      end
  end
end

%KalmanFilter Kalman filter for object tracking
%   This Kalman filter is designed for tracking. You can use it to predict
%   object's future location, to reduce noise in the detected location, or
%   to help associate multiple objects with their tracks. To use the Kalman
%   filter, the object must be moving based on a linear motion model, for
%   example, constant velocity or constant acceleration.
%
%   The Kalman filter algorithm implements a discrete time, linear
%   State-Space System described as follows.
% 
%      x(k) = A * x(k-1) + B * u(k-1) + w(k-1)    (state equation)
%      z(k) = H * x(k) + v(k)                     (measurement equation)
%
%   The Kalman filter algorithm involves two steps.
%      - Predict: Using the previous states to predict the current state.
%      - Correct, also known as update: Using the current measurement, 
%           such as the detected object location, to correct the state.
%
%   obj = matlabshared.tracking.internal.KalmanFilter returns a Kalman filter object for a discrete
%   time, constant velocity system. In this system, the state transition
%   model, A, is [1 1 0 0; 0 1 0 0; 0 0 1 1; 0 0 0 1] and the measurement
%   model, H, is [1 0 0 0; 0 0 1 0].
% 
%   obj = matlabshared.tracking.internal.KalmanFilter(StateTransitionModel, MeasurementModel)
%   lets you specify the state transition model, A, and the measurement
%   model, H. 
% 
%   obj = matlabshared.tracking.internal.KalmanFilter(StateTransitionModel, MeasurementModel,
%   ControlModel) additionally, lets you specify the control model, B.
% 
%   obj = matlabshared.tracking.internal.KalmanFilter(..., Name, Value) configures the Kalman
%   filter object properties, specified as one or more name-value pair
%   arguments. Unspecified properties have default values.
%
%   predict method syntax:
% 
%   [z_pred, x_pred, P_pred] = predict(obj) returns the prediction of
%   measurement, state, and state estimation error covariance at the next
%   time step (e.g., next video frame). The internal state and covariance
%   of Kalman filter are overwritten by the prediction results.
% 
%   [z_pred, x_pred, P_pred] = predict(obj, u) additionally, lets you
%   specify the control input, u, an L-element vector. This syntax applies
%   if you have set the control model B.
% 
%   [z_pred, x_pred, P_pred] = predict(obj, varargin) additionally, lets you
%   specify possibly time dependent values for the state transition model,
%   A, the control model, B, and the process noise, Q. 
%
%   correct method syntax:
% 
%   [z_corr, x_corr, P_corr] = correct(obj, z) returns the correction of
%   measurement, state, and state estimation error covariance based on the
%   current measurement z, an N-element vector. The internal state and
%   covariance of Kalman filter are overwritten by the corrected values.
% 
%   [z_corr, x_corr, P_corr] = correct(obj, z, zcov) additionally, allows
%   you to set a specific measurement noise covariance for the update.
%
%   distance method syntax:
% 
%   d = distance(obj, z_matrix) computes a distance between one or more
%   measurements supplied by the z_matrix and the measurement predicted by
%   the Kalman filter object. This computation takes into account the
%   covariance of the predicted state and the process noise. Each row of
%   the input z_matrix must contain a measurement vector of length N. The
%   distance method returns a row vector where each element is a distance
%   associated with the corresponding measurement input. The distance
%   method can only be called after the predict method.
%
%   Notes:
%   ======
%   - If the measurement exists, e.g., the object has been detected, you
%     can call the predict method and the correct method together. If the
%     measurement is missing, you can call the predict method but not the
%     correct method. 
%
%       If the object is detected
%           predict(kalmanFilter);
%           trackedLocation = correct(kalmanFilter, objectLocation);
%        Else
%           trackedLocation = predict(kalmanFilter);
%        End
%
%   - You can use the distance method to compute distances that describe
%     how a set of measurements matches the Kalman filter. You can thus
%     find a measurement that best fits the filter. This strategy can be
%     used for matching object detections against object tracks in a
%     multi-object tracking problem.
%
%   - You can use configureKalmanFilter to create a Kalman filter for
%     object tracking.
%
%   KalmanFilter methods:
% 
%   predict  - Predicts the measurement, state, and state error covariance
%   correct  - Corrects the measurement, state, and state error covariance
%   distance - Computes distances between measurements and Kalman filter
%   clone    - Creates a tracker object with the same property values
% 
%   KalmanFilter properties:
% 
%   StateTransitionModel - Model of state transition between time steps (A)
%   MeasurementModel     - Model relating state to measurements (H)
%   ControlModel         - Model relating control input to state (B)
%   State                - State (x)
%   StateCovariance      - State estimation error covariance (P)
%   ProcessNoise         - Process noise covariance (Q)
%   MeasurementNoise     - Measurement noise covariance (R)
% 
% Examples: should be specific to the toolboxes

%   Copyright 2013-2018 The MathWorks, Inc.
% 
%   References:
% 
%   [1] Greg Welch and Gary Bishop, "An Introduction to the Kalman Filter," 
%       TR95-041, University of North Carolina at Chapel Hill.
%   [2] Samuel Blackman, "Multiple-Target Tracking with Radar
%       Applications," Artech House, 1986.
