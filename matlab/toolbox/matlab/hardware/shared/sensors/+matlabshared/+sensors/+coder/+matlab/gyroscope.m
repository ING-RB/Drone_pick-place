classdef (Hidden) gyroscope < handle
    %Base class for gyroscope  modules(codegen)
    
    %   Copyright 2020 The MathWorks, Inc.
    
    %#codegen
    
    properties(Abstract, Access = protected, Constant)
        GyroscopeDataRegister; % output data register
    end
    
    methods(Abstract, Access = protected)
        data = readAngularVelocityImpl(obj);
        initGyroscopeImpl(obj);
    end
    
    methods
        function obj = gyroscope()
        end
    end
    
    methods(Sealed, Access = public)
        function  [data, varargout] = readAngularVelocity(obj)
            % To avoid unneccessary function call on hardware, get
            % timestamp from target only if it is requested.
            nargoutchk(0,2);
            data = readAngularVelocityImpl(obj);
            if nargout == 2
                varargout{1} = getCurrentTime(obj.Parent);
            end
        end
    end
end
