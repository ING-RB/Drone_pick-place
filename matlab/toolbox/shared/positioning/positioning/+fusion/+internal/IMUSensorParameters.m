classdef (Hidden) IMUSensorParameters
    %   Abstract class for fusion.internal.IMUSensorParameters.
    %
    %   This class is used to validate sensor parameters.
    %
    %   This class is for internal use only. It may be removed in the future.
    
    %   Copyright 2017-2023 The MathWorks, Inc.
    
    %#codegen
    
    properties
        %
        MeasurementRange = Inf;
        %
        Resolution = 0;
        %
        ConstantBias = [0 0 0];
        %
        AxesMisalignment = 100*eye(3);
        %
        NoiseDensity = [0 0 0];
        %
        BiasInstability = [0 0 0];
        %
        RandomWalk = [0 0 0];
        %
        BiasInstabilityCoefficients (1,1) struct = fractalcoef;
        %
        NoiseType (1,1) string {mustBeTextScalar} = "double-sided";
        %
        TemperatureBias = [0 0 0];
        %
        TemperatureScaleFactor = [0 0 0];
    end
    
    properties (Hidden, Constant)
        AxesMisalignmentUnits = '%';
        TemperatureScaleFactorUnits = ['%/' char(176) 'C'];
    end

    properties (Hidden)
        MeasurementRangeUnits
        ResolutionUnits
        ConstantBiasUnits
        NoiseDensityUnits
        BiasInstabilityUnits
        RandomWalkUnits
        TemperatureBiasUnits
    end
    
    methods % Display Unit Methods
        function val = get.MeasurementRangeUnits(obj)
            val = sprintf(obj.getDisplayUnit);
        end
        function val = get.ResolutionUnits(obj)
            val = sprintf('(%s)/LSB',obj.getDisplayUnit);
        end
        function val = get.ConstantBiasUnits(obj)
            val = sprintf(obj.getDisplayUnit);
        end
        function val = get.NoiseDensityUnits(obj)
            val = sprintf(['(%s)/' char(8730) 'Hz'],obj.getDisplayUnit);
        end
        function val = get.RandomWalkUnits(obj)
            val = sprintf(['(%s)*' char(8730) 'Hz'],obj.getDisplayUnit);
        end
        function val = get.BiasInstabilityUnits(obj)
            val = sprintf(obj.getDisplayUnit);
        end
        function val = get.TemperatureBiasUnits(obj)
            val = sprintf(['(%s)/' char(176) 'C'],obj.getDisplayUnit);
        end
    end
    
    methods (Access = protected)
        function unit = getDisplayUnitImpl(~)
            unit = '';
        end
    end
    
    methods (Access = protected, Sealed)
        function unit = getDisplayUnit(obj)
            unit = getDisplayUnitImpl(obj);
        end
    end
    
    methods
        % Constructor
        function obj = IMUSensorParameters(varargin)
            obj = matlabshared.fusionutils.internal.setProperties(obj, nargin, varargin{:});
        end
        
