classdef AngularVelocity < matlabshared.sensors.simulink.internal.OutputModuleBase
   %ANGULAR VELOCITY object gives the the required fields for propogation
   %   methods related to angularVelocity
    
   %   Copyright 2020-2023 The MathWorks, Inc.
   
    %#codegen
    properties(Nontunable)
        OutputSize = [1, 3]
        OutputName = 'Angular Rate'
        IsOutputComplex = false
        OutputDataType = 'double'
    end
  
    methods
        function [data, timestamp] = readSensorImpl(~, sensorObj)
            [data,timestamp] = readAngularVelocity(sensorObj);
        end
    end
end