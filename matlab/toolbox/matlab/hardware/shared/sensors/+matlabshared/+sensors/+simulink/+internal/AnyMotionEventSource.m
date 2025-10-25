classdef AnyMotionEventSource < matlabshared.sensors.simulink.internal.OutputModuleBase
    %class for receiving Any motion interrupt source received from BMI160.

    %Copyright 2023 The MathWorks, Inc.

    %#codegen
    properties(Nontunable)
        OutputSize = [1,4]
        OutputName = 'Any motion event source'
        IsOutputComplex = false
        OutputDataType = 'uint8'
    end

    methods
        function [data,timestamp] = readSensorImpl(~, sensorObj)
            [data,timestamp] = readAnyMotionEventSource(sensorObj);
        end
    end
end