%---------------------Set Methods Begin------------------------------------
        
        function obj = set.MeasurementRange(obj,val)
            validateattributes(val, {'single','double'}, {'scalar','real','positive','nonnan'}, '', 'MeasurementRange');
            obj.MeasurementRange = val;
        end
        
        function obj = set.Resolution(obj,val)
            validateattributes(val, {'single','double'}, {'scalar','real','nonnegative','finite'}, '', 'Resolution');
            obj.Resolution = val;
        end
        
        function obj = set.ConstantBias(obj,val)
            validateattributes(val, {'single','double'}, {'real','finite'}, '', 'ConstantBias');
            fusion.internal.IMUSensorParameters.validateSize(val, 'ConstantBias');
            obj.ConstantBias(:) = val;
        end
        
        function obj = set.AxesMisalignment(obj,valIn)
            prop = 'AxesMisalignment';
            num = 3;
            numstr = string(num);
            
            validateattributes(valIn, {'single', 'double'}, ...
                {'2d', 'nonempty', 'real'}, '', prop);

            
            % Error if not scalar, 3-element vector, or 3-by-3 matrix.
            sz = size(valIn);
            coder.internal.assert(isscalar(valIn) || ...
                isequal(sz, [num 1]) || isequal(sz, [1 num]) || ...
                isequal(size(valIn), [num num]), ...
                'shared_positioning:internal:IMUSensorParameters:ParameterSizeOptions', ...
                prop, numstr);
            
            % Expand to 3-by-3 matrix.
            if ((numel(valIn) == 1) || (numel(valIn) == num))
                I = eye(num, num, 'like', valIn);
                onesMask = ones(num, num, 'like', valIn) - I;
                val = 100*I + bsxfun(@times, onesMask, valIn(:).');
            else
                val = valIn;
            end
            
            obj.AxesMisalignment = val;
        end
        
        function obj = set.NoiseDensity(obj,val)
            validateattributes(val, {'single','double'}, {'real', 'nonnegative', 'finite'}, '', 'NoiseDensity');
            fusion.internal.IMUSensorParameters.validateSize(val, 'NoiseDensity');
            obj.NoiseDensity(:) = val;
        end
        
        function obj = set.BiasInstability(obj,val)
            validateattributes(val, {'single','double'}, {'real', 'nonnegative', 'finite'}, '', 'BiasInstability');
            fusion.internal.IMUSensorParameters.validateSize(val, 'BiasInstability');
            obj.BiasInstability(:) = val;
        end
        
        function obj = set.RandomWalk(obj,val)
            validateattributes(val, {'single','double'}, {'real', 'nonnegative', 'finite'}, '', 'RandomWalk');
            fusion.internal.IMUSensorParameters.validateSize(val, 'RandomWalk');
            obj.RandomWalk(:) = val;
        end
        
        function obj = set.TemperatureBias(obj,val)
            validateattributes(val, {'single','double'}, {'real', 'finite'}, '', 'TemperatureBias');
            fusion.internal.IMUSensorParameters.validateSize(val, 'TemperatureBias');
            obj.TemperatureBias(:) = val;
        end
        
        function obj = set.TemperatureScaleFactor(obj,val)
            validateattributes(val, {'single','double'}, {'real', '>=',0,'<=',100}, '', 'TemperatureScaleFactor');
            fusion.internal.IMUSensorParameters.validateSize(val, 'TemperatureScaleFactor');
            obj.TemperatureScaleFactor(:) = val;
        end

        function obj = set.NoiseType(obj,val)
            type = validatestring(val, {'double-sided','single-sided'}, '', 'NoiseType');
            obj.NoiseType = string(type);
        end

        function obj = set.BiasInstabilityCoefficients(obj,val)
            num = "Numerator";
            den = "Denominator";
            coder.internal.errorIf(~isfield(val, num) || ~isfield(val, den), ...
                "shared_positioning:imuSensor:InvalidBiasInstabilityCoefficientsFields", num, den);
            validateattributes(val.Numerator, {'double','single'}, ...
                {'real','finite','vector'}, '', 'BiasInstabilityCoefficients.Numerator');
            validateattributes(val.Denominator, {'double','single'}, ...
                {'real','finite','vector'}, '', 'BiasInstabilityCoefficients.Denominator');
            
            obj.BiasInstabilityCoefficients = val;
        end
        
%---------------------Set Methods End--------------------------------------
        
    end
    
    methods (Abstract, Access = protected)
        sobj = createSystemObjectImpl(obj);
    end
    
    methods (Access = protected)
        function updateSystemObjectImpl(~, ~)
        end
    end
    
    methods (Hidden, Sealed)
        function sobj = createSystemObject(obj, varargin)
            sobj = createSystemObjectImpl(obj, varargin{:});
            updateSystemObject(obj, sobj);
        end
        
        function updateSystemObject(obj, sobj)
            updateSystemObjectImpl(obj, sobj);
            sobj.MeasurementRange            = obj.MeasurementRange;
            sobj.Resolution                  = obj.Resolution;
            sobj.ConstantBias                = obj.ConstantBias;
            sobj.AxesMisalignment            = obj.AxesMisalignment;
            sobj.NoiseDensity                = obj.NoiseDensity;
            sobj.BiasInstability             = obj.BiasInstability;
            sobj.RandomWalk                  = obj.RandomWalk;
            sobj.BiasInstabilityCoefficients = obj.BiasInstabilityCoefficients;
            sobj.NoiseType                   = obj.NoiseType;
            sobj.TemperatureBias             = obj.TemperatureBias;
            sobj.TemperatureScaleFactor      = obj.TemperatureScaleFactor;            
        end
    end
    
    methods (Access = protected)
        function rowVectProp = getRowVector(obj, prop)
            if isscalar(obj.(prop))
                rowVectProp = repmat(obj.(prop), 1, 3);
            else
                rowVectProp = obj.(prop);
            end
        end
    end
    
    methods (Static, Access = protected)
        function validateSize(val, prop)
            % Check that val is a scalar or a 3-element row vector.
            cond = any([1 1] ~= size(val)) && any([1 3] ~= size(val));
            coder.internal.errorIf(cond, 'shared_positioning:internal:IMUSensorParameters:invalidSize', prop);
        end
    end
end
