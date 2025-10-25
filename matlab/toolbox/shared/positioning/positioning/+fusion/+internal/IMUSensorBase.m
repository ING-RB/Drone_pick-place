classdef IMUSensorBase < fusion.internal.PositioningSystemBase
%   This class is for internal use only. It may be removed in the future.  
%IMUSENSORBASE Common base class for MATLAB and Simulink IMU Sensors

    %   Copyright 2019-2023 The MathWorks, Inc.
    
    %#codegen
    
    properties (Nontunable)
        % IMUType Type of inertial measurement unit
        % Specify the IMU type as one of 'accel-gyro' | 'accel-mag' |
        % 'accel-gyro-mag'. The default value is 'accel-gyro'.
        IMUType = 'accel-gyro';
    end
    
    properties
        % Temperature Temperature of IMU (degrees C)
        % Specify the operating temperature of the IMU as a real scalar.
        % This property is tunable. The default value is 25.
        Temperature = 25;
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
    
    properties (Constant, Hidden)
        RandomStreamSet = matlab.system.StringSet({...
            'Global stream', ...
            'mt19937ar with seed'});
        IMUTypeSet = matlab.system.StringSet({...
            'accel-gyro', ...
            'accel-mag', ...
            'accel-gyro-mag'});
        ReferenceFrameSet = matlab.system.StringSet( ...
            fusion.internal.frames.ReferenceFrame.getOptions);
    end
    
    properties (Nontunable, Hidden)
        ReferenceFrame = fusion.internal.frames.ReferenceFrame.getDefault;
    end
    
    properties (Nontunable, Access = protected)
        % Cached reference frame.
        pRefFrame;
    end
    
    properties (Access = private)
        % Random stream object (used in 'mt19937ar with seed' mode).
        pStream;
        % Random number generator state.
        pStreamState;
    end
    
    properties (Constant, Access = protected)
        pNumRandomChannelsPerSensor = 9;
    end
    
    properties (Nontunable, Access = protected)
        % Cached number of random channels needed.
        pNumRandomChannels;
    end
    
    properties (Access = protected)
        % Internal System objects to execute each sensor model.
        pAccel;
        pGyro;
        pMag;
    end
    
    methods( Abstract, Access =protected)
        val = hasGyro(obj)
        val = hasMag(obj)
    end
    
    % Set methods
    methods
        function set.Temperature(obj, val)
            validateattributes(val,{'single','double'}, ...
                {'real','scalar','finite'}, ...
                '', ...
                'Temperature');
            obj.Temperature = val;
        end
        
        function set.Seed(obj, val)
            validateattributes(val,{'numeric'}, ...
                {'real','scalar','integer','>=',0,'<',2^32}, ...
                '', ...
                'Seed');
            obj.Seed = uint32(val);
        end
    end
    
    methods (Access = protected)
        
        function setupRandomStream(obj)
            numSensors = 1 + hasGyro(obj) + hasMag(obj);
            obj.pNumRandomChannels = numSensors ...
                * obj.pNumRandomChannelsPerSensor;
            
            if strcmp(obj.RandomStream,  'mt19937ar with seed') ...
                    && isempty(coder.target)
                % Setup Random Stream object if required.
                obj.pStream = RandStream('mt19937ar', 'seed', obj.Seed);
            end
        end
        
        function varargout = stepImpl(obj, acceleration, angularvelocity, orientation)
            if (nargin < 4)
                R = repmat(eye(3), 1, 1, size(acceleration, 1));
            elseif isa(orientation, 'quaternion')
                R = rotmat(orientation, 'frame');
            else
                R = orientation;
            end
            
            numSamples = size(R, 3);
            numRandomChannelsPerSensor = obj.pNumRandomChannelsPerSensor;
            sensorIdx = 1:numRandomChannelsPerSensor;
            randNums = stepRandomStream(obj, numSamples);
            
            argoutIdx = 1;
            varargout{argoutIdx} = step(obj.pAccel, acceleration, R, randNums(:,sensorIdx));
            argoutIdx = argoutIdx + 1;
            sensorIdx = sensorIdx + numRandomChannelsPerSensor;
            
            if hasGyro(obj)
                varargout{argoutIdx} = step(obj.pGyro, angularvelocity, acceleration, R, randNums(:,sensorIdx));
                argoutIdx = argoutIdx + 1;
                sensorIdx = sensorIdx + numRandomChannelsPerSensor;
            end
            if hasMag(obj)
                if isa(R, 'single') || isa(acceleration, 'single') ...
                        || isa(angularvelocity, 'single')
                    dataType = 'single';
                else
                    dataType = 'double';
                end
                magneticfield = cast(repmat(obj.MagneticField,numSamples,1),dataType);
                varargout{argoutIdx} = step(obj.pMag, magneticfield, R, randNums(:,sensorIdx));
            end
        end
        
        function whiteNoise = stepRandomStream(obj, numSamples)
            % Noise (random number) generation.
            if strcmp(obj.RandomStream, 'Global stream')
                whiteNoise = randn(obj.pNumRandomChannels, numSamples).';
            elseif isempty(coder.target)
                whiteNoise = randn(obj.pStream, obj.pNumRandomChannels, ...
                    numSamples).';
            else
                allRandData = coder.nullcopy(zeros(numSamples,...
                    obj.pNumRandomChannels));
                state = obj.pStreamState;
                for rowIdx = 1:numSamples
                    % Noise is generated column-wisely
                    for colIdx = 1:obj.pNumRandomChannels
                        [state, allRandData(rowIdx, colIdx)] = ...
                            eml_rand_mt19937ar('generate_normal', state);
                    end
                end
                obj.pStreamState = state;
                
                whiteNoise = allRandData;
            end
        end
        
        function resetImpl(obj)
            resetRandomStream(obj);
            
            if isLocked(obj)
                reset(obj.pAccel);
                
                if hasGyro(obj)
                    reset(obj.pGyro);
                end
                if hasMag(obj)
                    reset(obj.pMag);
                end
            end
        end
        
        function resetRandomStream(obj)
            if ~isempty(coder.target)
                obj.pStreamState = eml_rand_mt19937ar('preallocate_state');
                if strcmp(obj.RandomStream, 'mt19937ar with seed')
                    obj.pStreamState = ...
                        eml_rand_mt19937ar('seed_to_state', ...
                        obj.pStreamState, obj.Seed);
                end
            elseif strcmp(obj.RandomStream, 'mt19937ar with seed')
                obj.pStream.reset;
            end
        end
        
        
        
        function flag = isInputComplexityMutableImpl(~, ~)
            flag = false;
        end
        
        function s = saveObjectImpl(obj)
            % Save public properties.
            s = saveObjectImpl@matlab.System(obj);
            
            % Save private properties.
            if isLocked(obj)
                s.pNumRandomChannels = obj.pNumRandomChannels;
                s.pRefFrame = obj.pRefFrame;
                
                s.pAccel = matlab.System.saveObject(obj.pAccel);
                if hasGyro(obj)
                    s.pGyro  = matlab.System.saveObject(obj.pGyro);
                end
                if hasMag(obj)
                    s.pMag   = matlab.System.saveObject(obj.pMag);
                end
                
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
                obj.pNumRandomChannels = s.pNumRandomChannels;
                obj.pRefFrame = s.pRefFrame;
                
                obj.pAccel = matlab.System.loadObject(s.pAccel);
                if hasGyro(obj)
                    obj.pGyro = matlab.System.loadObject(s.pGyro);
                end
                if hasMag(obj)
                    obj.pMag = matlab.System.loadObject(s.pMag);
                end
                
                if strcmp(s.RandomStream, 'mt19937ar with seed')
                    obj.pStream = RandStream('mt19937ar', ...
                        'seed', obj.Seed);
                    if ~isempty(s.pStreamState)
                        obj.pStream.State = s.pStreamState;
                    end
                end
            end
        end
        
        function initializeMagneticField(obj)
            %INITIALIZEMAGNETICFIELD Set the MagneticField based on the
            %   reference frame.
            
            magFieldNED = defaultMagFieldNED;
            magFieldNorth = magFieldNED(1);
            magFieldEast = magFieldNED(2);
            magFieldDown = magFieldNED(3);
            
            refFrame = fusion.internal.frames.ReferenceFrame.getMathObject( ...
                obj.ReferenceFrame);
            magField = zeros(1,3);
            magField(refFrame.NorthIndex) = magFieldNorth;
            magField(refFrame.EastIndex) = magFieldEast;
            magField(3) = -refFrame.ZAxisUpSign * magFieldDown;
            
            obj.MagneticField = magField;
        end
      
    end
    
    methods (Hidden)
        function sensorsim = getSensorSimulator(obj, name)
            %This method is for internal use only. It may be removed in the
            % future.
            
            % Extract the underlying System object for an individual
            % sensor to verify tunable parameters have been updated.
            validateattributes(name, {'char'}, {'row'});
            sensorsim = [];
            if isLocked(obj)
                processTunedPropertiesImpl(obj);
                switch lower(name)
                    case 'accelerometer'
                        sensorsim = obj.pAccel;
                    case 'gyroscope'
                        sensorsim = obj.pGyro;
                    case 'magnetometer'
                        sensorsim = obj.pMag;
                end
            end
        end
    end
end

function mfNED = defaultMagFieldNED
mfNED = fusion.internal.ConstantValue.MagneticFieldNED;
end
