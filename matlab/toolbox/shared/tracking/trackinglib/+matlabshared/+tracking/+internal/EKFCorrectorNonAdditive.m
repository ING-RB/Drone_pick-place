classdef EKFCorrectorNonAdditive < matlabshared.tracking.internal.EKFCorrector
    %

    %   Copyright 2016-2020 The MathWorks, Inc.

    %#codegen
    properties
        HasAdditiveNoise = false();
    end
    
    methods(Static)
        function hasError = validateMeasurementFcn(ekf,z,varargin)
            % Make sure # of measurement noise terms is known to EKF.
            % This is needed for being able to invoke user's fcn
            ekf.ensureMeasurementNoiseIsDefined();
            % Invoke user's fcn
            ztry = ekf.MeasurementFcn(...
                ekf.State, ...
                zeros(size(ekf.MeasurementNoise,1),1,'like',ekf.State), ...
                varargin{:});
            % Check if the measurement provided to the correct() matches
            % with the one returned from user's fcn
            hasError = numel(ztry) ~= numel(z) || ~isa(ztry, class(ekf.State));
        end
        
        function hasError = validateMeasurementJacobianFcn(ekf,z,varargin)
            % Make sure # of measurement noise terms is known to EKF.
            % This is needed for being able to invoke user's fcn
            ekf.ensureMeasurementNoiseIsDefined();
            % Invoke user's Jacobian fcn
            Htry = ekf.MeasurementJacobianFcn(...
                ekf.State, ...
                zeros(size(ekf.MeasurementNoise,1),1,'like',ekf.State), ...
                varargin{:});
            % Check if the Jacobian returned from user's fcn is consistent 
            % state and measurement dimensions.
            isSizeNotCorrect = numel(z) ~= size(Htry,1) || numel(ekf.State) ~= size(Htry,2);
            hasError = isSizeNotCorrect || ~isa(Htry, class(ekf.State));
        end
        
        function n = getNumberOfMandatoryInputs()
            % The measurement function h must have the syntax
            %      h(x,v,varargin)
            % x, v are mandatory
            n = 2;
        end

        function [zEstimated,Pxy,Pyy,dhdx,wrapping] = getPredictedMeasurementAndCovariances(zcov,x,P,h,dh,hasWrap,varargin)
            % getPredictedMeasurementAndCovariances  Calculate innovation and covariances of the extended Kalman filter
            % Inputs:
            %   zcov     - measurement noise covariance matrix
            %   x        - state estimate
            %   P        - state covariance matrix
            %   h        - function_handle to the measurement fcn
            %   dh       - function_handle to the measurement jacobian fcn.
            %              Empty if doesn't exist.
            %   hasWrap  - true if the measurement function is bounded.
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

            vZeros = zeros(size(zcov,1),1,'like',P);
            if isempty(dh)
                dhdx = matlabshared.tracking.internal.numericJacobianNonAdditive(h, x, vZeros, varargin, 1);
                dhdv = matlabshared.tracking.internal.numericJacobianNonAdditive(h, x, vZeros, varargin, 2);
            else
                [dhdx, dhdv] = dh(x, vZeros, varargin{:}); 
            end
            
            Pxy = P * dhdx.';
            Pyy = dhdx * Pxy + dhdv * zcov * dhdv.';
            if hasWrap
                [zEstimated,wrapping] = h(x, vZeros, varargin{:});
            else
                zEstimated = h(x, vZeros, varargin{:});
                nz = coder.internal.indexInt(numel(zEstimated));
                wrapping = matlabshared.tracking.internal.defaultWrapping(nz,class(zEstimated));
            end
        end 
        
        % Function to prepare Measurement Function Jacobian and Measurement
        % Covariance
        function [zEstimated,Pxy,Sy,dhdx,Rsqrt,wrapping] = getMeasurementJacobianAndCovariance(Rs,x,S,h,dh,hasWrap,varargin)
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
            % Notes:
            % 1. Since this is an internal function, no validation is done at this
            %    level. Any additional input validation should be done in a function or
            %    object that use this function.
            
            %#ok<*EMCLS>
            %#ok<*EMCA>
            %#ok<*MCSUP>
                        
            classToUse = class(S);
            
            vZeros = zeros(size(Rs,1),1, classToUse);
            [dhdx, Rsqrt] = matlabshared.tracking.internal.EKFCorrectorNonAdditive.measurementMatrices(...
                Rs, h, dh, x, varargin{:});
            
            % Get estimated measurement
            if hasWrap
                [zEstimated,wrapping] = h(x, vZeros, varargin{:});
            else
                zEstimated = h(x, vZeros, varargin{:});
                nz = coder.internal.indexInt(numel(zEstimated));
                wrapping = matlabshared.tracking.internal.defaultWrapping(nz,class(zEstimated));
            end
            
            % Get covariance Pxy 
            Pxy = (S*S.')* dhdx.';
            
            % Compute Sy
            Sy = matlabshared.tracking.internal.qrFactor(dhdx,S,Rsqrt);
        end
        
        function [dHdx, Rsqrt] = measurementMatrices(Rs, h, dh, x, varargin)
            %measurementMatrices  Calculate the measurement matrices dhdx and Rsqrt
            % Inputs:
            %   Rs       - square root of measurement noise covariance matrix
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
            
            vZeros = zeros(size(Rs,1),1,'like',x);
            if isempty(dh)
                dHdx = matlabshared.tracking.internal.numericJacobianNonAdditive(h, x, vZeros, varargin, 1);
                dhdv = matlabshared.tracking.internal.numericJacobianNonAdditive(h, x, vZeros, varargin, 2);
            else
                [dHdx, dhdv] = dh(x, vZeros, varargin{:}); 
            end   
            
            % Since noise is non-additive, use transformation
            Rsqrt =  dhdv * Rs;
        end
    end
end
