classdef (Hidden) TemperatureSensor < handle
    %Base class for temperature modules(codegen)
    
    %   Copyright 2020 The MathWorks, Inc.
    
    %#codegen
    
    properties(Abstract, Access = protected, Constant)
        TemperatureDataRegister; % output data register
    end
    
    methods(Abstract, Access = protected)
        readTemperatureImpl(obj);
    end
    
    methods
        function obj = TemperatureSensor()
        end
    end
    
    methods(Access = public)
        function [data, varargout] = readTemperature(obj)
            % To avoid unneccessary function call on hardware, get
            % timestamp from target only if it is requested.
            nargoutchk(0,2);
            data = readTemperatureImpl(obj);
            if nargout == 2
                varargout{1} = getCurrentTime(obj.Parent);
            end
        end
    end
end