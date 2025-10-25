classdef (Hidden) IMUSensorSimulator < fusion.internal.PositioningSystemBase 
%   Base class for AccelerometerSimulator, AccelerometerSimulator, and 
%   MagnetometerSimulator. 
%
%   This class is used to calculate sensor output values based on ideal
%   input and model parameters.
%
%   This class is for internal use only. It may be removed in the future.

%   Copyright 2017-2023 The MathWorks, Inc.
    
%#codegen

    properties (Nontunable)
        % SampleRate Sampling rate (Hz)
        % Specify the sampling frequency of the sensor as a positive scalar. 
        % The default value is 100. 
        SampleRate = 100;
    end
    
    properties
        % MeasurementRange Maximum sensor reading
        % Specify the maximum sensor reading as a real positive scalar. 
        % This property is tunable. The default value is Inf.
        MeasurementRange = Inf;
        % Resolution Resolution of sensor measurements
        % Specify the resolution as a real nonnegative scalar. This 
        % property is tunable. The default value is 0.
        Resolution = 0;
        % ConstantBias Constant sensor offset bias
        % Specify the constant bias as a real 3-element row vector. This 
        % property is tunable. The default value is [0 0 0].
        ConstantBias = [0 0 0];
        % AxesMisalignment Sensor axes skew (%)
        % Specify the axes misalignment as a 3-by-3 matrix with values
        % between 0 and 100, inclusive. The default value is 100*eye(3).
        AxesMisalignment = 100*eye(3);
        % NoiseDensity Power spectral density of sensor noise
        % Specify the noise density as a real 3-element row vector. This 
        % property is tunable. The default value is [0 0 0].
        NoiseDensity = [0 0 0];
        % BiasInstability Instability of the bias offset
        % Specify the bias instability as a real 3-element row vector. This
        % property is tunable. The default value is [0 0 0].
        BiasInstability = [0 0 0];
        % RandomWalk Integrated white noise of sensor
        % Specify the random walk as a real scalar or 3-element row vector.
        % The default value is [0 0 0];
        RandomWalk = [0 0 0];
        % BiasInstabilityCoefficients Bias instability filter coefficients
        % Specify the coefficients as a struct with "Numerator" and
        % "Denominator" fields. Both fields contain vectors of
        % coefficients. The default value is fractalcoef().
        BiasInstabilityCoefficients (1,1) struct = fractalcoef;
        % NoiseType Type of sensor noise bandwidth
        % Specify the noise type as either "double-sided" or 
        % "single-sided". The default value is "double-sided".
        NoiseType = "double-sided";
        % TemperatureBias Sensor bias from temperature
        % Specify the temperature bias as a real 3-element row vector. This
        % property is tunable. The default value is [0 0 0].
        TemperatureBias = [0 0 0];
        % TemperatureScaleFactor Scale factor error from temperature (%)
        % Specify the temperature scale factor error as a real 3-element 
        % row vector with values between 0 and 100, inclusive.
        % This property is tunable. The default value is [0 0 0].
        TemperatureScaleFactor = [0 0 0];

        % Temperature Temperature of sensor (degrees C)
        % Specify the operating temperature of the sensor as a real scalar. 
        % This property is tunable. The default value is 25.
        Temperature = 25;
    end
    
    properties (Constant, Hidden)
        NumChannels = 3;

        pStandardTemperature = 25; 
    end
    
    properties (Nontunable, Access = protected)
        % Cached input datatype. 
        pDataType;
    end

    properties (Access = protected)
        % Cached sensor parameters. 
        pBandwidth;
        pCorrelationTime;
    end
    
    properties (Access = protected)
        % Sensor bias instability filter parameters.
        pBiasInstFilterNum;
        pBiasInstFilterDen;
        pBiasInstFilterStates;
        pStdDevBiasInst;

        % Sensor white noise parameters. 
        pStdDevWhiteNoise;
        
        % Sensor random walk filter parameters.
        pRandWalkFilterStates;
        pStdDevRandWalk;
        
        % Cached sensor parameters (used in bulk model). 
        pGain;
    end
    
    methods
        % Constructor
        function obj = IMUSensorSimulator(varargin)
            setProperties(obj,nargin,varargin{:});
        end
    end
    
    methods (Access = protected)

        function s = saveObjectImpl(obj)
            % Save public properties.
            s = saveObjectImpl@matlab.System(obj);

            % Save private properties. 
            if isLocked(obj)
                s.pDataType             = obj.pDataType;
                s.pBiasInstFilterNum    = obj.pBiasInstFilterNum;
                s.pBiasInstFilterDen    = obj.pBiasInstFilterDen;
                s.pBiasInstFilterStates = obj.pBiasInstFilterStates;
                s.pStdDevBiasInst       = obj.pStdDevBiasInst;
                s.pStdDevWhiteNoise     = obj.pStdDevWhiteNoise;
                s.pRandWalkFilterStates = obj.pRandWalkFilterStates;
                s.pStdDevRandWalk       = obj.pStdDevRandWalk;
                s.pGain                 = obj.pGain;
                s.pBandwidth            = obj.pBandwidth;
                s.pCorrelationTime      = obj.pCorrelationTime;
            end
        end

        function loadObjectImpl(obj, s, wasLocked)
            % Load public properties. 
            loadObjectImpl@matlab.System(obj, s, wasLocked)

            % Load private properties. 
            if wasLocked
                obj.pDataType             = s.pDataType;
                obj.pBiasInstFilterNum    = s.pBiasInstFilterNum;
                obj.pBiasInstFilterDen    = s.pBiasInstFilterDen;
                obj.pBiasInstFilterStates = s.pBiasInstFilterStates;
                obj.pStdDevBiasInst       = s.pStdDevBiasInst;
                obj.pStdDevWhiteNoise     = s.pStdDevWhiteNoise;
                obj.pRandWalkFilterStates = s.pRandWalkFilterStates;
                obj.pStdDevRandWalk       = s.pStdDevRandWalk;
                obj.pGain                 = s.pGain;
                obj.pBandwidth            = s.pBandwidth;
                obj.pCorrelationTime      = s.pCorrelationTime;
            end
        end

