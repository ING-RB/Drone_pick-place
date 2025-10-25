classdef HighGEventSource < matlabshared.sensors.simulink.internal.OutputModuleBase
    %class for receiving High G interrupt source from BMI160.

    %Copyright 2023 The MathWorks, Inc.

    %#codegen
    properties(Nontunable)
        OutputSize = [1,4]
        OutputName = 'High g event source'
        IsOutputComplex = false
        OutputDataType = 'uint8'
    end

    methods
        function [data,timestamp] = readSensorImpl(~, sensorObj)
            [data,timestamp] = readHighGEventSource(sensorObj);
        end
    end
end