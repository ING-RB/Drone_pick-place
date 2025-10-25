classdef LoopedMeasurementOverheadEstimator < matlab.unittest.measurement.internal.looping.OverheadEstimator
    % This class is undocumented and subject to change in a future release

    % Copyright 2024 The MathWorks, Inc.

    methods
        function estimate(estimator, meter)
            import matlab.unittest.TestRunner;
            import matlab.unittest.measurement.DefaultMeasurementResult;
            import matlab.unittest.measurement.MeasurementPlugin;
            import matlab.unittest.measurement.internal.ExperimentOperator;
            import matlab.unittest.measurement.internal.DefaultCalibrator;
            import matlab.unittest.measurement.internal.looping.NullLoopedMeasurementOverheadEstimator;
            import matlab.unittest.measurement.internal.looping.NullKeepMeasuringOverheadEstimator;
            
            loopedMeasurementCalibrationSuite = getLoopedMeasurementCalibrationSuite;
            operator = ExperimentOperator(meter, DefaultCalibrator,NullKeepMeasuringOverheadEstimator, NullLoopedMeasurementOverheadEstimator);
            operator.Result = DefaultMeasurementResult(loopedMeasurementCalibrationSuite.Name, 'LoopedMeasurementOverhead');
            
            % Run the suite 30 times (dynamic number of estimations, 5 warmup, the rest are samples)
            runner = TestRunner.withNoPlugins;
            runner.addPlugin(MeasurementPlugin(operator));
            runner.runRepeatedly(loopedMeasurementCalibrationSuite, 30);
            
            result = operator.Result;
            sampleCount = height(result.Samples);

            if sampleCount >= 6
                estimator.Overhead = mean(result.Samples.LoopedMeasurementOverhead(6:end));
            else
                estimator.Overhead = mean(result.Samples.LoopedMeasurementOverhead(1:end));
            end
        end
    end
end

function suite = getLoopedMeasurementCalibrationSuite
import matlab.unittest.TestSuite;
suite = TestSuite.fromClass(?matlab.unittest.measurement.internal.looping.LoopedMeasurementCalibrationTest);
end

