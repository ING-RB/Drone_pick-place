classdef Pressure < matlabshared.sensors.simulink.internal.OutputModuleBase
    %   Pressure class 
    %   Copyright 2020-2023 The MathWorks, Inc.
    
    %#codegen
    properties(Nontunable)
        OutputDataType = 'double'
        OutputSize = 1  
        OutputName = 'Pressure'
        IsOutputComplex = false
    end
    
    methods
        function [data,timestamp] = readSensorImpl(~, sensorObj)
             [data,timestamp] = readPressure(sensorObj);
        end
    end
end