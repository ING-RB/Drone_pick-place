classdef NullLoopedMeasurementOverheadEstimator < matlab.unittest.measurement.internal.looping.OverheadEstimator
    % This class is undocumented and subject to change in a future release

    % Copyright 2024 The MathWorks, Inc.

    methods
        function estimate(estimator, meter)
            estimator.Overhead = meter.DefaultLoopingOverhead;
        end
    end
end

