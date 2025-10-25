classdef accelparams < fusion.internal.IMUSensorParameters & fusion.internal.UnitDisplayer
%

%   Copyright 2017-2023 The MathWorks, Inc.

%#codegen
    
    methods
        function obj = accelparams(varargin)
            obj = obj@fusion.internal.IMUSensorParameters(varargin{:});
        end
    end
    
    methods (Access = protected)
        function sobj = createSystemObjectImpl(~, varargin)
            sobj = fusion.internal.AccelerometerSimulator(varargin{:});
        end
        
        function unit = getDisplayUnitImpl(~)
            unit = ['m/s' char(178)];
        end
        
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
                    
                basicGroup = matlab.mixin.util.PropertyGroup(basicList);
                noiseGroup = matlab.mixin.util.PropertyGroup(noiseList);
                envGroup   = matlab.mixin.util.PropertyGroup(envList);

                groups = [basicGroup noiseGroup envGroup];
            end
        end
    end
    
    methods (Hidden, Static)
        function name = matlabCodegenRedirect(~)
            name = 'fusion.internal.coder.accelparamscg';
        end
    end    
end
