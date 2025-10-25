classdef UKFPredictorNonAdditive < matlabshared.tracking.internal.UKFPredictor
    %

    %   Copyright 2016-2019 The MathWorks, Inc.
    
    %#codegen
    properties
        HasAdditiveNoise = false();
    end
    
    methods(Static)
        function hasError = validateStateTransitionFcn(h,x,pW,varargin)
            xNew = h(x, zeros(pW,1,'like',x),varargin{:});
            hasError = (numel(x) ~= numel(xNew)) || ~isa(xNew, class(x));
        end
        
        function expectedNargin =  getExpectedNargin(n)
            % n is nargin of UKF's predict() method, which is called as:
            %      predict(obj,varargin)
            % The state transition function f must have the syntax
            %      f(x,w,varargin)
            % Hence the expected nargin of f is equal to n+1
            expectedNargin = n+1;
        end
        
        function [X1,S,CrossCov] = predict(Qs,X1,S,alpha,beta,kappa,f,varargin)
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
            %       X1       - the predicted state
            %       S        - the square-root of predicted state error covariance
            %       CrossCov - cross covariance between predicted and current state
            %   Notes:
            %       1. Since this is an internal function, no validation is done at
            %          this level. Any additional input validation should be done in a
            %          function or object that use this function.
            %       2. This function is for state models where noise model
            %          is not additive

            %#codegen
            %#ok<*EMCLS>
            %#ok<*EMCA>
            %#ok<*MCSUP>
            
            % Get dimensions
            Ns = numel(X1);
            Nw = size(Qs,1);
            wZeros = zeros(Nw, 1, 'like', X1);
            
            % Calculate unscented transformation parameters
            [c, Wmean, Wcov, OOM] = matlabshared.tracking.internal.calcUTParameters(alpha,beta,kappa,cast(Ns+Nw,'like',alpha));
            
            % Generate the sigma points
            [X1,X2state] = matlabshared.tracking.internal.calcSigmaPointsSqrt(S,X1,c);
            [~,X2noise] = matlabshared.tracking.internal.calcSigmaPointsSqrt(Qs, wZeros, c);
            
            % Predict the sigma points using the state transition function, f
            tempY = f(X1, wZeros, varargin{:});
            Y1 = tempY(:);
            
            Y2 = zeros(Ns, 2*(Ns+Nw), 'like', X1); %memory allocation
            % Call the state fcn with x=Xs, w=0 
            for kk = 1 : 2*Ns
                tempY = f(X2state(:,kk), wZeros, varargin{:});
                Y2(:,kk) = tempY(:);
            end
            % Call the measurement fcn with x=Xs, w=0
            for kk = 1 : 2*Nw
                idx = 2*Ns + kk;
                tempY = f(X1, X2noise(:,kk), varargin{:});
                Y2(:,idx) = tempY(:);
            end
            
            % Calculate the unscented transformation mean and covariance
            [X1, S,CrossCov] = matlabshared.tracking.internal.UTMeanCovSqrt...
                (Wmean, Wcov, OOM, Y1, Y2, X1, X2state);
        end
    end
end
