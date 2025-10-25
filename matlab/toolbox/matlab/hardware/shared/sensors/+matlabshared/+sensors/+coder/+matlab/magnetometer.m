classdef (Hidden) magnetometer < handle
    %Base class for magnetometer modules(codegen)
    
    %   Copyright 2020 The MathWorks, Inc.
    
    %#codegen
    
    properties(Abstract, Access = protected, Constant)
        MagnetometerDataRegister; % output data register
    end
    
    properties(Abstract, Access = protected)
        MagnetometerResolution; % resolution
    end
    
    methods(Abstract, Access = protected)
        data = readMagneticFieldImpl(obj);
        initMagnetometerImpl(obj);
    end
    
    methods
        function obj = magnetometer()
        end
    end
    
    methods(Access = public)
        function  [data, varargout] = readMagneticField(obj)
            % To avoid unneccessary function call on hardware, get
            % timestamp from target only if it is requested.
            nargoutchk(0,2);
            data = readMagneticFieldImpl(obj);
            if nargout == 2
                varargout{1} = getCurrentTime(obj.Parent);
            end
        end
    end
end

