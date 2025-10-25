classdef TapEventSource < matlabshared.sensors.simulink.internal.OutputModuleBase
    %class for receiving Tap interrupt source from BMI160.

    %Copyright 2023 The MathWorks, Inc.

    %#codegen
    properties(Nontunable)
        OutputSize = [1,4]
        OutputName = 'Tap event source'
        IsOutputComplex = false
        OutputDataType = 'uint8'
    end

    methods
        function [data,timestamp] = readSensorImpl(~, sensorObj)
            [data,timestamp] = readTapEventSource(sensorObj);
        end
    end
end