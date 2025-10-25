classdef (Hidden) AbstractAlphaBetaFilter < matlabshared.tracking.internal.AbstractTrackingFilter ...
        & matlabshared.tracking.internal.AbstractJPDAFilter
%

% Leave the above row empty to suppress the message: "Help for X is
% inherited from superclass matlabshared.tracking.internal.AbstractAlphaBetaFilter"

%AlphaBetaFilter     Alpha-beta filter
%   H = matlabshared.tracking.internal.AbstractAlphaBetaFilter returns an
%   alpha-beta filter object, H. This object performs alpha-beta filter
%   based tracking on measurements.
%
%   H = matlabshared.tracking.internal.AbstractAlphaBetaFilter(Name,Value) creates
%   an alpha-beta filter object, H, with the specified property Name set to
%   the specified Value. You can specify additional name-value pair
%   arguments in any order as (Name1,Value1,...,NameN,ValueN).
%
%   Predict method syntax:
%
%   X_pred = predict(H,T) returns the predicted state, X_pred, in a column
%   vector using alpha-beta filter. T is scalar specifying the elapsed time
%   (in seconds) between the current prediction and last
%   prediction/correction.
%
%   [X_pred,P_pred] = predict(H,T) also returns the state estimate
%   covariance in a matrix, P_pred.
%
%   [X_pred,P_pred,Z_pred] = predict(H,T) also returns the predicted
%   measurement in a column vector, Z_pred.
%
%   Correct method syntax:
%
%   X_corr = correct(H,Z) returns the corrected state, X_corr, in a column
%   vector using alpha-beta filter based on the measurement vector, Z. Z is
%   also a column vector.
%
%   [X_corr,P_corr] = correct(H,Z) also returns the corrected state
%   covariance matrix, P_corr.
%
%   [X_corr,P_corr,Z_corr] = correct(H,Z) also returns the corrected
%   measurement in a column vector, Z_corr.
%
%   AlphaBetaFilter methods:
%
%   predict     - Perform state prediction using alpha-beta filter
%   correct     - Perform state correction using alpha-beta filter
%   correctjpda - Correct the filter using joint probabilistic detection assignment
%   distance    - Distances between measurements and filter prediction
%   likelihood  - Calculate the likelihood of a measurement
%   clone       - Create alpha-beta filter object with same property values
%
%   AlphaBetaFilter properties:
%
%   MotionModel      - Model of target motion
%   State            - Alpha-beta filter states
%   StateCovariance  - State estimation error covariance
%   ProcessNoise     - Process noise covariance 
%   MeasurementNoise - Measurement noise covariance 
%   Coefficients     - Alpha-beta filter coefficients

%   Copyright 2015-2018 The MathWorks, Inc.

%   Reference
%   [1] Blackman, Multiple-Target Tracking with Radar Applications, Artech
%   House, 1986
%   [2] Bar-Shalom et al., Estimation with Applications to Tracking and
%   Navigation, Theory, Algorithms, and Software. John Wiley & Sons, 2001


