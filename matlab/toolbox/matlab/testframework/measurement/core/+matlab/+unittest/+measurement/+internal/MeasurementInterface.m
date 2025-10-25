classdef MeasurementInterface < matlab.mixin.Heterogeneous
    % Measurement Interface
    % This class is undocumented and subject to change in a future release
    
    % Copyright 2017-2020 The MathWorks, Inc.
    
    properties(Abstract, SetAccess = immutable)
        Value
        Timestamp
    end
    
    properties(SetAccess=immutable)
        Host = getHostName;
        Platform = getPlatform;
        Version = getVersion;
    end
    
    methods(Abstract)
        t = getTaredValue(measurement,tare)
    end
    
    methods(Abstract, Hidden)
        tf = isOutsidePrecision(measurement,tare,threshold)
    end
    
    methods
        function m = addMeasurement(measurement,newmeasurement)
            m = [measurement, newmeasurement];
        end
        
        function value = getMinimumValue(measurements)
            value = min([measurements.Value]);
        end
    end
end

function host = getHostName
host = categorical({matlab.unittest.internal.getHostname});
end

function platform = getPlatform
platform = categorical({computer('arch')});
end

function v = getVersion
v = categorical({version});
end

% LocalWords:  newmeasurement
