classdef Measurement <matlab.unittest.measurement.internal.MeasurementInterface
    % This class is undocumented and subject to change in a future release
    
    % Copyright 2015-2018 The MathWorks, Inc.      
    
    properties (SetAccess = immutable)
        Value
        Timestamp
    end
    
    properties (Hidden)
        NumIterations uint64 = 1;
        Overhead = 0;
    end
    
    methods (Hidden)
        function measurement = Measurement(value, timestamp, niter, overhead)
            if nargin < 1
                return % Allow preallocation
            elseif nargin < 3
                niter = 1;
                overhead = 0;
            end
            measurement.Value = value;
            measurement.Timestamp = timestamp;
            measurement.NumIterations = niter;
            measurement.Overhead = overhead;
        end
        
        function t = getTaredValue(measurement,tare)
            t = ([measurement.Value] - tare) / double(measurement.NumIterations) - measurement.Overhead;
        end
        
        function measurement = updateLastMeasurementsLoopingData(measurement, niter, overhead)
            if ~isempty(measurement)
                measurement(end).NumIterations = niter;
                measurement(end).Overhead = overhead;
            end
        end
    end
    
    methods(Hidden)
        function tf = isOutsidePrecision(measurement,tare,threshold)
            if nargin < 3
                threshold = 5;
            end
            
            % Should be sufficiently outside the framework overhead AND
            % the whileLoop/TicToc overhead if auto-looping is applied
            
            % Make sure the iterated total result is sufficiently outside of tare 
            % This is equivalent to (measurement.getTaredValue(tare) + overhead) * measurement.NumIterations > threshold * tare
            isOutsideFrameworkOverhead = (measurement.Value - tare) > threshold * tare;
            
            % Make sure the average result from each iteration is sufficiently outside of overhead
            isOutsideAutoLoopingOverhead = measurement.getTaredValue(tare) > threshold * measurement.Overhead;
            
            tf = isOutsideFrameworkOverhead && isOutsideAutoLoopingOverhead;
        end
    end
            
end