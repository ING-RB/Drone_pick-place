classdef EKFCorrector
    %
    
    %   Copyright 2016-2020 The MathWorks, Inc.
    
    %#codegen
    properties(Abstract)
        HasAdditiveNoise;
    end

    properties(Hidden)
        HasMeasurementWrapping
    end
    
    methods(Abstract,Static)
        hasError = validateMeasurementFcn(h,x,z,numV,varargin);
        hasError = validateMeasurementJacobianFcn(h,x,z,numV,varargin);
        n = getNumberOfMandatoryInputs();
        [dHdx, Rsqrt] = measurementMatrices(Rs, h, dhdx, x, varargin)
    end
    
    methods(Static)
        function [x,P,gain] = correctStateAndCovariance(x,P,y,Pxy,Pyy,dHdx)
            % [x,P,gain] = correctStateAndCovariance(x,P,y,Pxy,Pyy,dHdx)
            %
            % One step of (extended, linear) Kalman filter correction
            % given: state estimate x, state estimate covariance P,
            % innovation y, actual measurement x-y cross covariance Pxy,
            % residual covariance Pyy, and linearization of the measurement
            % function w.r.t. x dHdx
            
            gain = Pxy / Pyy;                    
            x = x + gain * y(:);          
            P = P - gain * dHdx * P;
        end
        
        function [x,S] = correctStateAndSqrtCovariance(x,S,residue,Pxy,Sy,H,Rsqrt)
    
            % Compute Kalman Gain
            % Sy is Lower Triangular
            % K = (Pxy/Sy')/Sy;   
            opt1.LT = true;
            opt2.UT = true;
            K = (linsolve(Sy.',linsolve(Sy,Pxy.',opt1),opt2)).';            

            % Update the State             
            x = x + K*residue(:);                        

            % Update the Covariance
            % A = (I - KH)
            A = -K*H;
            for i = 1:size(A,1)
                A(i,i) = 1 + A(i,i);
            end            
            Ks = K*Rsqrt;

            % Perform QR Factorization
            S = matlabshared.tracking.internal.qrFactor(A,S,Ks);           
        end
    end
    
    methods
       
        function [x,S] = correct(obj,z,Rs,x,S,h,dh,varargin)
            %CORRECT  Performs the correction of the extended Kalman filter
            % Inputs:
            %   obj      - an EKFCorrector object
            %   z        - measurement
            %   Rs       - square root of measurement noise covariance matrix
            %   x        - state estimate
            %   S        - square root of state error covariance matrix
            %   h        - function_handle to the measurement fcn
            %   dh       - function_handle to the measurement jacobian fcn.
            %              Empty if doesn't exist.
            %   varargin - (optional) additional params for the fcns h and dhdx
            %
            % Outputs:
            %   x        - corrected state estimate
            %   S        - corrected square root of state error covariance
            %
            % Notes:
            % 1. Since this is an internal function, no validation is done at this
            %    level. Any additional input validation should be done in a function or
            %    object that use this function.
            % 2. The output from the function will have the same type as S.            

            if nargin<7
                dh = [];
            end
            
            % Find residue
            if obj.HasMeasurementWrapping
                [zEstimated,Pxy,Sy,dHdx,Rsqrt,wrapping] = obj.getMeasurementJacobianAndCovariance(Rs,x,S,h,dh,obj.HasMeasurementWrapping,varargin{:});
                residue = matlabshared.tracking.internal.wrapResidual(z(:)-zEstimated(:), wrapping, 'ExtendedKalmanFilter');
            else
                [zEstimated,Pxy,Sy,dHdx,Rsqrt] = obj.getMeasurementJacobianAndCovariance(Rs,x,S,h,dh,obj.HasMeasurementWrapping,varargin{:});
                residue = z(:)-zEstimated(:);
            end
            
            % Perform the Correction
            [x,S] = obj.correctStateAndSqrtCovariance(x,S,residue,Pxy,Sy,dHdx,Rsqrt);
        end
        
        function [res, S] = residual(obj,z,Rs,x,S,h,dh,varargin)
            %RESIDUAL  Computes residual of the extended Kalman filter
            % Inputs:
            %   obj      - an EKFCorrector object
            %   z        - measurement
            %   Rs       - square root of measurement noise covariance matrix
            %   x        - state estimate
            %   S        - square root of state error covariance matrix
            %   h        - function_handle to the measurement fcn
            %   dh       - function_handle to the measurement jacobian fcn.
            %              Empty if doesn't exist.
            %   varargin - (optional) additional params for the fcns h and dhdx
            %
            % Outputs:
            % res        - residual or innovation
            %   S        - covariance of residual
            %
            % Notes:
            % 1. Since this is an internal function, no validation is done at this
            %    level. Any additional input validation should be done in a function or
            %    object that use this function.
            % 2. The output from the function will have the same type as S.
            
            if obj.HasMeasurementWrapping
                [zEstimated,~,Sy,~,~,wrapping] = obj.getMeasurementJacobianAndCovariance(Rs,x,S,h,dh,obj.HasMeasurementWrapping,varargin{:});
                res = matlabshared.tracking.internal.wrapResidual(z(:)-zEstimated(:), wrapping, 'ExtendedKalmanFilter');
            else
                [zEstimated,~,Sy] = obj.getMeasurementJacobianAndCovariance(Rs,x,S,h,dh,obj.HasMeasurementWrapping,varargin{:});
                res = z(:)-zEstimated(:);
            end

            % Get the innovation covariance
            S = Sy*Sy.';
        end
        
        function [x,P] = correctjpda(obj,z,beta,zcov,x,P,h,dh,varargin)
            %CORRECTJPDA  Performs the correction of the extended JPDA Kalman filter
            % Inputs:
            %   z        - measurement
            %   beta     - jpda coefficients
            %   zcov     - measurement noise covariance matrix
            %   x        - state estimate
            %   P        - state covariance matrix
            %   h        - function_handle to the measurement fcn
            %   dhdx     - function_handle to the measurement jacobian fcn.
            %              Empty if doesn't exist.
            %   varargin - (optional) additional params for the fcns h and dhdx
            %
            % Outputs:
            %   x        - corrected state estimate with jpda
            %   P        - corrected state covariance with jpda
            %
            % Notes:
            % 1. Since this is an internal function, no validation is done at this
            %    level. Any additional input validation should be done in a function or
            %    object that use this function.
            % 2. The output from the function will have the same type as P.
            
            %#ok<*EMCLS>
            %#ok<*EMCA>
            %#ok<*MCSUP>
            
            if nargin < 8
                dh=[];
            end
            
            [zEstimated,Pxy,Pyy,dHdx,wrapping] = obj.getPredictedMeasurementAndCovariances(zcov,x,P,h,dh,obj.HasMeasurementWrapping,varargin{:});
            
            % Perform probabilistic average of innovation and covariance
            betas = beta(1:end-1);
            beta_not = beta(end);
            [y,yy] = matlabshared.tracking.internal.jpdaWeightInnovationAndCovariances(z,zEstimated,betas,wrapping);
            
            % First do the standard Kalman correction using the weighted
            % innovation y
            [x,P,gain] = obj.correctStateAndCovariance(x,P,y,Pxy,Pyy,dHdx);
            
            % Perform JPDA covariance correction
            % P = P - gain*Pyy*gain' was previously performed
            Sjpda = beta_not*Pyy + yy - (y*y');
            P = P + gain*Sjpda*gain';
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
