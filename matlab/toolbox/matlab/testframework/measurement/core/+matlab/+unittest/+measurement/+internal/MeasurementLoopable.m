classdef(Hidden) MeasurementLoopable < matlab.unittest.internal.Measurable
    
    % This class is undocumented and subject to change in a future release
    
    % Copyright 2020-2024 The MathWorks, Inc.
    
    properties (Hidden, SetAccess = private, GetAccess = protected)
        NumIterationsRemaining_ double = [];
        NumEstimatedIterations_ double = [];
        KeepMeasuringState_ = matlab.unittest.measurement.internal.looping.Unused;
        
        % The 0.01 is picked to be both quick to reach by looping
        % and not be filtered according to calibration 
        MinTime_ = 0.01;
        EstimationPhaseTimeMarker_ uint64 = 0; 
    end
    
    properties (Hidden, Constant)
        MeasurementCommunicationChannel_ = "unittest:measurement:keepMeasuring";
        MeasurementCommunicationChannel_LoopedMeasurement_ = "unittest:measurement:loopedMeasurement";
    end

    properties (SetAccess = ?matlab.unittest.measurement.MeasurementPlugin, GetAccess=private)
        LoopCount_ = 1;
    end
    
    methods(Sealed)
        function tf = keepMeasuring(measurable,varargin)
            % keepMeasuring - Measure code with automatic looping.
            %   To iterate code and measure the performance automatically,
            %   use keepMeasuring in the condition of a while loop.
            %
            %   keepMeasuring(TESTCASE) when used in the condition of a while loop 
            %   instructs the testing framework to iterate through the code
            %   in the while loop and measure the average performance. 
            %
            %   keepMeasuring(TESTCASE, LABEL) measures the average performance 
            %   of the code in the while loop and labels the measurement with LABEL. 
            %   LABEL must be a valid MATLAB variable name. Measurements generated 
            %   in the same test method and with the same label are accumulated 
            %   and summed.
            %
            %   Example:
            %       classdef tcellstr < matlab.perftest.TestCase
            %
            %           properties (TestParameter)
            %               Size = {1e2, 1e3, 1e4, 1e5};
            %           end
            %     
            %           methods(Test)
            %               function bar(testCase, Size)
            %                   prevState = rng(0,'twister');
            %                   testCase.addTeardown(@()rng(prevState));
            %                   testString = char('a' + randi(26, Size, 10));
            %                   
            %                   while(testCase.keepMeasuring)
            %                       [~] = cellstr(testString);
            %                   end
            %               end
            %           end
            %       end
            
            tf = true;
            numIterationsRemaining = measurable.NumIterationsRemaining_;
            
            % if measurable.KeepMeasuringState_ == Measuring
            if numIterationsRemaining > 1
                measurable.NumIterationsRemaining_ = numIterationsRemaining - 1;
                return;
            elseif numIterationsRemaining == 1
                % Looping done, numIterationsRemaining = 1
                % Measurement phase: stopMeasuring
                measurable.stopMeasuring(varargin{:});
                tf = false;
                measurable.KeepMeasuringState_ = switchToNext(measurable.KeepMeasuringState_);
                measurable.publishToPluginKeepMeasuring(measurable.KeepMeasuringState_, measurable.NumEstimatedIterations_);
                
                measurable.NumIterationsRemaining_ = [];
                measurable.NumEstimatedIterations_ = [];
                measurable.KeepMeasuringState_ = reset(measurable.KeepMeasuringState_);
                
            % elseif measurable.KeepMeasuringState_ == Estimating or Unused
            elseif isempty(numIterationsRemaining)
                estimationComplete = measurable.estimationPhase(varargin{:});
                if estimationComplete
                    measurable.KeepMeasuringState_ = switchToNext(measurable.KeepMeasuringState_);
                    if measurable.NumEstimatedIterations_ == 1
                        tf = false;
                        % Skip Measuring phase to Completed
                        measurable.KeepMeasuringState_ = switchToNext(measurable.KeepMeasuringState_);
                        measurable.publishToPluginKeepMeasuring(measurable.KeepMeasuringState_);
                        
                        measurable.NumEstimatedIterations_ = [];
                        measurable.KeepMeasuringState_ = reset(measurable.KeepMeasuringState_);
                        return;
                    end
                    measurable.publishToPluginKeepMeasuring(measurable.KeepMeasuringState_, 0);
                    measurable.NumIterationsRemaining_ = measurable.NumEstimatedIterations_;
                    
                    % Measurement phase: startMeasuring
                    measurable.startMeasuring(varargin{:});
                end
            end
        end
    end

    methods(Sealed, Hidden)
        % For every testCase instance, this function will only be called
        % once
        function lc = loopCount(measurable)
            lc = measurable.LoopCount_;
            measurable.publishToPluginLoopedMeasurement();
        end
    end
    
    methods(Abstract)
        publish(measurable,varargin)
    end

    methods(Access = private)
        function estimationDone = estimationPhase(measurable, varargin)
            estimationDone = false;
            if isempty(measurable.NumEstimatedIterations_)
                % Before start estimating, 
                % publish the current state (Estimating) to plugin
                measurable.NumEstimatedIterations_ = 0;
                measurable.KeepMeasuringState_ = switchToNext(measurable.KeepMeasuringState_);
                measurable.publishToPluginKeepMeasuring(measurable.KeepMeasuringState_);
                
                measurable.EstimationPhaseTimeMarker_ = tic;
                measurable.startMeasuring(varargin{:});
            else
                if measurable.NumEstimatedIterations_ == 0
                   % A measurement potentially to use 
                   measurable.stopMeasuring(varargin{:});
                end
                
                % A rough estimate of time taken per iteration
                totalTime = toc(measurable.EstimationPhaseTimeMarker_);
                
                measurable.NumEstimatedIterations_ = measurable.NumEstimatedIterations_ + 1;
                
                estimationDone = totalTime > measurable.MinTime_;
            end
        end
        
        function publishToPluginKeepMeasuring(measurable, state, iteration)
            if nargin < 3
                iteration = [];
            end
            
            dataToPublish.updateNeeded = ~isempty(iteration);
            dataToPublish.iteration = iteration;
            dataToPublish.state = state;
            measurable.publish(measurable.MeasurementCommunicationChannel_, dataToPublish);
        end

        function publishToPluginLoopedMeasurement(measurable)
            dataToPublish.UsingLoopedMeasurement = true;
            measurable.publish(measurable.MeasurementCommunicationChannel_LoopedMeasurement_, dataToPublish);
        end
    end
end

% LocalWords:  tcellstr perftest prev randi
