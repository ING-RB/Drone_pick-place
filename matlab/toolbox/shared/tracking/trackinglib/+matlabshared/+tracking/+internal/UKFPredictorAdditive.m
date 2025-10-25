classdef UKFPredictorAdditive < matlabshared.tracking.internal.UKFPredictor
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
        
        function expectedNargin =  getExpectedNargin(n)
            % n is nargin of UKF's predict() method, which is called as:
            %      predict(obj,varargin)
            % The state transition function f must have the syntax
            %      f(x,varargin)
            % Hence the expected nargin of f is equal to n
            expectedNargin = n;
        end
        
        function [X1,S, CrossCov] = predict(Qs,X1,S,alpha,beta,kappa,f,varargin)
            %UKFPredict A single function responsible for all the computations for the
            %predict stage in a UKF filter.
            %   Inputs:
            %       Qs       - square-root of process noise covariance
            %       X1       - state estimate
            %       S        - square-root of state error covariance
            %       alpha    - parameter to control sigma points' distribution
            %       beta     - parameter to control sigma points' distribution
            %       kappa    - parameter to control sigma points' distribution
            %       f        - function_handle for the state transition fcn
            %       varargin - (optional) additional params for the fcn f
            %
            %   Outputs:
            %       X1       - predicted state
            %       S        - the square-root of predicted state error covariance
            %       CrossCov - cross covariance between predicted and current state
            %   Notes:
            %       1. Since this is an internal function, no validation is done at
            %          this level. Any additional input validation should be done in a
            %          function or object that use this function.
            %       2. This function serves the regular UKF predict, i.e., when the
            %          process noise is additive. 

            %#codegen
            %#ok<*EMCLS>
            %#ok<*EMCA>
            %#ok<*MCSUP>
                        
            Ns = numel(X1); % # of states
            
            % Calculate unscented transformation parameters
            [c, Wmean, Wcov, OOM] = matlabshared.tracking.internal.calcUTParameters(alpha,beta,kappa,cast(Ns,'like',alpha));
            
            % Generate the sigma points
            [X1,X2state] = matlabshared.tracking.internal.calcSigmaPointsSqrt(S,X1,c);
                       
            % Predict the sigma points using the state transition function, f
            Y2 = zeros(Ns, 2*Ns, 'like', X1); 
            for kk = 1:2*Ns
                tempY = f(X2state(:,kk), varargin{:});
                Y2(:,kk) = tempY(:);
            end
            tempY = f(X1, varargin{:});
            Y1 = tempY(:);            
            
            % Calculate the unscented transformation mean and covariance
            [X1, S, CrossCov] = matlabshared.tracking.internal.UTMeanCovSqrt...
                (Wmean, Wcov, OOM, Y1, Y2, X1, X2state);
            
            % Calculate the state covariance by taking into account the
            % process noise
            S = matlabshared.tracking.internal.qrFactor(eye(size(S),'like',S),S,Qs);
        end
    end
end
