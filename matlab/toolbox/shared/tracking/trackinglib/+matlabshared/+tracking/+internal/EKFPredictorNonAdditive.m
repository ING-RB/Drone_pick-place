classdef EKFPredictorNonAdditive  < matlabshared.tracking.internal.EKFPredictor
    %

    %   Copyright 2016-2020 The MathWorks, Inc.

    %#codegen
    properties
        HasAdditiveNoise = false();
    end
    
    methods(Static)
        function hasError = validateStateTransitionFcn(h,x,pW,varargin)
            xNew = h(x, zeros(pW,1,'like',x),varargin{:});
            hasError = (numel(x) ~= numel(xNew)) || ~isa(xNew, class(x));
        end
        
        function hasError = validateStateTransitionJacobianFcn(h,x,pW,varargin)
            F = h(x, zeros(pW,1,'like',x),varargin{:});
            % F needs to be square
            isSizeNotCorrect = ~all(size(F) == numel(x));
            hasError = isSizeNotCorrect || ~isa(F, class(x));
        end
        
        function expectedNargin =  getExpectedNargin(n)
            % n is nargin of EKF's predict() method, which is called as:
            %      predict(obj,varargin)
            % The state transition function f must have the syntax
            %      f(x,w,varargin)
            % Hence the expected nargin of f is equal to n+1            
            expectedNargin = n+1;
        end
        
        function [x,S,dFdx] = predict(Qs,x,S,f,df,varargin)
            % EKF prediction for models with additive noise
            %
            % Inputs:
            %   Qs       - Square root of process noise covariance matrix
            %   x        - state estimate
            %   S        - Square root of state error covariance matrix
            %   f        - function_handle to the state transition fcn
            %   df       - function_handle to the state transition jacobian
            %              fcn. Empty if doesn't exist.
            %   varargin - (optional) additional params for the fcns f and dfdx
            %
            % Outputs:
            %   x    - predicted state estimate
            %   S    - predicted square root of state error covariance
            %   dFdx - State transition jacobian at the current state
            % Notes:
            % 1. Since this is an internal function, no validation is done at this
            %    level. Any additional input validation should be done in a function or
            %    object that use this function.
            % 2. The output from the function will have the same type as S.
            
            %#codegen
            %#ok<*EMCLS>
            %#ok<*EMCA>
            %#ok<*MCSUP>
            
            if nargin < 5
                df = [];
            end

            [dFdx,Qsqrt,wZeros] = matlabshared.tracking.internal.EKFPredictorNonAdditive.predictionMatrices(Qs,x,f,df,varargin{:});
            
            x = f(x, wZeros, varargin{:});
            S = matlabshared.tracking.internal.qrFactor(dFdx,S,Qsqrt);            
        end
        
        function [dFdx, Qsqrt, wZeros] = predictionMatrices(Qs,x,f,df,varargin)
            % Returns the state transition Jacobian matrix, dfdx, and Qsqrt
            %
            % Inputs:
            %   Qs       - Square root of process noise covariance matrix
            %   x        - state estimate
            %   f        - function_handle to the state transition fcn
            %   df       - function_handle to the state transition jacobian
            %              fcn. Empty if doesn't exist.
            %   varargin - (optional) additional params for the fcns f and dfdx
            %
            % Outputs:
            %   dFdx     - State transition jacobian at the current state
            %   Qsqrt    - Square root of process noise covariance matrix
            %              multiplied by dFdw, the Jacobian of f to noise
            %   wZeros   - A vector of zeros the same class and dim as Qs
            
            if nargin < 4
                df = [];
            end
   
            classToUse = class(Qs);
            wZeros = zeros(size(Qs,1),1, classToUse);
                       
            % Depending on whether StateTransitionJacobianFcn is defined,
            % calculate the Jacobian using varargin
            if isempty(df)
                % Use numerical perturbation to get Jacobians
                dFdx = matlabshared.tracking.internal.numericJacobianNonAdditive(f, x, wZeros, varargin, 1);
                dFdw = matlabshared.tracking.internal.numericJacobianNonAdditive(f, x, wZeros, varargin, 2); 
            else
                % User provided analytical jacobian fcn
                [dFdx, dFdw] = df(x, wZeros, varargin{:});
            end
            
            Qsqrt = dFdw*Qs;
        end
    end
end
