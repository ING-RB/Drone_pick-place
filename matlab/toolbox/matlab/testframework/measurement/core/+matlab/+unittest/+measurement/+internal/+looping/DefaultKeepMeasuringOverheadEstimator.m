classdef DefaultKeepMeasuringOverheadEstimator < matlab.unittest.measurement.internal.looping.OverheadEstimator
    % This class is undocumented and subject to change in a future release

    % Copyright 2018-2024 The MathWorks, Inc.
    
    methods
        function estimate(estimator, meter)
            import matlab.unittest.TestRunner;
            import matlab.unittest.measurement.DefaultMeasurementResult;
            import matlab.unittest.measurement.MeasurementPlugin;
            import matlab.unittest.measurement.internal.ExperimentOperator;
            import matlab.unittest.measurement.internal.NullCalibrator;
            import matlab.unittest.measurement.internal.looping.NullKeepMeasuringOverheadEstimator;
            
            keepMeasuringCalibrationSuite = getKeepMeasuringCalibrationSuite;
            operator = ExperimentOperator(meter, NullCalibrator, NullKeepMeasuringOverheadEstimator);
            operator.Result = DefaultMeasurementResult(keepMeasuringCalibrationSuite.Name, 'KeepMeasuringOverhead');
            
            % Run the suite 11 times (5 warmup, 6 samples)
            runner = TestRunner.withNoPlugins;
            runner.addPlugin(MeasurementPlugin(operator));
            runner.runRepeatedly(keepMeasuringCalibrationSuite, 11);
            
            result = operator.Result;
            estimator.Overhead = mean(result.Samples.KeepMeasuringOverhead(6:11));     
        end
    end
end

function suite = getKeepMeasuringCalibrationSuite
import matlab.unittest.TestSuite;
suite = TestSuite.fromClass(?matlab.unittest.measurement.internal.looping.KeepMeasuringCalibrationTest);
end