%-------------------------Setup Methods Begin------------------------------    

        function setupImpl(obj, idealSensorData, ~, ~)
            obj.pDataType = class(idealSensorData);
            
            setupBulkModel(obj);
            setupRandomDriftModel(obj);  
        end

        function setupBulkModel(obj)
            obj.pGain = obj.AxesMisalignment/100;
        end

        function setupRandomDriftModel(obj)
            setupBandwidth(obj);

            setupBiasInstabilityDrift(obj);
            setupWhiteNoiseDrift(obj);
            setupRandomWalkDrift(obj)
        end

        function setupBandwidth(obj)
            if (obj.NoiseType == "double-sided")
                obj.pBandwidth = cast(obj.SampleRate/2,obj.pDataType);
            else % (obj.NoiseType == "single-sided")
                obj.pBandwidth = cast(obj.SampleRate, obj.pDataType);
            end
        end

        function setupBiasInstabilityDrift(obj)
            dt = cast(1/obj.SampleRate,obj.pDataType);
            % Default correlation time value to make decay factor 1/2.
            correlationTime = cast(2.*dt,obj.pDataType);

            stateLength = setupBiasInstabilityDriftFilter(obj);
            obj.pBiasInstFilterStates = zeros(stateLength, obj.NumChannels, obj.pDataType);

            obj.pCorrelationTime = correlationTime;
            setStdDevBiasInst(obj);
        end

        function stateLength = setupBiasInstabilityDriftFilter(obj)
            coeffs = obj.BiasInstabilityCoefficients;
            obj.pBiasInstFilterNum = cast(coeffs.Numerator, obj.pDataType);
            obj.pBiasInstFilterDen = cast(coeffs.Denominator, obj.pDataType);
            stateLength = max(length(coeffs.Numerator), length(coeffs.Denominator))-1;
        end

        function setupWhiteNoiseDrift(obj) 
            setStdDevWhiteNoise(obj);
        end
        
        function setupRandomWalkDrift(obj)
            obj.pRandWalkFilterStates = zeros(1, obj.NumChannels, obj.pDataType);
            setStdDevRandWalk(obj);
        end

%-------------------------Setup Methods End--------------------------------

%-------------------------setStdDev Methods Begin--------------------------

        function setStdDevBiasInst(obj)
            % Gauss-Markov Standard Deviation
            %     sqrt(2/(ts*tau))*BiasInstability * ts
            obj.pStdDevBiasInst = ...
                cast(sqrt(2./(obj.SampleRate.*obj.pCorrelationTime)) ...
                .* obj.BiasInstability, obj.pDataType);
        end
        
        function setStdDevWhiteNoise(obj)
            obj.pStdDevWhiteNoise = cast(sqrt(obj.pBandwidth) .* obj.NoiseDensity, ...
                obj.pDataType);
        end
        
        function setStdDevRandWalk(obj)
            obj.pStdDevRandWalk = cast(obj.RandomWalk ./ sqrt(obj.pBandwidth), ...
                obj.pDataType);
        end

%-------------------------setStdDev Methods End----------------------------

