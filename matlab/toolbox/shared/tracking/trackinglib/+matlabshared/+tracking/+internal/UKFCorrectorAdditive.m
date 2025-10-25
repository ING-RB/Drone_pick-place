classdef UKFCorrectorAdditive < matlabshared.tracking.internal.UKFCorrector
    %

    %   Copyright 2016-2021 The MathWorks, Inc.
    
    %#codegen
    properties
        HasAdditiveNoise = true();
    end
    
    methods(Static)
        function hasError = validateMeasurementFcn(ukf,z,varargin)
            % Invoke user's fcn
            ztry = ukf.MeasurementFcn(ukf.State, varargin{:});
            % Check if the measurement provided to the correct() matches
            % with the one returned from user's fcn
            hasError = numel(ztry) ~= numel(z) || ~isa(ztry, class(ukf.State));
        end
        
        function n = getNumberOfMandatoryInputs()
            % The measurement function h must have the syntax
            %      h(x,varargin)
            % x is mandatory
            n = 1;
        end
        
        function [Ymean, Pxy, Pyy, wrapping]= getPredictedMeasurementAndCovariances(z,zcov,X1,P,alpha,beta,kappa,h,hasWrap,varargin)
            % getPredictedMeasurementAndCovariances  Calculate innovation and covariances of the unscented Kalman filter
            %   Inputs:
            %       obj      - an UKFCorrector object
            %       z        - the measurement
            %       zcov     - the measurement noise covariance
            %       X1       - the state estimate
            %       P        - the state covariance
            %       alpha    - parameter to control sigma points' distribution
            %       beta     - parameter to control sigma points' distribution
            %       kappa    - parameter to control sigma points' distribution
            %       h        - a function_handle for the measurement function
            %       hasWrap  - true if the measurement function is bounded 
            %       varargin - (optional) additional params for the fcn h
            %
            %   Outputs:
            %       Ymean       - expected measurement
            %       Pxy         - cross covariance x-y
            %       Pyy         - covariance y-y
            %       wrapping    - wrapping bounds for the measurement
            %
            %   Notes:
            %       1. Since this is an internal function, no validation is done at
            %          this level. Any additional input validation should be done in a
            %          function or object that use this function.
            %       2. This function serves the regular UKF correct, i.e., when the
            %          process noise is additive.
            
            %#ok<*EMCLS>
            %#ok<*EMCA>
            %#ok<*MCSUP>
            
            Ns = numel(X1); % # of states
            % internally measurement is always a column vector to handle
            % also matrices of measurements

            % correct needs to format its measurement to pass in a column
            Ny = size(z,1); % Matrix of measurements has fixed direction
            
            % Calculate unscented transformation parameters
            [c, Wmean, Wcov, OOM] = matlabshared.tracking.internal.calcUTParameters(alpha,beta,kappa,cast(Ns,'like',alpha));
            
            % Calculate sigma points
            [X1,X2] = matlabshared.tracking.internal.calcSigmaPoints(P, X1, c);
            
            % Measure the sigma points
            Y2 = zeros(Ny, 2*Ns, 'like', X1);
            for kk = 1:2*Ns
                tempY = h(X2(:,kk), varargin{:});
                Y2(:,kk) = tempY(:);
            end
            % Evaluate the first sigma point
            if hasWrap
                [tempY,wrapping] = h(X1, varargin{:});
            else
                tempY = h(X1, varargin{:});
                wrapping = matlabshared.tracking.internal.defaultWrapping(coder.internal.indexInt(Ny),class(tempY));
            end
            Y1 = tempY(:);

            % Calculate the unscented transformation mean and covariance
            [Ymean, Pyy, Pxy] = matlabshared.tracking.internal.UTMeanCov...
                (Wmean, Wcov, OOM, Y1, Y2, X1, X2);
            % Add the covariance of the additive measurement noise
            Pyy   = Pyy + zcov;
        end
         
        function [Ymean,Pxy,Sy,wrapping]= getPredictedMeasurementAndCovariancesSqrt(z,Rs,X1,S,alpha,beta,kappa,h,hasWrap,varargin)
            % getPredictedMeasurementAndCovariances  Calculate innovation and covariances of the unscented Kalman filter
            %   Inputs:
            %       obj      - an UKFCorrector object
            %       z        - the measurement
            %       Rs       - the square-root of measurement noise covariance
            %       X1       - the state estimate
            %       S        - the square-root of state error covariance
            %       alpha    - parameter to control sigma points' distribution
            %       beta     - parameter to control sigma points' distribution
            %       kappa    - parameter to control sigma points' distribution
            %       h        - a function_handle for the measurement function
            %       hasWrap  - true if the measurement function is bounded
            %       varargin - (optional) additional params for the fcn h
            %
            %   Outputs:
            %       Ymean       - expected measurement
            %       Pxy         - cross covariance x-y
            %       Sy          - square-root of covariance y-y
            %       wrapping    - wrapping bounds for the measurement
            %
            %   Notes:
            %       1. Since this is an internal function, no validation is done at
            %          this level. Any additional input validation should be done in a
            %          function or object that use this function.
            %       2. This function serves the regular UKF correct, i.e., when the
            %          process noise is additive.
            
            %#ok<*EMCLS>
            %#ok<*EMCA>
            %#ok<*MCSUP>
            
            Ns = numel(X1); % # of states
            % internally measurement is always a column vector to handle
            % also matrices of measurements

            % correct needs to format its measurement to pass in a column
            Ny = size(z,1); % Matrix of measurements has fixed direction
            
            % Calculate unscented transformation parameters
            [c, Wmean, Wcov, OOM] = matlabshared.tracking.internal.calcUTParameters(alpha,beta,kappa,cast(Ns,'like',alpha));
            
            % Calculate sigma points
            [X1,X2] = matlabshared.tracking.internal.calcSigmaPointsSqrt(S,X1,c);
            
            % Measure the sigma points
            Y2 = zeros(Ny, 2*Ns, 'like', X1);
            for kk = 1:2*Ns
                tempY = h(X2(:,kk), varargin{:});
                Y2(:,kk) = tempY(:);
            end
            % Evaluate the first sigma point
            if hasWrap
                [tempY,wrapping] = h(X1, varargin{:});
            else
                tempY = h(X1, varargin{:});
                wrapping = matlabshared.tracking.internal.defaultWrapping(coder.internal.indexInt(Ny),class(tempY));
            end
            Y1 = tempY(:);
            Y2 = matlabshared.tracking.internal.wrapResidual(Y2 - Y1,wrapping,'UnscentedKalmanFilter') + Y1;
            
            % Calculate the unscented transformation mean and covariance
            [Ymean, Sy, Pxy] = matlabshared.tracking.internal.UTMeanCovSqrt...
                (Wmean, Wcov, OOM, Y1, Y2, X1, X2);
            
            % Add the covariance of the additive measurement noise
            Sy = matlabshared.tracking.internal.qrFactor(eye(size(Sy),'like',Sy),Sy,Rs);
        end
    end
end
