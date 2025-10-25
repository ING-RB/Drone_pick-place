classdef Temperature < matlabshared.sensors.simulink.internal.OutputModuleBase
    %TEMPERATURE object gives the the required fields for propogation
    %   methods related to Temperature
    
    %   Copyright 2017-2023 The MathWorks, Inc.
    
    %#codegen
    properties(Nontunable)
        OutputDataType = 'double';
        OutputSize = 1
        OutputName = 'Temperature'
        IsOutputComplex = false
    end
    methods
        function [data,timestamp] = readSensorImpl(~, sensorObj)
             [data,timestamp] = readTemperature(sensorObj);
        end
    end
end