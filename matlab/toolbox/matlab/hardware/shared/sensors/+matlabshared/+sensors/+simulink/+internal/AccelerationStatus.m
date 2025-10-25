classdef AccelerationStatus < matlabshared.sensors.simulink.internal.OutputModuleBase
    %class for receiving status of data received from Accelerometer.

    %Copyright 2023 The MathWorks, Inc.

    %#codegen
    properties(Nontunable)
        OutputSize = 1
        OutputDataType = 'int8'
        OutputName = 'Acceleration status'
        IsOutputComplex = false
    end

    methods
        function [data,timestamp] = readSensorImpl(~, sensorObj)
            [data,timestamp] = readAccelerationStatus(sensorObj);
        end
    end
end