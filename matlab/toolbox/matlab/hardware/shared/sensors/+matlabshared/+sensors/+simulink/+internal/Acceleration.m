classdef Acceleration < matlabshared.sensors.simulink.internal.OutputModuleBase
   %ACCELERATION object gives the the required fields for propogation
   %   methods related to acceleration
    
   %   Copyright 2020-2023 The MathWorks, Inc.
    
   %#codegen
    properties(Nontunable)
        OutputSize = [1, 3]
        OutputName = 'Acceleration'
        IsOutputComplex = false
        OutputDataType = 'double'
    end
  
    methods
        function [data,timestamp] = readSensorImpl(~, sensorObj)
            [data,timestamp] = readAcceleration(sensorObj);
        end
    end
end