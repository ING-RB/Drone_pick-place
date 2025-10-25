classdef GravityRotationEstimationStatus < int32
%   This class is for internal use only. It may be removed in the future.
%
%GRAVITYROTATIONESTIMATIONSTATUS enum class for returning the validation
%   status of estimateGravityRotationAndPoseScale and 
%   estimateGravityRotation functions.

%   Copyright 2024 The MathWorks, Inc.

%#codegen

    enumeration
        %SUCCESS No validation failures.
        SUCCESS (0)

        %FAILURE_BAD_SCALE Scale is below specified threshold.
        FAILURE_BAD_SCALE (1)

        %FAILURE_BAD_PREDICTION Prediction error is above 
        % specified threshold.
        FAILURE_BAD_PREDICTION (2)

        %FAILURE_BAD_BIAS Bias variation from the initial value is out of 
        %   expected bounds computed from bias covariance values provided.
        FAILURE_BAD_BIAS (3)

        %FAILURE_BAD_SCALE_PREDICTION Scale is below specified threshold 
        %   and prediction error is above specified threshold.
        FAILURE_BAD_SCALE_PREDICTION (4)

        %FAILURE_BAD_SCALE_BIAS Scale is below specified threshold and bias
        %   variation from initial value is out of expected bounds.
        FAILURE_BAD_SCALE_BIAS (5)
        
        %FAILURE_BAD_PREDICTION_BIAS Prediction error is above specified
        %   threshold and bias variation from initial value is out of
        %   expected bounds.
        FAILURE_BAD_PREDICTION_BIAS (6)

        %FAILURE_BAD_SCALE_PREDICTION_BIAS Scale is below specified
        %   threshold, prediction error is above specified threshold and
        %   bias variation from initial value is out of expected bounds.
        FAILURE_BAD_SCALE_PREDICTION_BIAS (7)

        %FAILURE_BAD_OPTIMIZATION Optimization ran into errors and
        %   estimates are not usable.
        FAILURE_BAD_OPTIMIZATION (8)

        %FAILURE_NO_CONVERGENCE Initialization optimization didn't 
        %   converge in specified number of iterations. Increase the max 
        %   number of iterations.
        FAILURE_NO_CONVERGENCE (9)
    end
end
