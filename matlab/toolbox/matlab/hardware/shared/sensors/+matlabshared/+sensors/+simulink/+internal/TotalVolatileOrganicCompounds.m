classdef TotalVolatileOrganicCompounds < matlabshared.sensors.simulink.internal.OutputModuleBase
   %TotalVolatileOrganicCompounds object gives the the required fields for propogation
   
   %   methods related to TVOC
    
   %  Copyright 2023 The MathWorks, Inc.
    
   %#codegen
   properties(Nontunable)
        OutputSize = 1
        OutputName = 'eTVOC'
        IsOutputComplex = false
        OutputDataType = 'double'
    end
  
    methods
        function [data,timestamp]  = readSensorImpl(~, sensorObj,varargin)
            [data,timestamp]  = readTotalVolatileOrganicCompounds(sensorObj,varargin{:});
        end
    end
end