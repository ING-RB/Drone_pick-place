classdef MagneticFieldStatus < matlabshared.sensors.simulink.internal.OutputModuleBase
    %class for receiving status of data received from Magnetometer.

    %Copyright 2023 The MathWorks, Inc.

    %#codegen
    properties(Nontunable)
        OutputSize = 1
        OutputName = 'Magnetic field status'
        IsOutputComplex = false
        OutputDataType = 'int8'
    end

    methods
        function [data,timestamp] = readSensorImpl(~, sensorObj)
            [data,timestamp] = readMagneticFieldStatus(sensorObj);
        end
    end
end