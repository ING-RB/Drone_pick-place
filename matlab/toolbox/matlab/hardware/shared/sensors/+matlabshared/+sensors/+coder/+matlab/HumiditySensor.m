classdef (Hidden) HumiditySensor < handle
    %   Humidity base class
    
    %   Copyright 2020 The MathWorks, Inc.
    
    %#codegen
    
    properties(Abstract, Access = protected, Constant)
        HumidityDataRegister; % output data register
    end
    
    methods(Abstract, Access = protected)
        initHumidityImpl(obj);
        readHumidityImpl(obj);
    end
    
    methods
        function obj = HumiditySensor()
        end
    end
    
    methods(Sealed, Access = public)
        function [data, varargout] = readHumidity(obj)
            % To avoid unneccessary function call on hardware, get
            % timestamp from target only if it is requested.
            nargoutchk(0,2);
            data = readHumidityImpl(obj);
            if nargout == 2
                varargout{1} = getCurrentTime(obj.Parent);
            end
        end
    end
end