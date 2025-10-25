classdef EquivalentCarbondioxide < matlabshared.sensors.simulink.internal.OutputModuleBase
   %EquivalentCarbondioxide object gives the the required fields for propogation
   
   %methods related to eCO2
    
   %  Copyright 2023 The MathWorks, Inc.
    
   %#codegen
    properties(Nontunable)
        OutputSize = 1
        OutputName = 'eCO2'
        IsOutputComplex = false
        OutputDataType = 'double'
    end
  
    methods
        function [data,timestamp]  = readSensorImpl(~, sensorObj,varargin)
            [data,timestamp]  = readEquivalentCarbondioxide(sensorObj,varargin{:});
        end
    end
end