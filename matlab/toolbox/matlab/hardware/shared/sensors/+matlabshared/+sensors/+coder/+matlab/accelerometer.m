classdef (Hidden) accelerometer < handle
   %Base class for accelerometer modules
    
    %   Copyright 2017-2020 The MathWorks, Inc.
    %#codegen
    
    properties(Abstract, Access = protected, Constant)
        AccelerometerDataRegister; % output data register
    end
    
    methods(Abstract, Access = protected)
        data = readAccelerationImpl(obj);
        initAccelerometerImpl(obj);
    end
    
    methods
        function obj = accelerometer()
        end
    end
    
    methods(Access = public)
        function [data, varargout] = readAcceleration(obj)
            % To avoid unneccessary function call on hardware, get
            % timestamp from target only if it is requested.
            nargoutchk(0,2);
            data = readAccelerationImpl(obj);
            if nargout == 2
                varargout{1} = getCurrentTime(obj.Parent);
            end
        end
    end
end