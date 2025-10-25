classdef (Hidden) AltimeterSensorBase < fusion.internal.PositioningSystemBase 
%ALTIMETERSENSORBASE - Base class for altimeterSensor
%
%   This class is for internal use only. It may be removed in the future.

%   Copyright 2018-2020 The MathWorks, Inc.

%#codegen

    properties (Nontunable)
        % SampleRate Sampling rate (Hz)
        % Specify the sampling rate of the altimeter sensor as a positive 
        % scalar. The default value is 1.
        SampleRate = 1;
    end
    
    properties
        % ConstantBias Constant offset bias (m)
        % Specify the constant bias of the sensor as a real scalar in 
        % meters. This property is tunable. The default value is 0.
        ConstantBias = 0;
        % NoiseDensity Power spectral density of sensor noise (m/sqrt(Hz))
        % Specify the noise density as a real scalar. This property is
        % tunable. The default value is 0.
        NoiseDensity = 0;
        % BiasInstability Instability of the bias offset (m)
        % Specify the bias instability as a real scalar in meters. This
        % property is tunable. The default value is 0.
        BiasInstability = 0;
        % DecayFactor Bias instability noise decay factor
        % Specify the bias instability noise decay factor as a real scalar
        % with a value between 0 and 1, inclusive. A decay factor of 0
        % models the bias instability noise as a white noise process. A
        % decay factor of 1 models the bias instability noise as a random
        % walk process. This property is tunable. The default value is 0.
        DecayFactor = 0;
    end
    
    properties (Nontunable)
        % RandomStream Random number source
        % Specify the source of the random number stream as one of the
        % following:
        %
        % 'Global stream' - Random numbers are generated using the current
        % global random number stream.
        % 'mt19937ar with seed' - Random numbers are generated using the
        % mt19937ar algorithm with the seed specified by the Seed property.
        %
        % The default value is 'Global stream'.
        RandomStream = 'Global stream';
        % Seed Initial seed
        % Specify the initial seed of an mt19937ar random number generator
        % algorithm as a real, nonnegative integer scalar. This property
        % applies when you set the RandomStream property to
        % 'mt19937ar with seed'. The default value is 67.
        Seed = uint32(67);
    end

    properties (Hidden, Dependent)
        % UpdateRate Update rate (Hz)
        % Specify the update rate of the altimeter sensor as a positive 
        % scalar. The default value is 1. This is equivalent to the 
        % SampleRate property.
        UpdateRate;
    end
    
    properties (Constant, Hidden)
        RandomStreamSet = matlab.system.StringSet({...
            'Global stream', ...
            'mt19937ar with seed'});
        ReferenceFrameSet = matlab.system.StringSet( ...
            fusion.internal.frames.ReferenceFrame.getOptions);
    end
    
    properties (Nontunable, Hidden)
        ReferenceFrame = fusion.internal.frames.ReferenceFrame.getDefault;
    end
    
    properties (Nontunable, Access = private)
        % Cached input datatype.
        pDataType;
        % Cached z-axis sign relative to up.
        pZAxisUpSign;
    end
    
    properties (Access = private)
        % Random stream object (used in 'mt19937ar with seed' mode).
        pStream;
        % Random number generator state.
        pStreamState;
        
        % Sensor bias instability filter parameters.
        pBiasInstFilterNum;
        pBiasInstFilterDen;
        pBiasInstFilterStates;
        pStdDevBiasInst;

        % Sensor white noise parameters. 
        pStdDevWhiteNoise;
    end
    
    % Get/Set methods
    methods
        function val = get.UpdateRate(obj)
            val = obj.SampleRate;
        end
        function set.UpdateRate(obj, val)
            obj.SampleRate = val;
        end
        function set.SampleRate(obj, val)
            validateattributes(val, {'double','single'}, ...
                {'real','scalar','positive','finite'}, ...
                '', ...
                'SampleRate');
            obj.SampleRate = val;
        end
        function set.ConstantBias(obj, val)
            validateattributes(val, {'double','single'}, ...
                {'real','scalar','finite'}, ...
                '', ...
                'ConstantBias');
            obj.ConstantBias = val;
        end
        function set.NoiseDensity(obj, val)
            validateattributes(val, {'double','single'}, ...
                {'real','scalar','nonnegative','finite'}, ...
                '', ...
                'NoiseDensity');
            obj.NoiseDensity = val;
        end
        function set.BiasInstability(obj, val)
            validateattributes(val, {'double','single'}, ...
                {'real','scalar','nonnegative','finite'}, ...
                '', ...
                'BiasInstability');
            obj.BiasInstability = val;
        end
        function set.DecayFactor(obj, val)
            validateattributes(val, {'double','single'}, ...
                {'real','scalar','>=',0,'<=',1}, ...
                '', ...
                'DecayFactor');
            obj.DecayFactor = val;
        end
        function set.Seed(obj, val)
            validateattributes(val, {'numeric'}, ...
                {'real','scalar','integer','>=',0,'<',2^32}, ...
                '', ...
                'Seed');
            obj.Seed = uint32(val);
        end
    end
    
    methods
        % Constructor
        function obj = AltimeterSensorBase(varargin)
            setProperties(obj, nargin, varargin{:});
        end
    end
    
    methods (Access = protected)
        function setStdDevBiasInst(obj)
            obj.pStdDevBiasInst = ...
                cast(sqrt(2*(1-obj.DecayFactor)) ...
                .* obj.BiasInstability, obj.pDataType);
        end
        
        function setStdDevWhiteNoise(obj)
            obj.pStdDevWhiteNoise = cast(sqrt(obj.SampleRate/2) .* obj.NoiseDensity, ...
                obj.pDataType);
        end
        
        function setupRandomStream(obj)
            % Setup Random Stream object if required.
            if strcmp(obj.RandomStream, 'mt19937ar with seed')
                if isempty(coder.target)
                    obj.pStream = RandStream('mt19937ar', 'seed', obj.Seed);
                else
                    obj.pStream = coder.internal.RandStream('mt19937ar', 'seed', obj.Seed);
                end
            end
        end
        
        function setupBiasInstabilityDrift(obj)
            obj.pBiasInstFilterStates = cast(0, obj.pDataType);
            resetBiasInstabilityDriftNoise(obj);

            setStdDevBiasInst(obj);
        end
        
        function setupWhiteNoiseDrift(obj)
            setStdDevWhiteNoise(obj);
        end
        
        function setupImpl(obj, pos)
            obj.pDataType = class(pos);
            setupRandomStream(obj);
            setupBiasInstabilityDrift(obj);
            setupWhiteNoiseDrift(obj);
            obj.pZAxisUpSign = ...
                fusion.internal.frames.ReferenceFrame.getMathObject( ...
                obj.ReferenceFrame).ZAxisUpSign;
        end
        
        function noise = stepRandomStream(obj, numSamples)
            % Noise (random number) generation.
            if strcmp(obj.RandomStream, 'Global stream')
                noise = randn(numSamples, 1);
            else
                noise = randn(obj.pStream, numSamples, 1);
            end
        end
        
        function biasInstDrift = stepBiasInstabilityDrift(obj, randNums)
            [biasInstDrift, obj.pBiasInstFilterStates] = ...
                filter(obj.pBiasInstFilterNum, obj.pBiasInstFilterDen, ...
                bsxfun(@times, randNums, obj.pStdDevBiasInst), ...
                obj.pBiasInstFilterStates, 1);
        end
        
        function whiteNoiseDrift = stepWhiteNoiseDrift(obj , randNums)
            whiteNoiseDrift = bsxfun(@times, randNums, obj.pStdDevWhiteNoise);
        end
        
        function alt = stepImpl(obj, pos)
            numSamples = size(pos, 1);
            posDrift = cast(0, obj.pDataType);
            
            randNums = stepRandomStream(obj, numSamples);
            posDrift = posDrift + stepWhiteNoiseDrift(obj, randNums);
            randNums = stepRandomStream(obj, numSamples);
            posDrift = posDrift + stepBiasInstabilityDrift(obj, randNums);
            
            zsign = obj.pZAxisUpSign;
            alt = zsign .* pos(:,3) + obj.ConstantBias + posDrift;
        end
        
        function validateInputsImpl(~, pos)
            validateattributes(pos, {'double', 'single'}, ...
                {'real', 'finite', '2d', 'ncols', 3});
        end
        
        function processTunedPropertiesImpl(obj)
            if isChangedProperty(obj, 'NoiseDensity')
                setStdDevWhiteNoise(obj);
            end
            if isChangedProperty(obj, 'BiasInstability')
                setStdDevBiasInst(obj);              
            end
            if isChangedProperty(obj, 'DecayFactor')
                resetBiasInstabilityDriftNoise(obj);
            end 
        end
        
        function resetRandomStream(obj)
            if strcmp(obj.RandomStream, 'mt19937ar with seed')
                obj.pStream.reset;
            end
        end
        
        function resetBiasInstabilityDriftNoise(obj)
            obj.pBiasInstFilterNum = cast(1, obj.pDataType);
            obj.pBiasInstFilterDen = ...
                cast([1 -obj.DecayFactor], obj.pDataType);
        end
        
        function resetBiasInstabilityDriftStates(obj)
            obj.pBiasInstFilterStates = zeros( ...
                size(obj.pBiasInstFilterStates), ...
                'like', obj.pBiasInstFilterStates);
        end
        
        function resetBiasInstabilityDrift(obj)
            resetBiasInstabilityDriftNoise(obj);
            resetBiasInstabilityDriftStates(obj);
        end
        
        function resetImpl(obj)
            resetRandomStream(obj);
            resetBiasInstabilityDrift(obj);
        end
        
        function flag = isInputComplexityMutableImpl(~, ~)
            flag = false;
        end
        
        function s = saveObjectImpl(obj)
            % Save public properties.
            s = saveObjectImpl@matlab.System(obj);
            
            % Save private properties.
            if isLocked(obj)
                s.pDataType = obj.pDataType;
                s.pBiasInstFilterNum = obj.pBiasInstFilterNum;
                s.pBiasInstFilterDen = obj.pBiasInstFilterDen;
                s.pBiasInstFilterStates = obj.pBiasInstFilterStates;
                s.pStdDevBiasInst = obj.pStdDevBiasInst;
                s.pStdDevWhiteNoise = obj.pStdDevWhiteNoise;
                s.pZAxisUpSign = obj.pZAxisUpSign;
                
                if strcmp(obj.RandomStream, 'mt19937ar with seed')
                    if ~isempty(obj.pStream)
                        s.pStreamState = obj.pStream.State;
                    end
                end
            end
        end
        
        function loadObjectImpl(obj, s, wasLocked)
            % Load public properties.
            loadObjectImpl@matlab.System(obj, s, wasLocked);
            
            % Load private properties.
            if wasLocked
                obj.pDataType = s.pDataType;
                obj.pBiasInstFilterNum = s.pBiasInstFilterNum;
                obj.pBiasInstFilterDen = s.pBiasInstFilterDen;
                obj.pBiasInstFilterStates = s.pBiasInstFilterStates;
                obj.pStdDevBiasInst = s.pStdDevBiasInst;
                obj.pStdDevWhiteNoise = s.pStdDevWhiteNoise;
                obj.pZAxisUpSign = s.pZAxisUpSign;
                
                if strcmp(s.RandomStream, 'mt19937ar with seed')
                    obj.pStream = RandStream('mt19937ar', ...
                        'seed', obj.Seed);
                    if ~isempty(s.pStreamState)
                        obj.pStream.State = s.pStreamState;
                    end
                end
            end
        end
        
        function flag = isInactivePropertyImpl(obj, prop)
            flag = false;
            if strcmp(prop, 'Seed')
                if strcmp(obj.RandomStream, 'Global stream')
                    flag = true;
                end
            end
        end
    end
end
