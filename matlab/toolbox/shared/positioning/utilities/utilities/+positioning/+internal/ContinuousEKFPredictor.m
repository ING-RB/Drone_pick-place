classdef (Hidden, HandleCompatible) ContinuousEKFPredictor
%   This class is for internal use only. It may be removed in the future. 
%CONTINUOUSEKFPREDICTOR Continuous Time EKF Prediction
%  For use with continuous-discrete EKFs

%   Copyright 2021 The MathWorks, Inc.    

%#codegen 


    methods(Static, Access = protected)
        function pDot = predictCovarianceDerivative(P, dfdx, procNoise)
            %PREDICTCOVARIANCEDERIVATIVE covariance derivative in
            % continuous time prediction for an extended Kalman filter
               pDot =  dfdx*P + P*(dfdx.') + procNoise;
               pDot = 0.5 * (pDot + pDot.'); % ensure symmetry
        end

        function e = eulerIntegrate(x, xdot, dt)
            % Basic Euler Integration
            e = x + dt.* xdot;
        end
    end

end
