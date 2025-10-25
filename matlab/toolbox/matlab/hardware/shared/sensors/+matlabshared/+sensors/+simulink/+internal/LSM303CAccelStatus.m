classdef LSM303CAccelStatus < matlabshared.sensors.simulink.internal.OutputModuleBase
    %class for LSM303C Accelerometer and Magnetometer status.
    
    %Copyright 2020-2023 The MathWorks, Inc.
    %#codegen
    properties
        OutputSize = [1, 3]
        OutputDataType = 'uint8'
        OutputName = 'Acceleration Status'
        IsOutputComplex = false
    end
    
    methods
        function data = readSensorImpl(~, sensorObj)
            data = readAccelStatus(sensorObj);
        end
    end
end