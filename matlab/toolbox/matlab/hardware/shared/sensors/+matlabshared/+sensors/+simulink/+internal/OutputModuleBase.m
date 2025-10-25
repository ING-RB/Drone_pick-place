classdef OutputModuleBase < matlab.System
   %OUTPUTMODULEBASE class is the base class that each output value has to
   %inherit.
   %   This class gives the abstract properties and methods for the
   %   simulink propogation methods.
    
   %   Copyright 2020-2023 The MathWorks, Inc.
    
    %#codegen
    
    properties(Abstract,Nontunable)
        OutputDataType char
        OutputSize double
        OutputName char
        IsOutputComplex logical
    end
    
    methods(Access=public)
        function [data,timestamp] = readSensor(obj,sensorBlockObject,varargin)
            [data,timestamp]=readSensorImpl(obj,sensorBlockObject.SensorObject,varargin{:}); %Pass matlab object inside sensorblock object
            dataUpdateBlockFunction(sensorBlockObject,obj.OutputName);
        end 
    end 

    methods(Abstract)
        [data,timestamp] = readSensorImpl(obj)        
    end
end