%#ok<*EMCLS>
%#ok<*EMCA>
%#codegen
   
    properties (Dependent)
        %MotionModel    Model of target motion
        %   Specify the target motion model as one of '1D Constant
        %   Velocity' | '2D Constant Velocity' | '3D Constant Velocity' |
        %   '1D Constant Acceleration' | '2D Constant Acceleration' | '3D
        %   Constant Acceleration'. When you set this property to '1D
        %   Constant Velocity', '2D Constant Velocity', or '3D Constant
        %   Velocity', the target motion is assumed to be constant velocity
        %   during each simulation step. When you set this property to '1D
        %   Constant Acceleration' | '2D Constant Acceleration' | '3D
        %   Constant Acceleration', the target motion is assumed to be
        %   constant acceleration during each simulation step.
        MotionModel 
    end
    
    properties (Dependent)
        %State      Alpha-beta filter states
        %   Specify the state as a scalar or an M-element column vector. If
        %   you specify it as a scalar it will be extended to an M-element
        %   column vector. M is determined by the motion model specified in
        %   the MotionModel property. The default value of this property is
        %   0.
        %
        %   The state vector is formed by concatenating states from each
        %   dimension. For example, if you set the MotionModel to '3D
        %   Constant Acceleration', the state vector is in the form of 
        %         [x; x'; x''; y; y'; y''; z; z'; z'']
        %   where ' and '' represents the first and second order
        %   derivatives, respectively.
        State
        %StateCovariance State estimation error covariance
        %   Specify the covariance of the state estimation error as a
        %   scalar or an M-by-M matrix, where M is the number of states. If
        %   you specify it as a scalar it will be extended to an M-by-M
        %   diagonal matrix. The default value of this property is 1.
        StateCovariance
        %ProcessNoise Process noise covariance 
        %   Specify the covariance of process noise as a scalar or an
        %   M-by-M matrix, where M is the number of states. If you specify
        %   it as a scalar it will be extended to an M-by-M diagonal
        %   matrix. The default value of this property is 1.
        ProcessNoise
        %MeasurementNoise Measurement noise covariance 
        %   Specify the covariance of measurement noise as a scalar or an
        %   N-by-N matrix, where N is the number of measurements. If you
        %   specify it as a scalar it will be extended to an N-by-N
        %   diagonal matrix. The default value of this property is 1.
        MeasurementNoise
        %Coefficients   Alpha-beta filter coefficients
        %   Specify the alpha-beta filter coefficient as a scalar or a row
        %   vector. If you set the MotionModel property to one of '1D
        %   Constant Velocity', '2D Constant Velocity' and '3D Constant
        %   Velocity', the Coefficients property is in the form of [alpha
        %   beta]. If you set the MotionModel property to one of '1D
        %   Constant Acceleration', '2D Constant Acceleration' and '3D
        %   Constant Acceleration', the Coefficient property is in the form
        %   of [alpha beta gamma]. If you set this property as a scalar,
        %   the value is used for alpha, and beta, and gamma. The default
        %   value of this property is 0.1.
        Coefficients
    end
    
    properties (Access = protected)
        pStateTransitionMatrix;
    end
    
    properties(Access = private)
        pMeasurementMatrix 
        pControlGain
        pStateLength
        pMeasurementLength
        pState
        pStateCovariance
        pProcessNoise
        pMeasurementNoise
        pResidue
        pResidueCovariance
        pZPredicted
        pCoefficients
        pTimeStep
        pModelIndex
        pMotionDimension
        pIsPropertyValidated = false
        pClassToUse
    end
    
    methods
        function obj = AbstractAlphaBetaFilter(varargin)
            % Parse the inputs.
            [MotionModel,State,StateCovariance,ProcessNoise,MeasurementNoise,Coefficients,ClassToUse] = ...
                parseInput(varargin{:});
            
            obj.pClassToUse = ClassToUse;
            obj.MotionModel = MotionModel;
            obj.State = State;
            obj.Coefficients = Coefficients;
            obj.StateCovariance = StateCovariance;
            obj.ProcessNoise = ProcessNoise;
            obj.MeasurementNoise = MeasurementNoise;
            obj.pTimeStep = ones(1,1,obj.pClassToUse);
        end
    end
    
    methods
        function set.MotionModel(obj,val)
            cval = validatestring(val,{'1D Constant Velocity','1D Constant Acceleration',...
                '2D Constant Velocity','2D Constant Acceleration',...
                '3D Constant Velocity','3D Constant Acceleration'},'',...
                'MotionModel');
            switch cval
                case '1D Constant Velocity'
                    obj.pModelIndex = 1;
                    obj.pMotionDimension = 1;
                    obj.pStateLength = 2;
                    obj.pMeasurementLength = 1;
                case '1D Constant Acceleration'
                    obj.pModelIndex = 2;
                    obj.pMotionDimension = 1;
                    obj.pStateLength = 3;
                    obj.pMeasurementLength = 1;
                case '2D Constant Velocity'
                    obj.pModelIndex = 1;
                    obj.pMotionDimension = 2;
                    obj.pStateLength = 4;
                    obj.pMeasurementLength = 2;
                case '2D Constant Acceleration'
                    obj.pModelIndex = 2;
                    obj.pMotionDimension = 2;
                    obj.pStateLength = 6;
                    obj.pMeasurementLength = 2;
                case '3D Constant Velocity'
                    obj.pModelIndex = 1;
                    obj.pMotionDimension = 3;
                    obj.pStateLength = 6;
                    obj.pMeasurementLength = 3;
                case '3D Constant Acceleration'
                    obj.pModelIndex = 2;
                    obj.pMotionDimension = 3;
                    obj.pStateLength = 9;
                    obj.pMeasurementLength = 3;
            end
            obj.pIsPropertyValidated = false;
        end
        
        function val = get.MotionModel(obj)
            if obj.pModelIndex == 1
                switch obj.pMotionDimension
                    case 1
                        val = '1D Constant Velocity';
                    case 2
                        val = '2D Constant Velocity';
                    case 3
                        val = '3D Constant Velocity';
                end
           else
                switch obj.pMotionDimension
                    case 1
                        val = '1D Constant Acceleration';
                    case 2
                        val = '2D Constant Acceleration';
                    case 3
                        val = '3D Constant Acceleration';
                end
            end
        end
        
        function set.State(obj,val)
            slen = obj.pStateLength;
            if isscalar(val)
                sval = val*ones(slen,1);
            else
                sval = val;
            end
            validateattributes(sval,{'double','single'},{'column',...
                'real','finite','nonempty','nonnan'},...
                '','State');
            obj.pState = cast(sval,obj.pClassToUse);
            obj.pIsPropertyValidated = false;
        end
        
        function val = get.State(obj)
            val = obj.pState;
        end
        
        function set.Coefficients(obj,val)
            clen = obj.pModelIndex+1;
            if isscalar(val)
                cval = val*ones(1,clen);
            else
                cval = val;
            end
            validateattributes(cval,{'single','double'},...
                {'row','nonnan','nonempty','real','finite','positive'},...
                '','Coefficients');
            obj.pCoefficients = cast(cval,obj.pClassToUse);
            obj.pIsPropertyValidated = false;
        end
        
        function val = get.Coefficients(obj)
            val = obj.pCoefficients;
        end
                
        function set.StateCovariance(obj,val)
            slen = obj.pStateLength;
            if isscalar(val)
                scval = val*eye(slen);
            else
                scval = val;
            end
            validateattributes(scval,{'single','double'},{'2d',...
                'real','finite','nonempty','nonnan'},'','StateCovariance');
            obj.pStateCovariance = cast(scval,obj.pClassToUse);
            obj.pIsPropertyValidated = false;
        end
        
        function val = get.StateCovariance(obj)
            val = obj.pStateCovariance;
        end
        
        function set.ProcessNoise(obj,val)
            pnd = obj.pMotionDimension;
            if isscalar(val)
                pnval = val*eye(pnd);
            else
                pnval = val;
            end
            validateattributes(pnval,{'single','double'},{'2d',...
                'real','finite','nonempty','nonnan'},'','ProcessNoise');
            obj.pProcessNoise = cast(pnval,obj.pClassToUse);
            obj.pIsPropertyValidated = false;
        end
        
        function val = get.ProcessNoise(obj)
            val = obj.pProcessNoise;
        end
        
        function set.MeasurementNoise(obj,val)
            mlen = obj.pMeasurementLength;
            if isscalar(val)
                mnval = val*eye(mlen);
            else
                mnval = val;
            end
            validateattributes(mnval,{'single','double'},{'2d',...
                'real','finite','nonempty','nonnan'},'','MeasurementNoise');
            obj.pMeasurementNoise = cast(mnval,obj.pClassToUse);
            obj.pIsPropertyValidated = false;
        end
        
        function val = get.MeasurementNoise(obj)
            val = obj.pMeasurementNoise;
        end
        
    end
    
    methods
        function d = distance(obj, z_matrix, ~)
            %distance Distances between measurements and filter prediction
            %   D = distance(H, ZMAT) computes a distance between one or
            %   more measurements supplied by the ZMAT and the measurement
            %   predicted by the Alpha-beta filter. This computation takes
            %   into account the covariance of the predicted state and the
            %   process noise. ZMAT is a matrix whose rows represent the
            %   range measurements. The number of columns, N,  in ZMAT must
            %   match the measurement dimensions of the motion model. D is
            %   a lenght-N row vector, whose elements are distances
            %   associated with the corresponding measurements in ZMAT.
            
            % The procedure for computing the distance is described in Page
            % 93 of "Multiple-Target Tracking with Radar Applications" by
            % Samuel Blackman.
            
            % Make sure that the method was called with a single object
            cond = (numel(obj) > 1);
            coder.internal.errorIf(cond, ...
                'shared_tracking:dims:NonScalarFilter', ...
                'Alpha-beta filter', 'distance');
            
            if iscolumn(z_matrix)
                zmat = z_matrix.';
            else
                zmat = z_matrix;
            end
            validateattributes(zmat,{'single','double'},{'2d','ncols',obj.pMeasurementLength},...
                'distance','ZMAT');
            
            if ~obj.pIsPropertyValidated 
                setup(obj);
            end
            
            [r,residueCovariance] = innovation(obj,cast(zmat.',obj.pClassToUse));
            mahalanobisDistance = sum(r.*(residueCovariance\r));
            d = mahalanobisDistance+log(det(residueCovariance));
            
        end
        
        function [x_pred,P_pred,z_pred] = predict(obj,T)
        %predict    Predicts the state and measurement
        %   x_pred = predict(H,T) returns the prediction of the state,
        %   x_pred, at the next time step. The internal state and
        %   covariance of Alpha-beta filter are overwritten by the
        %   prediction results. T specifies the time step (in seconds) as a
        %   positive scalar.
        % 
        %   [x_pred, P_pred] = predict(...) also returns the prediction of
        %   the state covariance, P_pred, at the next time step.
        %
        %   [..., z_pred] = predict(...) also returns the prediction of
        %   the measurement, z_pred, at the next time step.
        
            if ~obj.pIsPropertyValidated 
                setup(obj);
            else
                createKinematicModel(obj,obj.pTimeStep); % for codegen
            end
            
            if nargin==1
                T = 1;
            end
            validateattributes(T,{'single','double'},{'finite','nonnan','nonempty',...
                'positive'},'predict','T');
            if T ~= obj.pTimeStep
                Tcast = cast(T,obj.pClassToUse);
                createKinematicModel(obj,Tcast);
                obj.pTimeStep = Tcast;
            end
            
            A = obj.pStateTransitionMatrix;
            B = obj.pControlGain;
            x_pred = A*obj.pState;
            z_pred = obj.pMeasurementMatrix*x_pred;
            P_pred = A*obj.pStateCovariance*A'+B*obj.ProcessNoise*B';  %[2] eq 5.2.3-5
            obj.pState = x_pred;
            obj.pStateCovariance = P_pred;
            obj.pZPredicted = z_pred;
        end
        
        function [x_corr,P_corr,z_corr] = correct(obj,z,varargin)
        % correct    Corrects the state and measurement
        %   x_corr = correct(H,z) returns the correction of state, x_corr,
        %   based on the current measurement z. The internal state and
        %   covariance of Kalman filter are overwritten by the corrected
        %   values.
        %
        %   [x_corr, P_corr] = correct(...) also returns the correction of
        %   the state variance, P_corr.
        %
        %   [..., z_corr] = correct(...) also returns the correction of
        %   measurement, z_corr.
        
           % Method must be called with a single object
           coder.internal.errorIf(numel(obj) > 1, ...
               'shared_tracking:AlphaBetaFilter:NonScalarFilter', ...
               class(obj), 'correct');
           
            if ~obj.pIsPropertyValidated
                setup(obj);
            else
                createKinematicModel(obj,obj.pTimeStep); % for codegen
            end
            
            validateattributes(z,{'single','double'},{'column','nonempty','nonnan',...
                'finite','real','nrows',size(obj.pMeasurementMatrix,1)},...
                '','Z');

            [r,rcov] = residual(obj,cast(z,obj.pClassToUse));
            
            [x_corr , P_corr] = correctStateAndCovariance(obj,r,rcov);
            
            % Save corrected values
            obj.pState = x_corr;
            obj.pStateCovariance = P_corr;
            obj.pResidue = r;
            obj.pResidueCovariance = rcov;
            z_corr = obj.pMeasurementMatrix*x_corr;
                    
        end
        
        function [x_corr,P_corr,z_corr] = correctjpda(obj,z,beta,varargin)
        %CORRECTJPDA Correct the filter using joint probabilistic detection assignment
        %   Correct the state and state error covariance with a joint
        %   probabilistic data association set of coefficients.
        %
        %   [x_corr, P_corr] = CORRECTJPDA(obj, z, beta) returns the
        %   correction of state, x_corr, and state estimation error
        %   covariance, P_corr, based on the current set of measurements,
        %   z, and their joint probabilistic data association coefficients,
        %   beta.
        %
        %   Inputs:
        %           - filter    an Alpha-Beta filter
        %
        %           - z         measurements matrix of size m-M  where m
        %                       is the dimension of a measurement and M is
        %                       the number of measurements.
        %
        %           - jpda      M+1 vector of joint probabilities.
        %                       For i=1:M, jpda(i) is the joint
        %                       probability of measurement i to be
        %                       associated with the filter.
        %                       jpda(M+1) is the probability that no
        %                       measurement is associated with the
        %                       filter. correctjpda expects sum(jpda) to
        %                       be equal to 1.
        %  [..., z_corr] = CORRECTJPDA(...) also returns the correction of
        %  measurement, z_corr.
        
            % Method must be called with a single object
           coder.internal.errorIf(numel(obj) > 1, ...
               'shared_tracking:AlphaBetaFilter:NonScalarFilter', ...
               class(obj), 'correctjpda');
        
            % number of inputs should be 3 or 4 (incl. obj)
            narginchk(3,4)

            if ~obj.pIsPropertyValidated
                setup(obj);
            else
                createKinematicModel(obj,obj.pTimeStep); % for codegen
            end

            validateattributes(z,{'single','double'},{'nonempty','nonsparse', ...
                'finite','real','2d','nrows',size(obj.pMeasurementMatrix,1)},...
                'correctjpda','Z');

            % jpda should have length of numMeasurements + 1
            numMeasurements = size(z,2);
            validateattributes(beta,{'numeric'},{'real','finite','nonsparse',...
               'nonnegative','vector','numel',numMeasurements+1,'<=',1},...
               'correctjpda','jpda');

            % jpda coefficients must sum to 1
            coder.internal.errorIf(abs(sum(beta)-1)>sqrt(eps(obj.pClassToUse)),...
                'shared_tracking:AlphaBetaFilter:InvalidJPDAInput','jpda')

            [~,rcov] = residual(obj,cast(z(:,1),obj.pClassToUse));
            % Compute predicted measurement
            zEstimated = obj.pMeasurementMatrix * obj.pState;

            % Compute weighted innovation and innovation covariance-like
            % term
            jpda = beta(1:end-1);
            [y,yy] = matlabshared.tracking.internal.jpdaWeightInnovationAndCovariances(z,zEstimated,jpda);

            % Correct state and covariance with standard KF correction
            [x_corr, P_corr, W] = correctStateAndCovariance(obj, y, rcov);
            obj.pState = x_corr;

            % Add jpda terms on covariance
            beta_not = beta(end);
            Sjpda = beta_not*rcov + yy - (y*y');
            P_corr = P_corr + W*Sjpda*W';

            % Save corrected values

            obj.pStateCovariance = P_corr;
            obj.pResidue = y;                 % probabilistically weighted residue
            obj.pResidueCovariance = rcov;
            z_corr = obj.pMeasurementMatrix*x_corr;
        end
        
        function newobj = clone(obj)
        % clone Create System object with same property values
        %    C = clone(OBJ) creates another instance of the object, OBJ,
        %    with the same property values.
            objName = class(obj);
            fcnName = str2func(objName);
            if ~coder.target('MATLAB')
                newobj = clonecg(obj,fcnName);
                return
            end
            s = saveobj(obj);
            newobj = fcnName(...
                'MotionModel',      obj.MotionModel, ...
                'State',            obj.State, ...
                'StateCovariance',  obj.StateCovariance, ...
                'ProcessNoise',     obj.ProcessNoise, ...
                'MeasurementNoise', obj.MeasurementNoise, ...
                'Coefficients',     obj.Coefficients);
            loadPrivateProps(newobj,s);
        end
        
        function l = likelihood(obj, z, ~)
        % liklihood Calculate the likelihood of a measurement
        %   l = likelihood(H, Z) calculates the likelihood of
        %   measurement, Z, given the object, H.
            if ~obj.pIsPropertyValidated 
                setup(obj);
            else
                createKinematicModel(obj,obj.pTimeStep); % for codegen
            end
            [zres,S] = residual(obj, z);
            l = matlabshared.tracking.internal.KalmanLikelihood(zres, S);
        end
    end
    
    % Methods accessed by trackers and multi-model systems
    methods (Access = ...
            {?matlabshared.tracking.internal.AbstractTrackingFilter, ...
            ?matlabshared.tracking.internal.AbstractContainsFilters, ...
            ?matlab.unittest.TestCase})
        function sync(abf1,abf2)
        %sync   Synchronize Alpha-beta filters
        %   sync(H,H1) syncs the filter, H, with another Alpha-beta filter,
        %   H1, to make sure that their State, StateCovariance,
        %   ProcessNoise, and MeasurementNoise, are the same.
        
            abf1.State = abf2.State;
            abf1.StateCovariance = abf2.StateCovariance;
            abf1.ProcessNoise = abf2.ProcessNoise;
            abf1.MeasurementNoise = abf2.MeasurementNoise;
        end
        
        function nullify(obj)
        %nullify    Reset the filter
        %   nullify(H) sets the state and the state covariance of the
        %   Alpha-beta filter to zeros.
           obj.State           = zeros(numel(obj.State), 1, 'like', obj.State);
           obj.StateCovariance = eye(numel(obj.State), numel(obj.State), 'like', obj.State);
        end 
        
        function name = modelName(obj)
        %modelName  Return the filter model name
        %   name = modelName(H) returns the model name of the filter
            if (strcmp(obj.MotionModel,'1D Constant Velocity')||...
                    strcmp(obj.MotionModel,'2D Constant Velocity')||...
                    strcmp(obj.MotionModel,'3D Constant Velocity'))
                name = 'constvel';
            elseif (strcmp(obj.MotionModel,'1D Constant Acceleration')||...
                    strcmp(obj.MotionModel,'2D Constant Acceleration')||...
                    strcmp(obj.MotionModel,'3D Constant Acceleration'))
                name = 'constacc';
            end
        end
        
        function [stm,mm] = models(obj, dt)
            %MODELS  Return the state transition and measurement models
            %  [stm, mm] = MODELS returns the state transition and
            %  measurement models
            obj.pTimeStep = dt;
            if ~obj.pIsPropertyValidated 
                setup(obj);
            else
                createKinematicModel(obj,obj.pTimeStep); % for codegen
            end 
            stm = obj.pStateTransitionMatrix;
            mm  = obj.pMeasurementMatrix;
        end
    end
    
    methods (Access = protected)
        function newobj = clonecg(obj,fcnName)
            % Code generation support for clone
            if ~obj.pIsPropertyValidated
                setup(obj);
            else
                createKinematicModel(obj,obj.pTimeStep); % for codegen
            end
            newobj = fcnName(...
                'MotionModel',      obj.MotionModel, ...
                'State',            obj.State, ...
                'StateCovariance',  obj.StateCovariance, ...
                'ProcessNoise',     obj.ProcessNoise, ...
                'MeasurementNoise', obj.MeasurementNoise, ...
                'Coefficients',     obj.Coefficients);
            newobj.pStateTransitionMatrix = obj.pStateTransitionMatrix;
            newobj.pMeasurementMatrix = obj.pMeasurementMatrix;
            newobj.pState = obj.pState;
            newobj.pModelIndex = obj.pModelIndex;
            newobj.pMotionDimension = obj.pMotionDimension;
            newobj.pCoefficients = obj.pCoefficients;
            newobj.pTimeStep = obj.pTimeStep;
            newobj.pIsPropertyValidated = obj.pIsPropertyValidated;
            newobj.pControlGain = obj.pControlGain;
            newobj.pStateLength = obj.pStateLength;
            newobj.pMeasurementLength = obj.pMeasurementLength;
            newobj.pStateCovariance = obj.pStateCovariance;
            newobj.pProcessNoise = obj.pProcessNoise;
            newobj.pMeasurementNoise = obj.pMeasurementNoise;
        end

        function [r,rcov] = residual(obj,z,~)
        %RESIDUAL  Residual between measurements and filter prediction
        %   [D,S] = RESIDUAL(H,Z) computes a residual between a
        %   measurement supplied by Z and the measurement predicted by the
        %   Alpha-beta filter object. D is the difference between the
        %   measurement and the filter prediction. S is the covariance
        %   matrix of the difference. Z is a column vector containing the
        %   measurement.
        
            validateattributes(z,{'single','double'},{'nonnan','finite','nonempty',...
                'size',[obj.pMeasurementLength 1]},'residual','Z');
            [r,rcov] = innovation(obj,z);
        end
         
        function [x_corr, P_corr, W] = correctStateAndCovariance(obj,r,rcov)
            %correctStateAndCovariance correct state and state covariance
            % [x_corr, P_corr, W] = correctStateAndCovariance(obj,r,rcov)
            %
            % Notes:
            % 1. Since this is an internal function, no validation is done 
            %    at this level. Any additional input validation should be
            %    done in a function or object that use this function.
            % 2. The output from the function will have the same type as P.

            
            T = obj.pTimeStep;
            coeff = obj.pCoefficients;
            
            C = obj.pMeasurementMatrix;
            xp = obj.pState;
            Pp = obj.pStateCovariance;
            
            if obj.pModelIndex == 1
                deltax = bsxfun(@times,coeff(:).*[1;1/T],...
                    r.');
            else
                deltax = bsxfun(@times,...
                    coeff(:).*[1;1/T;1/T^2],r.');
            end
            x_corr = xp + deltax(:);
            W = Pp*C'/rcov;                       % [2] eq 6.5.2-8
            P_corr = (eye(size(W,1))-W*C)*Pp;     % [2] eq 6.5.2-11
        end
        
        function setup(obj)
            validateProperties(obj)
            createKinematicModel(obj,obj.pTimeStep);
            obj.pZPredicted = zeros(obj.pMotionDimension,1,obj.pClassToUse);
            obj.pIsPropertyValidated = true;
        end

        function [r,rcov] = innovation(obj,z)
        %innovation  Innovation between measurements and filter prediction
        %   [D,S] = innovation(H,Z) computes a innovation between a
        %   measurement supplied by Z and the measurement predicted by the
        %   Alpha-beta filter object. D is the difference between the
        %   measurement and the filter prediction. S is the covariance
        %   matrix of the difference. Z is a column vector containing the
        %   measurement.
        
        %   The outputs are:
        %	  d = z-Hx, where H is the MeasurementModel and x is the state
        %	  S = HPH'+R, where P is the state covariance and R is the
        %	      measurement noise
            C = obj.pMeasurementMatrix;
            xp = obj.pState;
            Pp = obj.pStateCovariance;
            % z_est = obj.pZPredicted;
            z_est = C*xp;
            r = z-z_est;                          % [1] figure 2-1
            rcov = C*Pp*C'+obj.MeasurementNoise;  % [2] eq 5.2.3-9
        end
        
        function s = saveobj(obj)
            % Save properties defined by propsToSaveLoad method.
            fn = obj.propsToSaveLoad();
            for i = 1:numel(fn)
                s.(fn{i}) = obj.(fn{i});
            end
        end
        
        function loadPrivateProps(obj,s)
            % Load private properties defined by the propsToSaveLoadMethod.
            % Ignore other fields of s.
            fn = obj.propsToSaveLoad;
            for m = 1:numel(fn)
                obj.(fn{m}) = s.(fn{m});
            end
        end

        function validateProperties(obj)
            NumStatePerDim = obj.pModelIndex+1; 
            % 2 for constant velocity and 3 for constant acceleration
            cond = (numel(obj.pCoefficients) ~= NumStatePerDim);
            if cond
                coder.internal.errorIf(cond,...
                    'shared_tracking:AlphaBetaFilter:invalidRowNumbers','Coefficients',NumStatePerDim);
            end
            
            %NumState = NumStatePerDim*obj.pMotionDimension;
            NumState = obj.pStateLength;
            cond = (size(obj.pState,1) ~= NumState);
            if cond
                coder.internal.errorIf(cond,...
                    'shared_tracking:AlphaBetaFilter:invalidRowNumbers','State',NumState);
            end
            
            cond = ~isequal(size(obj.pStateCovariance),[NumState NumState]);
            if cond
                coder.internal.errorIf(cond,...
                    'shared_tracking:AlphaBetaFilter:expectedMatrixSize','StateCovariance',NumState,NumState);
            end
            
            pnd = obj.pMotionDimension;
            cond = ~isequal(size(obj.pProcessNoise),[pnd pnd]);
            if cond
                coder.internal.errorIf(cond,...
                    'shared_tracking:AlphaBetaFilter:expectedMatrixSize','ProcessNoise',pnd,pnd);
            end
                       
            mlen = obj.pMeasurementLength;
            cond = ~isequal(size(obj.pMeasurementNoise),[mlen mlen]);
            if cond
                coder.internal.errorIf(cond,...
                    'shared_tracking:AlphaBetaFilter:expectedMatrixSize','MeasurementNoise',mlen,mlen);
            end
                       
        end
        
        function createKinematicModel(obj,t)
            coder.varsize('t',[1 1],[0 0]);
            [A,B,C] = matlabshared.tracking.internal.getKinematicModel(...
                obj.pModelIndex,obj.pMotionDimension,t);
            obj.pStateTransitionMatrix = cast(A, obj.pClassToUse);
            obj.pControlGain = cast(B, obj.pClassToUse);
            obj.pMeasurementMatrix = cast(C, obj.pClassToUse);

        end
            
            
    end
    
    methods (Static,Hidden)
        function props = matlabCodegenNontunableProperties(classname) %#ok<INUSD>
            % used for code generation
            props = {'pModelIndex','pMotionDimension','pClassToUse','pStateLength'};
        end
        function obj = loadobj(s)
            obj = matlabshared.tracking.internal.AbstractAlphaBetaFilter('1D Constant Velocity');
            loadPrivateProps(obj,s);
        end
    end
    
    methods (Static, Access = protected)
        function fn = propsToSaveLoad(~)
            fn = {'pStateTransitionMatrix';
                'pMeasurementMatrix';
                'pState';
                'pZPredicted';
                'pModelIndex';
                'pMotionDimension';
                'pCoefficients';
                'pTimeStep';
                'pIsPropertyValidated';
                'pControlGain';
                'pStateLength';
                'pMeasurementLength';
                'pStateCovariance';
                'pProcessNoise';
                'pMeasurementNoise';
                'pResidue';
                'pResidueCovariance'};
        end
    end
end

%--------------------------------------
function [MotionModel,State,StateCovariance,ProcessNoise,MeasurementNoise,Coefficients,ClassToUse] = ...
    parseInput(varargin)
defaultMotionModel = varargin{1};
defaultCoefficients = 0.1;
defaultState = 0;
defaultStateCovariance = 1;
defaultProcessNoise = 1;
defaultMeasurementNoise = 1;

if coder.target('MATLAB')
    p = inputParser;
    p.addParameter('MotionModel',defaultMotionModel);
    p.addParameter('State',defaultState);
    p.addParameter('StateCovariance',defaultStateCovariance);
    p.addParameter('ProcessNoise',defaultProcessNoise);
    p.addParameter('MeasurementNoise',defaultMeasurementNoise);
    p.addParameter('Coefficients',defaultCoefficients);
    p.parse(varargin{2:end});
    MotionModel = p.Results.MotionModel;
    State = p.Results.State;
    StateCovariance = p.Results.StateCovariance;
    ProcessNoise = p.Results.ProcessNoise;
    MeasurementNoise = p.Results.MeasurementNoise;
    Coefficients = p.Results.Coefficients;
    ClassToUse = class(State);
else
    parms = struct('MotionModel',uint32(0), ...
                'State',uint32(0), ...
                'StateCovariance',uint32(0), ...
                'ProcessNoise',uint32(0), ...
                'MeasurementNoise',uint32(0), ...
                'Coefficients',uint32(0));
    pstruct = eml_parse_parameter_inputs(parms,[],varargin{2:end});
    MotionModel = eml_get_parameter_value(pstruct.MotionModel,defaultMotionModel,varargin{2:end});
    State = eml_get_parameter_value(pstruct.State,defaultState,varargin{2:end});
    StateCovariance = eml_get_parameter_value(pstruct.StateCovariance,defaultStateCovariance,varargin{2:end});
    ProcessNoise = eml_get_parameter_value(pstruct.ProcessNoise,defaultProcessNoise,varargin{2:end});
    MeasurementNoise = eml_get_parameter_value(pstruct.MeasurementNoise,defaultMeasurementNoise,varargin{2:end});
    Coefficients = eml_get_parameter_value(pstruct.Coefficients,defaultCoefficients,varargin{2:end});
    ClassToUse = class(State);
end

end

