classdef (Hidden) PressureSensor < handle
    %   Pressure base class 
    
    %   Copyright 2020 The MathWorks, Inc.
    
    %#codegen
    
    properties(Abstract, Access = protected, Constant)
        PressureDataRegister; % output data register
    end
    
    methods(Abstract, Access = protected)
        initPressureImpl(obj);
        readPressureImpl(obj);
    end
    
    methods
        function obj = PressureSensor()
        end
    end
    
    methods(Sealed, Access = public)
        function [data, varargout] = readPressure(obj)
            % To avoid unneccessary function call on hardware, get
            % timestamp from target only if it is requested.
            nargoutchk(0,2);
            data = readPressureImpl(obj);
            if nargout == 2
                varargout{1} = getCurrentTime(obj.Parent);
            end
        end
    end
end