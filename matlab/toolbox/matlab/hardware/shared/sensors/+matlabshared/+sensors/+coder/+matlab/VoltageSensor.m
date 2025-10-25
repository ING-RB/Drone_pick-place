classdef (Hidden) VoltageSensor < handle
    %   Voltage base class
    %   Copyright 2022 The MathWorks, Inc.
    %#codegen
    properties(Abstract, Access = protected, Constant)
        ADCDataRegister; % output data register
    end
    
    methods(Abstract, Access = protected)
        readVoltageImpl(obj);
    end
    
    methods
        function obj = VoltageSensor()
        end
    end
    
    methods(Access = public)
        function [data, varargout] = readVoltage(obj,pinNumber)
            % To avoid unneccessary function call on hardware, get
            % timestamp from target only if it is requested.
            nargoutchk(0,2);
            data = readVoltageImpl(obj,pinNumber);
            if nargout == 2
                varargout{1} = getCurrentTime(obj.Parent);
            end
        end
    end
end