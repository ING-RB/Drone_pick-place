classdef gyroparams < fusion.internal.IMUSensorParameters & fusion.internal.UnitDisplayer
%

%   Copyright 2017-2023 The MathWorks, Inc.

%#codegen
    
    properties
        %
        AccelerationBias = [0 0 0];
    end
    
    properties (Hidden)
        AccelerationBiasUnits;
    end
    
    methods
        function obj = gyroparams(varargin)
            obj = obj@fusion.internal.IMUSensorParameters(varargin{:});
        end
    end
    
    methods (Access = protected)
        function sobj = createSystemObjectImpl(~)
            sobj = fusion.internal.GyroscopeSimulator();
        end
        
        function updateSystemObjectImpl(obj, sobj)
            sobj.AccelerationBias = getRowVector(obj, 'AccelerationBias');
        end

        function unit = getDisplayUnitImpl(~)
            unit = 'rad/s';
        end
    end
    
    methods
        function obj = set.AccelerationBias(obj,val)
            validateattributes(val, {'single','double'}, {'real','finite'}, '', 'AccelerationBias');
            fusion.internal.IMUSensorParameters.validateSize(val, 'AccelerationBias');
            obj.AccelerationBias = val .* ones(1,3);
        end
        
        function val = get.AccelerationBiasUnits(obj)
            val = sprintf(['(%s)/(m/s' char(178) ')'],obj.getDisplayUnit);
        end
    end
    
    methods (Access = protected)
        function groups = getPropertyGroups(obj)
            if ~isscalar(obj)
                groups = getPropertyGroups@matlab.mixin.CustomDisplay(obj);
            else
                basicList.MeasurementRange     = obj.MeasurementRange;
                basicList.Resolution           = obj.Resolution;
                basicList.ConstantBias         = obj.ConstantBias;
                basicList.AxesMisalignment     = obj.AxesMisalignment;
                
                noiseList.NoiseDensity                = obj.NoiseDensity;
                noiseList.BiasInstability             = obj.BiasInstability;
                noiseList.RandomWalk                  = obj.RandomWalk;
                noiseList.NoiseType                   = obj.NoiseType;
                noiseList.BiasInstabilityCoefficients = obj.BiasInstabilityCoefficients;
                
                envList.TemperatureBias        = obj.TemperatureBias;
                envList.TemperatureScaleFactor = obj.TemperatureScaleFactor;
                envList.AccelerationBias       = obj.AccelerationBias;
                    
                basicGroup = matlab.mixin.util.PropertyGroup(basicList);
                noiseGroup = matlab.mixin.util.PropertyGroup(noiseList);
                envGroup   = matlab.mixin.util.PropertyGroup(envList);

                groups = [basicGroup noiseGroup envGroup];
            end
        end
    end

    methods (Hidden, Static)
        function name = matlabCodegenRedirect(~)
            name = 'fusion.internal.coder.gyroparamscg';
        end
    end
end
