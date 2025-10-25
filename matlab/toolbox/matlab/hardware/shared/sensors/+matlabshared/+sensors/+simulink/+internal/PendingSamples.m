classdef PendingSamples < matlabshared.sensors.simulink.internal.OutputModuleBase
    %class for receiving status of data received.
    %Copyright 2023 The MathWorks, Inc.
    %#codegen
    properties(Nontunable)
        OutputSize = 1
        OutputName = 'Samples Pending'
        IsOutputComplex = false
        OutputDataType = 'uint8'
    end
 
    methods
        function [data,timestamp] = readSensorImpl(~, sensorObj)
            [data,timestamp] = readPendingSamples(sensorObj);
        end
    end
end