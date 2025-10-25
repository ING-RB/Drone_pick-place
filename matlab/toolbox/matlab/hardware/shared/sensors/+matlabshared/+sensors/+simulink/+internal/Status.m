classdef Status < matlabshared.sensors.simulink.internal.OutputModuleBase
    %class for receiving status of data received.

    %Copyright 2023 The MathWorks, Inc.

    %#codegen
    properties(Nontunable)
        OutputSize = 1
        OutputName = 'Status'
        IsOutputComplex = false
        OutputDataType = 'uint8'
    end
 
    methods
        function [data,timestamp] = readSensorImpl(~, sensorObj)
            [data,timestamp] = readStatus(sensorObj);
        end
    end
end