classdef EKFCorrectorAdditive < matlabshared.tracking.internal.EKFCorrector
    %
    
    %   Copyright 2016-2020 The MathWorks, Inc.

    %#codegen
    properties
        HasAdditiveNoise = true();
    end        
    
    methods(Static)
        function hasError = validateMeasurementFcn(ekf,z,varargin)
            % Invoke user's fcn
            ztry = ekf.MeasurementFcn(ekf.State, varargin{:});
            % Check if the measurement provided to the correct() matches
            % with the one returned from user's fcn            
            hasError = numel(ztry) ~= numel(z) || ~isa(ztry, class(ekf.State));
        end
        
        function hasError = validateMeasurementJacobianFcn(ekf,z,varargin)
            % Invoke user's Jacobian fcn
            Htry = ekf.MeasurementJacobianFcn(ekf.State, varargin{:});
            % Check if the Jacobian returned from user's fcn is consistent 
            % state and measurement dimensions.
            isSizeNotCorrect = numel(z) ~= size(Htry,1) || numel(ekf.State) ~= size(Htry,2);
            hasError = isSizeNotCorrect || ~isa(Htry, class(ekf.State));
        end
        
        function n = getNumberOfMandatoryInputs()
            % The measurement function h must have the syntax
            %      h(x,varargin)
            % x is mandatory
            n = 1;
        end
         
        function [zEstimated,Pxy,Pyy,dHdx,wrapping] = getPredictedMeasurementAndCovariances(zcov,x,P,h,dhdx,hasWrap,varargin)
            % getPredictedMeasurementAndCovariances  Calculate innovation and covariances of the extended Kalman filter
            % Inputs:
            %   zcov     - measurement noise covariance matrix
            %   x        - state estimate
            %   P        - state covariance matrix
            %   h        - function_handle to the measurement fcn
            %   dhdx     - function_handle to the measurement jacobian fcn.
            %              Empty if doesn't exist.
            %   hasWrap  - true if the measurement function is bounded
            %   varargin - (optional) additional params for the fcns h and dhdx
            %
            % Outputs:
            %   zEstimated        - estimated measurement from predicted
            %                       state
            %   Pxy               - P*dhdx'
            %   Pyy               - innovation covariance
            %   dHdx              - measurement jacobian evaluated at
            %                       predicted state
            %   wrapping          - measurement bounds
            %
            % Notes:
            % 1. Since this is an internal function, no validation is done at this
            %    level. Any additional input validation should be done in a function or
            %    object that use this function.
            % 2. The output from the function will have the same type as P.
            
            %#ok<*EMCLS>
            %#ok<*EMCA>
            %#ok<*MCSUP>
                   
            if isempty(dhdx)
                dHdx = matlabshared.tracking.internal.numericJacobianAdditive(h, x, varargin, 1);
            else
                dHdx = dhdx(x, varargin{:});
            end
            
            Pxy = P * dHdx.';
            Pyy = dHdx * Pxy  + zcov;
            if hasWrap
                [zEstimated,wrapping] = h(x, varargin{:});
            else
                zEstimated = h(x, varargin{:});
                nz = coder.internal.indexInt(numel(zEstimated));
                wrapping = matlabshared.tracking.internal.defaultWrapping(nz,class(zEstimated));
            end
        end
        
        % Function to prepare Measurement Function Jacobian and Measurement
        % Covariance
        function [zEstimated,Pxy,Sy,dHdx,Rsqrt,wrapping] = getMeasurementJacobianAndCovariance(Rs,x,S,h,dhdx,hasWrap,varargin)
            % getMeasurementJacobianAndCovariance  Calculate innovation, jacobian and  measurement noise covariance
            %                                      of the extended Kalman filter
            % Inputs:
            %   Rs     - square root of measurement noise covariance matrix
            %   x        - state estimate
            %   S        - square root of state error covariance matrix
            %   h        - function_handle to the measurement fcn
            %   dhdx     - function_handle to the measurement jacobian fcn.
            %              Empty if doesn't exist.
            %   hasWrap  - true if the measurement function is bounded.
            %   varargin - (optional) additional params for the fcns h and dhdx
            %
            % Outputs:
            %   zEstimated        - estimated measurement from predicted
            %                       state
            %   Pxy               - P*dhdx'
            %   Sy                - square root of innovation covariance
            %   dHdx              - measurement jacobian evaluated at
            %                       predicted state
            %   Rsqrt             - square root of measurement noise covariance matrix
            %                       transformed with the appropriate
            %                       jacobian
            %   wrapping          - measurement bounds
            %
            % Notes:
            % 1. Since this is an internal function, no validation is done at this
            %    level. Any additional input validation should be done in a function or
            %    object that use this function.
            
            
            %#ok<*EMCLS>
            %#ok<*EMCA>
            %#ok<*MCSUP>
            
            [dHdx, Rsqrt] = matlabshared.tracking.internal.EKFCorrectorAdditive.measurementMatrices(...
                Rs, h, dhdx, x, varargin{:});
            
            % Get estimated measurement
            if hasWrap
                [zEstimated,wrapping] = h(x, varargin{:});
            else
                zEstimated = h(x, varargin{:});
                nz = coder.internal.indexInt(numel(zEstimated));
                wrapping = matlabshared.tracking.internal.defaultWrapping(nz,class(zEstimated));
            end
            
            % Get covariance Pxy 
            Pxy = (S*S.')* dHdx.';
            
            % Compute Sy
            Sy = matlabshared.tracking.internal.qrFactor(dHdx,S,Rsqrt);            
        end
        
        function [dHdx, Rsqrt] = measurementMatrices(Rs, h, dhdx, x, varargin)
            %measurementMatrices  Calculate the measurement matrices dhdx and Rsqrt
            % Inputs:
            %   Rs     - square root of measurement noise covariance matrix
            %   x        - state estimate
            %   h        - function_handle to the measurement fcn
            %   dhdx     - function_handle to the measurement jacobian fcn.
            %              Empty if doesn't exist.
            %   varargin - (optional) additional params for the fcns h and dhdx
            %
            % Outputs:
            %   dHdx              - measurement jacobian evaluated at
            %                       predicted state
            %   Rsqrt             - square root of measurement noise covariance matrix
            %                       transformed with the appropriate
            %                       jacobian
            % Notes:
            % 1. Since this is an internal function, no validation is done at this
            %    level. Any additional input validation should be done in a function or
            %    object that use this function.
            if isempty(dhdx)
                dHdx = matlabshared.tracking.internal.numericJacobianAdditive(h, x, varargin, 1);
            else
                dHdx = dhdx(x, varargin{:});
            end
            
            % Since noise is additive, no transformation required
            Rsqrt = Rs;
        end
    end
end