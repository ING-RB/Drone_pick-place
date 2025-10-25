classdef Orientation < handle
    %codegen class for Orientation Sensor 
    
    %   Copyright 2020 The MathWorks, Inc.
    %#codegen
    properties(Abstract, Access = protected,Constant)        
       OrientationDataRegister; % output data register
    end

    properties(Access = protected)
        OrientationDataName = {'Orientation'};
    end
    
    methods(Abstract, Access = protected)
        readOrientationImpl(obj); 
    end
    
     methods
        function obj = Orientation()
        end
    end
    
    methods(Access = public)
        function  [data, varargout] = readOrientation(obj)
            % To avoid unneccessary function call on hardware, get
            % timestamp from target only if it is requested.
            nargoutchk(0,2);
            data = readOrientationImpl(obj);
            if nargout == 2
                varargout{1} = getCurrentTime(obj.Parent);
            end
        end
    end
end