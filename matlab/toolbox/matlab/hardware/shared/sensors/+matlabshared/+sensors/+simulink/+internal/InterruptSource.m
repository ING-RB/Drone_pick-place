classdef InterruptSource < matlabshared.sensors.simulink.internal.OutputModuleBase
    %class for receiving source of interrupts received from BMI160.

    %Copyright 2023 The MathWorks, Inc.

    %#codegen
    properties(Nontunable)
        OutputSize = [1,7]
        OutputName = 'Interrupt source'
        IsOutputComplex = false
        OutputDataType = 'int8'
    end

    methods
        function [data,timestamp] = readSensorImpl(~, sensorObj)
            [data,timestamp] = readInterruptSource(sensorObj);
        end
    end
end