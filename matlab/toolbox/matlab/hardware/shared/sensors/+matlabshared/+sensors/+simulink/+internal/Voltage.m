classdef Voltage < matlabshared.sensors.simulink.internal.OutputModuleBase
    %Voltage object gives the the required fields for propogation
    %   methods related to Voltage
    %   Copyright 2023 The MathWorks, Inc.
    
    %#codegen
    properties(Nontunable)
        OutputDataType = 'double';
        OutputSize = 1
        OutputName = 'Voltage'
        IsOutputComplex = false
        pinNumber="ADC1";
    end
    
    methods
        function [data,timestamp] = readSensorImpl(obj, sensorObj)
             [data,timestamp] = readVoltage(sensorObj,obj.pinNumber);
        end
    end
end