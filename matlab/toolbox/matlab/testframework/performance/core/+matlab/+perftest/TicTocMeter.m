classdef (Hidden) TicTocMeter < matlab.unittest.measurement.internal.Meter
    % This class is undocumented and subject to change in a future release
    
    
    % Copyright 2015-2024 The MathWorks, Inc.
    
    properties(Access=private)
        TimerValue = uint64(0);
    end
    
    methods
        
        function start(meter,~)
            meter.State = start(meter.State);
            meter.TimerValue = tic; % Always should be last
        end
        
        function stop(meter,label)
            import matlab.unittest.measurement.internal.Measurement;
            
            timingResult = toc(meter.TimerValue); % Always should be first
            
            meter.State = stop(meter.State);
            measurement = Measurement(timingResult,datetime);
            meter.addMeasurement(measurement,label);
        end
        
    end
    
    methods(Hidden, Access=protected)
        function m = createEmptyMeasurement(~)
            import matlab.unittest.measurement.internal.AccumulatedMeasurement;
            import matlab.unittest.measurement.internal.Measurement;
            m = AccumulatedMeasurement(Measurement.empty);
        end
    end
    
    methods (Hidden)
        
        function logTimeMeasurement(meter,measurement,label)
            meter.LabelList(end+1) = {label};
            meter.State = log(meter.State);
            meter.addMeasurement(measurement,label);

        end
        
    end

    methods(Access=?matlab.unittest.measurement.MeasurementPlugin)
        % This helper function is designed to triage measurements and
        % return the appropriate one for LoopCount calculation, if the
        % target test point is using startMeasuring/stopMeasuring,
        % "_implicit" labeled result is discared, otherwise
        % "_implicit" measurement is used. For now we do not support
        % multiple measurements in one test point, so numel(measurements)
        % should always equal to 1.
        function measurements = getLastMeasurements(meter)
            container = meter.MeasurementContainer;
            measurements = [];
            Labels = unique(meter.LabelList,'stable');

            for i = 1:length(Labels)
                label = Labels{i};
                
                if meter.isSelfMeasured && strcmp(label,'_implicit')
                    continue;
                end

                if container.isKey(label)
                    measurements(end + 1).Label = label; %#ok<AGROW>
                    measurements(end).Value = container(label).Value;
                end
            end
        end
    end
    
end
