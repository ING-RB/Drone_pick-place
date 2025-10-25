classdef Humidity < matlabshared.sensors.simulink.internal.OutputModuleBase
    %   Humidity class

    %   Copyright 2020-2023 The MathWorks, Inc.

    %#codegen

    properties(Nontunable)
        OutputDataType = 'double'
        OutputSize = 1
        OutputName = 'Humidity'
        IsOutputComplex = false
    end

    methods
        function [data, timestamp] = readSensorImpl(~, sensorObj)
            [data, timestamp] = readHumidity(sensorObj);
        end
    end
end