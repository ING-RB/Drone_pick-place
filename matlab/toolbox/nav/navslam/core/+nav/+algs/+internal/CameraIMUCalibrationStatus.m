classdef CameraIMUCalibrationStatus < uint8
    %
    
    %   Copyright 2023 The MathWorks, Inc.

    enumeration
        Success (0) 
        ReprojectionErrorAboveThreshold (1) 
        PredictionErrorAboveThreshold (2) 
        BiasValuesOutOfBounds (3) 
        CalibrationOptimizationNotConverged (4) 
        CalibrationOptimizationResultNotUsable (5) 
        MoreThanOneCheckFailed (6)
    end
end