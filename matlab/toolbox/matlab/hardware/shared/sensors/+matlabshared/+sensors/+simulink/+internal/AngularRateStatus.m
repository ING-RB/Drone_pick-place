classdef AngularRateStatus < matlabshared.sensors.simulink.internal.OutputModuleBase
    %class for receiving status of data received from Gyroscope.

    %Copyright 2023 The MathWorks, Inc.

    %#codegen
    properties(Nontunable)
        OutputSize = 1
        OutputDataType = 'int8'
        OutputName = 'Angular rate status'
        IsOutputComplex = false
    end

    methods
        function [data,timestamp] = readSensorImpl(~, sensorObj)
            [data,timestamp] = readAngularRateStatus(sensorObj);
        end
    end
end