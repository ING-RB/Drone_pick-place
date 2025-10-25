classdef (Hidden) MeasurementPlugin < matlab.unittest.plugins.QualifyingPlugin
    % This class is undocumented and subject to change in a future release
    
    % MeasurementPlugin - A plugin for recording measurements.
    
    % Copyright 2015-2024 The MathWorks, Inc.

    properties (Hidden, Access = protected)
        RunTestSuitePluginData;
    end
    
    properties(Access = ?matlab.unittest.measurement.internal.Experiment)
        Operator;
    end
    
    properties(SetAccess=private, Hidden)
        MeasuresAtClassBoundary        
        MeasuresInFreshFixture
    end
    
    properties(Access=private)
        TestCaseInstance
        FreshFixtureListeners = event.listener.empty;
    end
    
    properties(Dependent, SetAccess=private)
        Result
        KeepMeasuringLoopedMeasurementConflict
    end

    properties(Access=private)
        DetectedLoopingConflictBefore = false;
    end
    
    properties (Hidden, Dependent, SetAccess=private)
        CurrentIndex
        RepeatIndex
        HasEstimatedKeepMeasuringOverhead
        HasEstimatedLoopedMeasurementOverhead
    end

    properties (Access = ?matlab.unittest.measurement.internal.Experiment)
        UsingLoopedMeasurement = false;
        UsingKeepMeasuring = false;
    end

    properties (Access = ?matlab.unittest.measurement.internal.Experiment)
        LoopCount = 1;
        Estimating = true;
        EstimationPhaseCount = 0;
    end

    properties (Access = ?matlab.unittest.measurement.internal.Experiment, Constant)
        MinTime = 0.2;
        MaxEstimationPhaseCount = 10;
    end
    
    methods (Hidden)
        function plugin = MeasurementPlugin(operator)
            if nargin > 0
                plugin.Operator = operator;
            end
        end
    end
    
    methods
        
        function val = get.Result(plugin)
            val = plugin.Operator.Result;
        end

        function tf = get.KeepMeasuringLoopedMeasurementConflict(plugin)
            tf = plugin.UsingKeepMeasuring && plugin.UsingLoopedMeasurement;
        end
        
        function val = get.CurrentIndex(plugin)
            val = plugin.RunTestSuitePluginData.CurrentIndex;
        end
        
        function val = get.RepeatIndex(plugin)
            val = plugin.RunTestSuitePluginData.RepeatIndex;
        end
        
        function tf = get.HasEstimatedKeepMeasuringOverhead(plugin)
            tf = ~isempty(plugin.Operator.KeepMeasuringOverheadEstimator.Overhead);
        end

        function tf = get.HasEstimatedLoopedMeasurementOverhead(plugin)
            tf = ~isempty(plugin.Operator.LoopedMeasurementOverheadEstimator.Overhead);
        end
    end
    
    methods (Access = protected)
        
        function runTestSuite(plugin, pluginData)
            import matlab.unittest.measurement.DefaultMeasurementResult;
            
            % Store the plugin data
            plugin.RunTestSuitePluginData = pluginData;
            
            resultNames = {plugin.Operator.Result.Name};
            suiteNames = {pluginData.TestSuite.Name};
            if ~isequal(resultNames, suiteNames)
                plugin.Operator.Result = DefaultMeasurementResult(suiteNames);                
            end
            
            plugin.Operator.calibrate(pluginData.TestSuite);
            meterCleanup = onCleanup(@()plugin.Operator.Meter.clear);
            
            runTestSuite@matlab.unittest.plugins.TestRunnerPlugin(plugin, pluginData);
        end
        
        function testCase = createTestClassInstance(plugin, pluginData)
            
            plugin.MeasuresAtClassBoundary = false;
            
            testCase = createTestClassInstance@matlab.unittest.plugins.TestRunnerPlugin(...
                plugin, pluginData);
            
            testCase.addlistener('MeasurementStarted', @plugin.usesClassMeasurement);
            testCase.addlistener('MeasurementStopped', @plugin.usesClassMeasurement);
            testCase.addlistener('MeasurementLogged',  @plugin.usesClassMeasurement);
        end

        function testCase = createTestRepeatLoopInstance(plugin, pluginData)
            plugin.reset();
            testCase = createTestRepeatLoopInstance@matlab.unittest.plugins.TestRunnerPlugin(...
                plugin, pluginData);
        end
        
        function testCase = createTestMethodInstance(plugin, pluginData)
            plugin.MeasuresInFreshFixture = false;
            
            testCase = createTestMethodInstance@matlab.unittest.plugins.TestRunnerPlugin(...
                plugin, pluginData);
            plugin.TestCaseInstance = testCase;
            
            plugin.FreshFixtureListeners(1) = ...
                testCase.addlistener('MeasurementStarted', @plugin.usesFreshFixtureMeasurement);
            plugin.FreshFixtureListeners(2) = ...
                testCase.addlistener('MeasurementStopped', @plugin.usesFreshFixtureMeasurement);
            plugin.FreshFixtureListeners(3) = ...
                testCase.addlistener('MeasurementLogged',  @plugin.usesFreshFixtureMeasurement);
            
            idx = plugin.CurrentIndex;
            iter = plugin.RepeatIndex;

            if (plugin.UsingLoopedMeasurement)
                plugin.TestCaseInstance.LoopCount_ = plugin.LoopCount;
            end

            plugin.Operator.Result(idx) = plugin.Operator.Result(idx).newTestRun(iter);

        end
        
        function runTestMethod(plugin, pluginData)
            import matlab.unittest.measurement.internal.Measurable;
            
            cl = plugin.disableFreshFixtureListeners;  %#ok<NASGU> onCleanup usage
            plugin.TestCaseInstance.subscribe(Measurable.MeasurementCommunicationChannel_, ...
                @(data)plugin.handleKeepMeasuringData(data));

            plugin.TestCaseInstance.subscribe(Measurable.MeasurementCommunicationChannel_LoopedMeasurement_, ...
                @(data)plugin.handleLoopedMeasurementData(data));
            
            meter = plugin.Operator.Meter;
            
            meter.connect(plugin.TestCaseInstance);
            runTestMethod@matlab.unittest.plugins.TestRunnerPlugin(plugin, pluginData);
            meter.disconnect();
        end
        
        function teardownTestMethod(plugin, pluginData)
            import matlab.unittest.measurement.internal.DidNotDetectFreshFixtureMeasurement;
            import matlab.unittest.measurement.internal.DidNotDetectKeepMeasuringAndLoopedMeasurementTogether;
            import matlab.unittest.measurement.internal.HasValidInteractions;
            import matlab.unittest.measurement.internal.HasValidKeepMeasuringState;
            import matlab.unittest.measurement.internal.HasValidLoopedMeasurementState;
            import matlab.unittest.measurement.internal.CalculateNewLoopCount;
            
            teardownTestMethod@matlab.unittest.plugins.TestRunnerPlugin(plugin, pluginData);
            
            context = pluginData.QualificationContext;
            
            plugin.verifyUsing(context, plugin, DidNotDetectFreshFixtureMeasurement(pluginData.Name));
            plugin.verifyUsing(context, plugin, DidNotDetectKeepMeasuringAndLoopedMeasurementTogether(pluginData.Name));
            
            idx = plugin.CurrentIndex;
            testResult = plugin.RunTestSuitePluginData.TestResult(idx);
            flattened = testResult.flatten;
            if flattened(end).Incomplete
                % If the result is already incomplete, subsequent
                % verifications of the measurement are unnecessary
                return;
            end
            
            plugin.assertUsing(context, plugin.Operator.Meter, HasValidKeepMeasuringState(pluginData.Name));
            plugin.assertUsing(context, plugin.Operator.Meter, HasValidLoopedMeasurementState());
            plugin.assertUsing(context, plugin.Operator.Meter, HasValidInteractions(pluginData.Name));

            if (plugin.UsingLoopedMeasurement)
                plugin.handleLastLoopedMeasurements(plugin.LoopCount);

                newStatuses = CalculateNewLoopCount(plugin.LoopCount,...
                    plugin.Operator.Meter.getLastMeasurements.Value, plugin.EstimationPhaseCount,...
                    plugin.MinTime, plugin.Estimating, plugin.RepeatIndex,plugin.MaxEstimationPhaseCount,...
                    pluginData.Name, plugin.KeepMeasuringLoopedMeasurementConflict, plugin.DetectedLoopingConflictBefore);

                plugin.LoopCount = newStatuses.LoopCount;
                plugin.Estimating = newStatuses.Estimating;
                plugin.EstimationPhaseCount = newStatuses.EstimationPhaseCount;
                plugin.DetectedLoopingConflictBefore = newStatuses.DetectedLoopingConflictBefore;
            end

            estimating = plugin.UsingLoopedMeasurement && plugin.Estimating;
            
            % record measurement
            plugin.Operator.completeTestRun(plugin.CurrentIndex, estimating);
        end
        
        function teardownTestRepeatLoop(plugin, pluginData)
            import matlab.unittest.measurement.internal.HasAllValuesSufficientlyOutsideCalibrationOffset;
            
            teardownTestRepeatLoop@matlab.unittest.plugins.TestRunnerPlugin(plugin, pluginData);

            % reset flags
            plugin.reset();
            
            context = pluginData.QualificationContext;
            idx = plugin.CurrentIndex;
            measurementResult = plugin.Result(idx);
            plugin.assumeUsing(context, measurementResult, HasAllValuesSufficientlyOutsideCalibrationOffset, ...
                getString(message('MATLAB:unittest:measurement:MeasurementPlugin:MeasuredCodeShouldBeSufficientlyLong', ...
                measurementResult.MeasuredVariableName)));
        end
        
        function teardownTestClass(plugin, pluginData)
            import matlab.unittest.measurement.internal.DidNotDetectClassBoundaryMeasurement;
            
            teardownTestClass@matlab.unittest.plugins.TestRunnerPlugin(plugin, pluginData);
            plugin.verifyUsing(pluginData.QualificationContext, plugin, DidNotDetectClassBoundaryMeasurement(pluginData.Name));
        end
        
        function reportFinalizedResult(plugin, pluginData)
            reportFinalizedResult@matlab.unittest.plugins.TestRunnerPlugin(plugin, pluginData);
            plugin.Operator.storeFinalizedTestResult(pluginData.Index, pluginData.TestResult);
        end
        
    end
    
    methods(Hidden, Access = protected)
        function handleKeepMeasuringData(plugin, data)
            plugin.UsingKeepMeasuring = true;

            % Store the state of keepMeasuring function call
            plugin.Operator.Meter.KeepMeasuringState = data.state;
            
            % Store the iteration data in the measurement
            if data.updateNeeded
                plugin.handleLastLoopingMeasurements(data.iteration);
            end
        end
        
        function handleLastLoopingMeasurements(plugin, niter)
            meter = plugin.Operator.Meter;
            label = meter.LabelList{end};
            lastMeasurements = meter.MeasurementContainer(label);
            
            if niter > 0
                if ~plugin.HasEstimatedKeepMeasuringOverhead
                    % Run the overhead estimator if have not done so
                    plugin.Operator.estimateKeepMeasuringOverhead;
                end
                overhead = plugin.Operator.KeepMeasuringOverheadEstimator.Overhead;
                % Update the number of iterations and overhead of the measurement 
                lastMeasurements = lastMeasurements.updateLastMeasurementsLoopingData(niter, overhead);
            else
                % Remove the measurement from the estimation phase
                lastMeasurements = lastMeasurements.removeLastMeasurement;
            end
            
            meter.MeasurementContainer(label) = lastMeasurements;
        end
    end

    methods(Hidden, Access = protected)
        function handleLoopedMeasurementData(plugin, data)
            plugin.UsingLoopedMeasurement = data.UsingLoopedMeasurement;
            plugin.Operator.Meter.LoopedMeasurementOn = data.UsingLoopedMeasurement;
        end
    end

    methods(Hidden, Access = protected)
        
        function handleLastLoopedMeasurements(plugin, niter)
            meter = plugin.Operator.Meter;
            label = meter.LabelList{end};
            lastMeasurements = meter.MeasurementContainer(label);

            if ~plugin.HasEstimatedLoopedMeasurementOverhead
                plugin.Operator.estimateLoopedMeasurementOverhead;
            end
            overhead = plugin.Operator.LoopedMeasurementOverheadEstimator.Overhead;
 
            lastMeasurements = lastMeasurements.updateLastMeasurementsLoopingData(niter, overhead);

            meter.MeasurementContainer(label) = lastMeasurements;
        end
    end
    
    methods(Access=private)
        function usesClassMeasurement(plugin, varargin)
            plugin.MeasuresAtClassBoundary = true;
        end
        function usesFreshFixtureMeasurement(plugin, varargin)
            plugin.MeasuresInFreshFixture = true;
        end
        function cleaner = disableFreshFixtureListeners(plugin)
            startingValue = [plugin.FreshFixtureListeners.Enabled];
            cleaner = onCleanup(@() plugin.applyFreshFixtureListenerEnabledState(startingValue));
            plugin.applyFreshFixtureListenerEnabledState(false(size(startingValue)));
        end
        
        function applyFreshFixtureListenerEnabledState(plugin, state)
            for idx = 1:numel(state)
                plugin.FreshFixtureListeners(idx).Enabled = state(idx);
            end
        end

    end

    methods(Access=private)

        function reset(plugin)
            plugin.UsingKeepMeasuring = false;
            plugin.UsingLoopedMeasurement = false;
            plugin.Estimating = true;
            plugin.LoopCount = 1;
        end
    end
    
end

% LocalWords:  perftest
