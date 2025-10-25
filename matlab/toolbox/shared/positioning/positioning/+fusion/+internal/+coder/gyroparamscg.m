classdef (Hidden) gyroparamscg < fusion.internal.IMUSensorParameters
    %   
    %
    %   This class is for internal use only. It may be removed in the future.
    
    %   Copyright 2017-2019 The MathWorks, Inc.
    
    %#codegen
    
    properties
        AccelerationBias = [0 0 0];
    end

    methods
        function obj = gyroparamscg(varargin)
            obj = obj@fusion.internal.IMUSensorParameters(varargin{:});
        end
    end
    
    methods (Access = protected)
        function sobj = createSystemObjectImpl(~)
            sobj = fusion.internal.GyroscopeSimulator();
        end
        
        function updateSystemObjectImpl(obj, sobj)
            sobj.AccelerationBias = obj.AccelerationBias;
        end
    end
    
    methods
        function obj = set.AccelerationBias(obj,val)
            validateattributes(val, {'single','double'}, {'real','finite'}, 'set.AccelerationBias');
            fusion.internal.IMUSensorParameters.validateSize(val, 'AccelerationBias');
            obj.AccelerationBias(:) = val;
        end
    end   
end
