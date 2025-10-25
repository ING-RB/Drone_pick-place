classdef UKFCorrector
    %

    %   Copyright 2016-2021 The MathWorks, Inc.
    
    %#codegen
    properties(Abstract)
        HasAdditiveNoise;
    end

    properties
        HasMeasurementWrapping
    end

    methods(Abstract,Static)
        hasError = validateMeasurementFcn(h,x,z,numV,varargin);
        n = getNumberOfMandatoryInputs();
    end
    
    methods(Static)
        function [x,P,gain] = correctStateAndCovariance(x,P,y,Pxy,Pyy)
            % [x,P,gain] = correctStateAndCovariance(x,P,y,Pxy,Pyy)
            %
            % One step of unscented Kalman filter correction given: 
            % state estimate x, state estimate covariance P, innovation y,
            % x-y cross covariance Pxy, residual covariance Pyy, 
            % and linearization of the measurement
            % function w.r.t. x dHdx
            
            gain = Pxy / Pyy;            
            x = x + gain * y(:);
            P = P - gain * Pyy * gain.';
        end
        
        function [x,S] = correctStateAndSqrtCovariance(x,S,residue,Pxy,Sy)
            % Compute Kalman Gain
            % Sy is Lower Triangular
            % K = (Pxy/Sy')/Sy;
            opt1.LT = true;
            opt2.UT = true;
            K = (linsolve(Sy.',linsolve(Sy,Pxy.',opt1),opt2)).';

            % Update the State
            x = x + K*residue(:);

            % Update S
            U = K*Sy;

            % Do a cholupdate for all columns of U
            S = matlabshared.tracking.internal.cholUpdateFactor(S,U,'-');
        end
    end
    
    methods 
        function [X1, S] = correct(obj,z,Rs,X1,S,alpha,beta,kappa,h,varargin)
            %CORRECT A single function responsible for all the computations for the
            %correct stage in a UKF filter.
            %   Inputs:
            %       obj      - an UKFCorrector object
            %       z        - the measurement
            %       Rs       - the square-root of measurement noise covariance
            %       x        - the state estimate
            %       S        - the square-root of state error covariance
            %       alpha    - parameter to control sigma points' distribution
            %       beta     - parameter to control sigma points' distribution
            %       kappa    - parameter to control sigma points' distribution
            %       h        - a function_handle for the measurement function
            %       varargin - (optional) additional params for the fcn h
            %
            %   Outputs:
            %       x       - the corrected state
            %       S       - the corrected state error covariance
            %
            %   Notes:
            %       1. Since this is an internal function, no validation is done at
            %          this level. Any additional input validation should be done in a
            %          function or object that use this function.
                        
            %#ok<*EMCLS>
            %#ok<*EMCA>
            %#ok<*MCSUP>
            
            % Internally the measurement must be a column vector
            zcol = z(:);
            
            if obj.HasMeasurementWrapping
                [Ymean, Pxy, Sy, wrapping]= ...
                    obj.getPredictedMeasurementAndCovariancesSqrt(zcol,Rs,X1,S,alpha,beta,kappa,h,obj.HasMeasurementWrapping,varargin{:});
                residual = matlabshared.tracking.internal.wrapResidual(zcol-Ymean(:),wrapping,'UnscentedKalmanFilter');
            else
                [Ymean, Pxy, Sy]= ...
                    obj.getPredictedMeasurementAndCovariancesSqrt(zcol,Rs,X1,S,alpha,beta,kappa,h,obj.HasMeasurementWrapping,varargin{:});
                residual = zcol-Ymean(:);
            end

            [X1,S] = matlabshared.tracking.internal.UKFCorrector.correctStateAndSqrtCovariance...
                (X1,S.',residual,Pxy,Sy);
        end 
        
        function [res, Py] = residual(obj,z,zcov,X1,S,alpha,beta,kappa,h,varargin)            
            %RESIDUAL A single function responsible for computing the
            %residual of the Unscented Kalman Filter at a particular time
            %step.
            %   Inputs:
            %       obj      - an UKFCorrector object
            %       z        - the measurement
            %       Rs       - the square-root of measurement noise covariance
            %       x        - the state estimate
            %       S        - the square-root of state error covariance
            %       alpha    - parameter to control sigma points' distribution
            %       beta     - parameter to control sigma points' distribution
            %       kappa    - parameter to control sigma points' distribution
            %       h        - a function_handle for the measurement function
            %       varargin - (optional) additional params for the fcn h
            %
            %   Outputs:
            %       x       - the corrected state
            %       Py      - the residual covariance
            %
            %   Notes:
            %       1. Since this is an internal function, no validation is done at
            %          this level. Any additional input validation should be done in a
            %          function or object that use this function.
                        
            %#ok<*EMCLS>
            %#ok<*EMCA>
            %#ok<*MCSUP>
                        
            % Internally the measurement must be a column vector
            zcol = z(:);
            if obj.HasMeasurementWrapping
                [Ymean, ~, Sy, wrapping]= ...
                    obj.getPredictedMeasurementAndCovariancesSqrt(zcol,zcov,X1,S,alpha,beta,kappa,h,obj.HasMeasurementWrapping,varargin{:});
                res = matlabshared.tracking.internal.wrapResidual(zcol-Ymean(:),wrapping,'UnscentedKalmanFilter');
            else
                [Ymean, ~, Sy]= ...
                    obj.getPredictedMeasurementAndCovariancesSqrt(zcol,zcov,X1,S,alpha,beta,kappa,h,obj.HasMeasurementWrapping,varargin{:});
                res = zcol-Ymean(:);
            end

            Py = Sy*Sy.';
        end       
        
        function [X1, P] = correctjpda(obj,z,jpda,zcov,X1,P,alpha,beta,kappa,h,varargin)
            %CORRECTJDPA A single function responsible for all the computations for the
            %correct stage in a JPDA UKF filter.
            %   Inputs:
            %       z        - measurements matrix
            %       jpda     - jpda coefficients
            %       zcov     - the measurement noise covariance
            %       x        - the state estimate
            %       P        - the state covariance
            %       alpha    - parameter to control sigma points' distribution
            %       beta     - parameter to control sigma points' distribution
            %       kappa    - parameter to control sigma points' distribution
            %       h        - a function_handle for the measurement function
            %       varargin - (optional) additional params for the fcn h
            %
            %   Outputs:
            %       x       - the corrected state
            %       P       - the corrected state covariance
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
            
 
            % Predict measurement and covariances
            [Ymean, Pxy, Pyy,wrapping]= ...
                obj.getPredictedMeasurementAndCovariances(z,zcov,X1,P,alpha,beta,kappa,h,obj.HasMeasurementWrapping,varargin{:});
            
            % Perform probabilistic average of innovation and covariance
            weight = jpda(1:end-1);
            [y,yy] = matlabshared.tracking.internal.jpdaWeightInnovationAndCovariances(z,Ymean,weight,wrapping);
            
            % Perform regular KF correction
            [X1,P,gain] = obj.correctStateAndCovariance(X1,P,y,Pxy,Pyy);
            
            weight_not = jpda(end);
            Pmeas = gain*(yy - (y*y') )*gain';
            P = P + weight_not*gain*Pyy*gain'+Pmeas;            

        end   
    end
    
    methods(Static,Hidden)
        function props = matlabCodegenNontunableProperties(~)
            % Let the coder know about non-tunable parameters so that it
            % can generate more efficient code.
            props = {'HasAdditiveNoise','HasMeasurementWrapping'};
        end        
    end      
end
