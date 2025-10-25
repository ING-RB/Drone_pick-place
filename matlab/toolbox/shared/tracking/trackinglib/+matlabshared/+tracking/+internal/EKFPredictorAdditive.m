classdef EKFPredictorAdditive < matlabshared.tracking.internal.EKFPredictor
    %

    %   Copyright 2016-2020 The MathWorks, Inc.

    %#codegen
    properties
        HasAdditiveNoise = true();
    end
    
    methods(Static)
        function hasError = validateStateTransitionFcn(h,x,~,varargin)
            xNew = h(x, varargin{:});
            hasError = (numel(x) ~= numel(xNew)) || ~isa(xNew, class(x));
        end
        
        function hasError = validateStateTransitionJacobianFcn(h,x,~,varargin)
            F = h(x, varargin{:});
            % F needs to be square
            isSizeNotCorrect = ~all(size(F) == numel(x));
            hasError = isSizeNotCorrect || ~isa(F, class(x));
        end
        
        function expectedNargin =  getExpectedNargin(n)
            % n is nargin of EKF's predict() method, which is called as:
            %      predict(obj,varargin)
            % The state transition function f must have the syntax
            %      f(x,varargin)
            % Hence the expected nargin of f is equal to n
            expectedNargin = n;
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
            %   x        - predicted state estimate
            %   S        - predicted square root of state error covariance
            %   Jacobian - state transition jacobian at the current state
            % Notes:
            % 1. Since this is an internal function, no validation is done at this
            %    level. Any additional input validation should be done in a function or
            %    object that use this function.
            % 2. The output from the function will have the same type as S.
            
            %#ok<*EMCLS>
            %#ok<*EMCA>
            %#ok<*MCSUP>
            
            if nargin < 5
                df = [];
            end
   
            % Depending on whether StateTransitionJacobianFcn is defined,
            % calculate the Jacobian using the varargin
            [dFdx,Qsqrt] = matlabshared.tracking.internal.EKFPredictorAdditive.predictionMatrices(Qs,x,f,df,varargin{:});
            
            x = f(x, varargin{:});
            S = matlabshared.tracking.internal.qrFactor(dFdx,S,Qsqrt); 
        end
        
        function [dFdx, Qsqrt] = predictionMatrices(Qs,x,f,df,varargin)
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
            %   Qs       - Square root of process noise covariance matrix
            
            if nargin < 3
                df = [];
            end
   
            % Depending on whether StateTransitionJacobianFcn is defined,
            % calculate the Jacobian using the varargin
            if isempty(df)
                dFdx = matlabshared.tracking.internal.numericJacobianAdditive(f, x, varargin); 
            else
                dFdx = df(x, varargin{:});
            end
            Qsqrt = Qs;
        end
    end
end