%-------------------------Step Methods Begin-------------------------------        
        
        function out = stepImpl(obj,idealSensorData, orientationRotMats, randNums)
            numSamples = size(idealSensorData,1);
            
            for i=1:numSamples
                idealSensorData(i,:) = (orientationRotMats(:,:,i) * idealSensorData(i,:).').';
            end
            
            B = stepBulkModel(obj,idealSensorData);
            
            D = stepRandomDriftModel(obj, randNums) ...
                + stepEnvironmentalDriftModel(obj,numSamples);
            
            scaleFactorError = stepScaleFactorErrorModel(obj,numSamples);
            
            continuousOutput = scaleFactorError .* (B + D);
            
            out = stepQuantizationModel(obj,continuousOutput);
        end

        function out = stepBulkModel(obj,in)
            out = bsxfun(@plus, (obj.pGain * in.').', obj.ConstantBias);
        end

        function randomDrift = stepRandomDriftModel(obj, randNums)
            idx = 1:obj.NumChannels;
            
            biasInstDrift = stepBiasInstabilityDrift(obj, randNums(:,idx));
            
            idx = idx + obj.NumChannels;
            
            whiteNoiseDrift = stepWhiteNoiseDrift(obj, randNums(:,idx));
            
            idx = idx + obj.NumChannels;
            
            randomWalkDrift = stepRandomWalkDrift(obj, randNums(:,idx));

            randomDrift = whiteNoiseDrift + biasInstDrift + randomWalkDrift;
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
        
        function randWalkDrift = stepRandomWalkDrift(obj, randNums)
            x = vertcat(obj.pRandWalkFilterStates, ...
                bsxfun(@times, randNums, obj.pStdDevRandWalk));
            y = cumsum(x, 1);
            randWalkDrift = y(2:end,:);
            obj.pRandWalkFilterStates = y(end,:);
        end

        function envDrift = stepEnvironmentalDriftModel(obj,numSamples)
            temperatureDrift = repmat( ...
                (obj.Temperature-obj.pStandardTemperature) ...
                .* obj.TemperatureBias, ...
                numSamples, 1 );
            envDrift = temperatureDrift;
        end
        
        function scaleFactorError = stepScaleFactorErrorModel(obj,numSamples)
            scaleFactorError = repmat(1 ...
                + (obj.Temperature-obj.pStandardTemperature) .* (1e-2) ...
                .* obj.TemperatureScaleFactor, ...
                numSamples, 1);
        end
        
        function out = stepQuantizationModel(obj, in)
            dataType = obj.pDataType;
            out = in;
            % Saturate to measurement range and round to resolution. 
            if ~isinf(obj.MeasurementRange) 
                maximum = cast(obj.MeasurementRange, dataType);
                out(abs(out) > maximum) = ...
                    sign(out(abs(out) > maximum)) .* maximum;
            end
            if (obj.Resolution ~= 0)
                sensitivity = cast(obj.Resolution, dataType);
                out = sensitivity .* round(out ./ sensitivity);
            end
        end
        
%-------------------------Step Methods End---------------------------------

        function processTunedPropertiesImpl(obj)
            if isChangedProperty(obj, 'AxesMisalignment')
                setupBulkModel(obj);
            end
            if isChangedProperty(obj, 'NoiseDensity') ...
                || isChangedProperty(obj, 'NoiseType')
                setupBandwidth(obj);
                setStdDevWhiteNoise(obj);
            end
            if isChangedProperty(obj, 'BiasInstability')
                setStdDevBiasInst(obj);              
            end
            if isChangedProperty(obj, 'RandomWalk') ...
                || isChangedProperty(obj, 'NoiseType')
                setupBandwidth(obj);
                setStdDevRandWalk(obj);
            end
            if isChangedProperty(obj, 'BiasInstabilityCoefficients')
                stateLength = setupBiasInstabilityDriftFilter(obj);
                prevStateLength = size(obj.pBiasInstFilterStates, 1);
                if (stateLength ~= prevStateLength)
                    obj.pBiasInstFilterStates = zeros(stateLength, obj.NumChannels, obj.pDataType);
                end
            end
        end

%-------------------------Reset Methods Begin------------------------------

        function resetImpl(obj)
            resetBiasInstabilityDrift(obj);
            resetRandomWalkDrift(obj);
        end

        function resetBiasInstabilityDrift(obj)
            obj.pBiasInstFilterStates = zeros( ...
                size(obj.pBiasInstFilterStates), ...
                'like', obj.pBiasInstFilterStates);
        end
        
        function resetRandomWalkDrift(obj)
            obj.pRandWalkFilterStates = zeros( ...
                size(obj.pRandWalkFilterStates), ...
                'like', obj.pRandWalkFilterStates);
        end

%-------------------------Reset Methods End--------------------------------        
    end
       
end
