classdef (Hidden) accelparamscg < fusion.internal.IMUSensorParameters
    %   
    %
    %   This class is for internal use only. It may be removed in the future.
    
    %   Copyright 2017-2019 The MathWorks, Inc.
    
    %#codegen
    
    methods
        function obj = accelparamscg(varargin)
            obj = obj@fusion.internal.IMUSensorParameters(varargin{:});
        end
    end
    
    methods (Access = protected)
        function sobj = createSystemObjectImpl(~, varargin)
            sobj = fusion.internal.AccelerometerSimulator(varargin{:});
        end
    end 
end
