classdef imuSensor < fusion.internal.IMUSensorBase & scenario.internal.mixin.Perturbable
%IMUSENSOR IMU measurements of accelerometer, gyroscope, and magnetometer
%   IMU = IMUSENSOR returns a System object, IMU, that computes an inertial 
%   measurement unit reading based on an inertial input signal. The 
%   IMUSENSOR System object has an ideal accelerometer and gyroscope.
%
%   IMU = IMUSENSOR(TYPE) returns an IMUSENSOR System object with the
%   IMUType property set to TYPE.
%
%   IMU = IMUSENSOR('accel-gyro') returns an IMUSENSOR System object with 
%   an ideal accelerometer and gyroscope.
%
%   IMU = IMUSENSOR('accel-mag') returns an IMUSENSOR System object with an 
%   ideal accelerometer and magnetometer.
%   
%   IMU = IMUSENSOR('accel-gyro-mag') returns an IMUSENSOR System object 
%   with an ideal accelerometer, gyroscope, and magnetometer.
%
%   IMU = IMUSENSOR(..., 'ReferenceFrame', RF) returns an IMUSENSOR System
%   object that computes an inertial measurement unit reading relative to
%   the reference frame RF. Specify the reference frame as 'NED'
%   (North-East-Down) or 'ENU' (East-North-Up). The default value is 'NED'.
%
%   IMU = IMUSENSOR(..., 'Name', Value, ...) returns an IMUSENSOR System 
%   object with each specified property name set to the specified value. 
%   You can specify additional name-value pair arguments in any order as 
%   (Name1,Value1,...,NameN, ValueN).
%   
%   Step method syntax:
%
%   [ACCEL, GYRO] = step(IMU, ACC, ANGVEL) computes accelerometer and
%   gyroscope readings from the acceleration (ACC) and angular velocity
%   (ANGVEL) inputs. This syntax is only valid if IMUType is set to 
%   'accel-gyro' or 'accel-gyro-mag'.
%
%   [ACCEL, GYRO] = step(IMU, ACC, ANGVEL, ORIENTATION) computes
%   accelerometer and gyroscope readings from the acceleration (ACC),
%   angular velocity (ANGVEL), and orientation (ORIENTATION) inputs. This 
%   syntax is only valid if IMUType is set to 'accel-gyro' or 
%   'accel-gyro-mag'.
%
%   [ACCEL, MAG] = step(IMU, ACC, ANGVEL) computes accelerometer and
%   magnetometer readings from the acceleration (ACC) and angular velocity
%   (ANGVEL) inputs. This syntax is only valid if IMUType is set to
%   'accel-mag'.
%
%   [ACCEL, MAG] = step(IMU, ACC, ANGVEL, ORIENTATION) computes
%   accelerometer and magnetometer readings from the acceleration (ACC),
%   angular velocity (ANGVEL), and orientation (ORIENTATION) inputs. This
%   syntax is only valid if IMUType is set to 'accel-mag'.
%
%   [ACCEL, GYRO, MAG] = step(IMU, ACC, ANGVEL) computes accelerometer,
%   gyroscope, and magnetometer readings from the acceleration (ACC) and
%   angular velocity (ANGVEL) inputs. This syntax is only valid if IMUType
%   is set to 'accel-gyro-mag'.
%
%   [ACCEL, GYRO, MAG] = step(IMU, ACC, ANGVEL, ORIENTATION) computes
%   accelerometer, gyroscope, and magnetometer readings from the
%   acceleration (ACC), angular velocity (ANGVEL), and orientation
%   (ORIENTATION) inputs. This syntax is only valid if IMUType is set to
%   'accel-gyro-mag'.
%
%   The inputs to IMUSENSOR are defined as follows: 
%
%       ACC            Acceleration of the IMU in the local navigation 
%                      coordinate system specified as a real finite N-by-3
%                      array in meters per second squared. N is the number
%                      of samples in the current frame.
%
%       ANGVEL         Angular velocity of the IMU in the local navigation 
%                      coordinate system specified as a real finite N-by-3 
%                      array in radians per second. N is the number of 
%                      samples in the current frame.
%
%       ORIENTATION    Orientation of the IMU with respect to the local
%                      navigation coordinate system specified as a
%                      quaternion N-element column vector or a single or
%                      double 3-3-N-element rotation matrix. Each
%                      quaternion or rotation matrix is a frame rotation
%                      from the local navigation coordinate system to the
%                      current IMU body coordinate system. N is the number
%                      of samples in the current frame.
%
%   The outputs of IMUSENSOR are defined as follows: 
%
%       ACCEL          Accelerometer measurement of the IMU in the local 
%                      sensor body coordinate system specified as a real 
%                      finite N-by-3 array in meters per second squared. N 
%                      is the number of samples in the current frame. 
%
%       GYRO           Gyroscope measurement of the IMU in the local sensor
%                      body coordinate system specified as a real finite 
%                      N-by-3 array in radians per second. N is the number 
%                      of samples in the current frame. 
%
%       MAG            Magnetometer measurement of the IMU in the local 
%                      sensor body coordinate system specified as a real 
%                      finite N-by-3 array in microteslas. N is the number 
%                      of samples in the current frame. 
%
%   Either single or double datatypes are supported for the inputs to 
%   IMUSENSOR. Outputs have the same datatype as the input.
%
%   System objects may be called directly like a function instead of using
%   the step method. For example, y = step(obj, x) and y = obj(x) are
%   equivalent.
%
%   IMUSENSOR methods:
%
%   step             - See above description for use of this method
%   perturbations    - Define perturbations to the IMUSENSOR
%   perturb          - Apply perturbations to the IMUSENSOR
%   release          - Allow property value and input characteristics to 
%                      change, and release IMUSENSOR resources
%   clone            - Create IMUSENSOR object with same property values
%   isLocked         - Display locked status (logical)
%   reset            - Reset the states of the IMUSENSOR
%   loadparams       - Load sensor parameters from json file
%
%   IMUSENSOR properties:
%
%   IMUType          - Type of inertial measurement unit
%   SampleRate       - Sample rate of sensor (Hz)
%   Temperature      - Temperature of imu (degrees C)
%   MagneticField    - Magnetic field vector in the navigation frame (uT)
%   Accelerometer    - Accelerometer sensor parameters
%   Gyroscope        - Gyroscope sensor parameters
%   Magnetometer     - Magnetometer sensor parameters
%   RandomStream     - Source of random number stream 
%   Seed             - Initial seed of mt19937ar random number 
%   
%   % EXAMPLE 1: Generate ideal IMU data from stationary input. 
% 
%   Fs = 100;
%   numSamples = 1000;
%   t = 0:1/Fs:(numSamples-1)/Fs;
% 
%   imu = imuSensor('accel-gyro-mag', 'SampleRate', Fs);
%   
%   acc = zeros(numSamples, 3);
%   angvel = zeros(numSamples, 3);
%   
%   [accelMeas, gyroMeas, magMeas] = imu(acc, angvel);
% 
%   subplot(3, 1, 1)
%   plot(t, accelMeas)
%   title('Accelerometer')
%   xlabel('s')
%   ylabel('m/s^2')
%   legend('x','y','z')
%   
%   subplot(3, 1, 2)
%   plot(t, gyroMeas)
%   title('Gyroscope')
%   xlabel('s')
%   ylabel('rad/s')
%   legend('x','y','z')
%   
%   subplot(3, 1, 3)
%   plot(t, magMeas)
%   title('Magnetometer')
%   xlabel('s')
%   ylabel('uT')
%   legend('x','y','z')
% 
%   % EXAMPLE 2: Generate noisy IMU data from a spinning trajectory.
% 
%   % To determine if an orientation filter is affected by gimbal lock, 
%   % first create a spinning trajectory that passes through the 
%   % singularity and then generate noisy IMU data from it. 
% 
%   Fs = 100;
%   numSamples = 1000;
%   t = 0:1/Fs:(numSamples-1)/Fs;
%   
%   orientation = quaternion.zeros(numSamples, 1);
%   acc = zeros(numSamples, 3);
%   angvel = deg2rad([0 20 0]) .* ones(numSamples, 3);
% 
%   q = quaternion(1, 0, 0, 0);
%   for i = 1:numSamples
%       orientation(i) = q;
%       dq = quaternion(angvel(i,:) ./ Fs, 'rotvec');
%       q = q .* dq;
%   end
% 
%   imu = imuSensor('accel-gyro-mag', 'SampleRate', Fs);
% 
%   % Typical noise values for MEMS sensors. 
%   imu.Accelerometer.MeasurementRange = 156.96;
%   imu.Accelerometer.Resolution = 0.0048;
%   imu.Accelerometer.ConstantBias = 0.5886;
%   imu.Accelerometer.AxesMisalignment = 2;
%   imu.Accelerometer.NoiseDensity = 0.0029;
%   imu.Accelerometer.TemperatureBias = 0.0147;
%   imu.Accelerometer.TemperatureScaleFactor = 0.026;
% 
%   imu.Gyroscope.MeasurementRange = deg2rad(2000);
%   imu.Gyroscope.Resolution = deg2rad(1/16.4);
%   imu.Gyroscope.ConstantBias = deg2rad(5);
%   imu.Gyroscope.AxesMisalignment = 2;
%   imu.Gyroscope.NoiseDensity = deg2rad(0.01);
%   imu.Gyroscope.TemperatureBias = deg2rad(30/125);
%   imu.Gyroscope.TemperatureScaleFactor = 4/125;
% 
%   imu.Magnetometer.MeasurementRange = 4800;
%   imu.Magnetometer.Resolution = 0.6;
%   imu.Magnetometer.ConstantBias = 500*0.6;
%   
%   accelMeas = zeros(numSamples, 3);
%   gyroMeas = zeros(numSamples, 3);
%   magMeas = zeros(numSamples, 3);
% 
%   for i = 1:numSamples
%       [accelMeas(i,:), gyroMeas(i,:), magMeas(i,:)] ...
%           = imu(acc(i,:), angvel(i,:), orientation(i,:));
%   end
% 
%   subplot(3, 1, 1)
%   plot(t, accelMeas)
%   title('Accelerometer')
%   xlabel('s')
%   ylabel('m/s^2')
%   legend('x','y','z')
% 
%   subplot(3, 1, 2)
%   plot(t, gyroMeas)
%   title('Gyroscope')
%   xlabel('s')
%   ylabel('rad/s')
%   legend('x','y','z')
% 
%   subplot(3, 1, 3)
%   plot(t, magMeas)
%   title('Magnetometer')
%   xlabel('s')
%   ylabel('uT')
%   legend('x','y','z')
%
%   See also ACCELPARAMS, GYROPARAMS, MAGPARAMS, GPSSENSOR, INSSENSOR

%   Copyright 2017-2021 The MathWorks, Inc.

%#codegen

    properties (Nontunable)
        % SampleRate Sampling rate (Hz)
        % Specify the sampling frequency of the IMU as a positive scalar. 
        % The default value is 100. 
        SampleRate = 100;
    end
    
    properties 
        % MagneticField Magnetic field vector (uT)
        % Specify the magnetic field as a real 3-element row vector in the
        % navigation frame. This property is tunable. The default value is
        % [27.5550 -2.4169 -16.0849].
        MagneticField = [ 27.5550 -2.4169 -16.0849];

        % Accelerometer Accelerometer sensor parameters
        % accelparams object containing accelerometer parameters
        % This property is tunable. 
        Accelerometer;

        % Gyroscope Gyroscope sensor parameters
        % gyroparams object containing gyroscope parameters.
        % This property is tunable. 
        Gyroscope; 
        
        % Magnetometer Magnetometer sensor parameters
        % magparams object containing magnetometer parameters.
        % This property is tunable. 
        Magnetometer;
    end

    % Default perturbable properties.
    properties (Access = private, Constant)
        DefaultAccelPerts = {"Accelerometer.MeasurementRange", ...
            "Accelerometer.Resolution", ...
            "Accelerometer.ConstantBias", ...
            "Accelerometer.NoiseDensity", ...
            "Accelerometer.BiasInstability", ...
            "Accelerometer.RandomWalk", ...
            "Accelerometer.TemperatureBias", ...
            "Accelerometer.TemperatureScaleFactor"}; %#ok<CLARRSTR>

        DefaultGyroPerts = {"Gyroscope.MeasurementRange", ...
            "Gyroscope.Resolution", ...
            "Gyroscope.ConstantBias", ...
            "Gyroscope.NoiseDensity", ...
            "Gyroscope.BiasInstability", ...
            "Gyroscope.RandomWalk", ...
            "Gyroscope.TemperatureBias", ...
            "Gyroscope.TemperatureScaleFactor", ...
            "Gyroscope.AccelerationBias"}; %#ok<CLARRSTR>
        
        DefaultMagPerts = {"Magnetometer.MeasurementRange", ...
            "Magnetometer.Resolution", ...
            "Magnetometer.ConstantBias", ...
            "Magnetometer.NoiseDensity", ...
            "Magnetometer.BiasInstability", ...
            "Magnetometer.RandomWalk", ...
            "Magnetometer.TemperatureBias", ...
            "Magnetometer.TemperatureScaleFactor"}; %#ok<CLARRSTR>
    end

    % Set methods
    methods
        function set.SampleRate(obj, val)
            validateattributes(val,{'single','double'}, ...
                {'real','scalar','positive','finite'}, ...
                '', ...
                'SampleRate');
            obj.SampleRate = val;
        end
        
        function set.Accelerometer(obj, val)
            coder.internal.errorIf(~isa(val, 'accelparams'), ...
                'shared_positioning:imuSensor:invalidType', ... 
                'Accelerometer', 'accelparams');
            coder.internal.errorIf(~isscalar(val), ...
            	'shared_positioning:imuSensor:expectedScalar', ...
                'Accelerometer');
            obj.Accelerometer = val;
        end
        
        function set.Gyroscope(obj, val)
            coder.internal.errorIf(~isa(val, 'gyroparams'), ...
            	'shared_positioning:imuSensor:invalidType', ...
                'Gyroscope', 'gyroparams');
            coder.internal.errorIf(~isscalar(val), ...
            	'shared_positioning:imuSensor:expectedScalar', ...
                'Gyroscope');
            obj.Gyroscope = val;
        end
        
        function set.Magnetometer(obj, val)
            coder.internal.errorIf(~isa(val, 'magparams'), ...
            	'shared_positioning:imuSensor:invalidType', ...
                'Magnetometer', 'magparams');
            coder.internal.errorIf(~isscalar(val), ...
            	'shared_positioning:imuSensor:expectedScalar', ...
                'Magnetometer');
            obj.Magnetometer = val;
        end

        function set.MagneticField(obj, val)
            validateattributes(val,{'single','double'}, ...
                {'real','size',[1,3],'finite'}, ...
                '', ...
                'MagneticField');
            obj.MagneticField = val;
        end
        
    end
    
   
    methods
        % Constructor
        function obj = imuSensor(varargin)
            setProperties(obj, nargin, varargin{:}, 'IMUType');
            isAccelSet = false;
            isGyroSet = false;
            isMagSet = false;
            isMagFieldSet = false;
            for i = 1:nargin
                if strcmp('Accelerometer', varargin{i})
                    isAccelSet = true;
                end
                if strcmp('Gyroscope', varargin{i})
                    isGyroSet = true;
                end
                if strcmp('Magnetometer', varargin{i})
                    isMagSet = true;
                end
                if strcmp('MagneticField', varargin{i})
                    isMagFieldSet = true;
                end
            end
            
            if ~isAccelSet
                obj.Accelerometer = accelparams();
            end
            if ~isGyroSet
                obj.Gyroscope = gyroparams();
            end
            if ~isMagSet
                obj.Magnetometer = magparams();
            end
            
            if isempty(coder.target) && ~isMagFieldSet
                initializeMagneticField(obj);
            end
        end
        
        function loadparams(obj, file, pn)
            % LOADPARAMS load sensor parameters from JSON file
            %   LOADPARAMS(OBJ, FILE, PN) configures the imuSensor object OBJ
            %   to match those of a part PN in a JSON file FILE.
            %
            %   Examples:
            %
            %       s = imuSensor;
            %       fn = fullfile(matlabroot, 'toolbox', 'shared', ...
            %           'positioning', 'positioningdata', 'generic.json');
            %
            %       % Configure as a 6-axis sensor
            %       loadparams(s, fn, 'GenericLowCost6Axis');
            %
            %       % Configure as a 9-axis sensor
            %       loadparams(s, fn, 'GenericLowCost9Axis');
            %
            %   See also ACCELPARAMS, GYROPARAMS, MAGPARAMS
            
            
            % Only load if unlocked
            assert( ~isLocked(obj),  ...
                (message('shared_positioning:imuSensor:unlockedLoad')));
        
            s = fusion.internal.SensorParamLoader.extractPartFromJSON(...
                file, pn);
            if isempty(s)
                error(message('shared_positioning:imuSensor:unknownPart', ...
                    pn, file));
            end
            hasAcc = isfield(s, 'Accelerometer');
            hasGyro = isfield(s, 'Gyroscope');
            hasMag = isfield(s, 'Magnetometer');
            
            % Build accelparams, gyroparams, magparams, then tweak obj once
            % all can be built successfully.
            if hasAcc
                pv = fusion.internal.SensorParamLoader.parseParams(...
                    s.Accelerometer);
                ap = accelparams;
                ap = fusion.internal.SensorParamLoader.configureParams(ap, pv);
            end
            if hasGyro
                pv = fusion.internal.SensorParamLoader.parseParams(...
                    s.Gyroscope);
                gp = gyroparams;
                gp = fusion.internal.SensorParamLoader.configureParams(gp, pv);
            end
            if hasMag
                pv = fusion.internal.SensorParamLoader.parseParams(...
                    s.Magnetometer);
                mp = magparams;
                mp = fusion.internal.SensorParamLoader.configureParams(mp, pv);
            end
            
            % All params can be built. Now it's okay to tweak obj.
            if hasMag
                if hasGyro
                    obj.IMUType = 'accel-gyro-mag';
                else
                    obj.IMUType = 'accel-mag';
                end
            else
                obj.IMUType = 'accel-gyro';
            end
            
            if hasAcc
                obj.Accelerometer = ap;
            end
            if hasGyro
                obj.Gyroscope = gp;
            end
            if hasMag
                obj.Magnetometer = mp;
            end
           
        end
    end

    methods (Access = protected)
        
          
        function val = hasGyro(obj)
            val = ~strcmp(obj.IMUType, 'accel-mag');
        end
        
        function val = hasMag(obj)
            val = ~strcmp(obj.IMUType, 'accel-gyro');
        end
        
        function setupImpl(obj, ~, ~, ~) 
            
            isMagFieldSet = coder.internal.is_defined(obj.MagneticField);
            if ~isempty(coder.target) && ~isMagFieldSet
                initializeMagneticField(obj);
            end
            
            setupRandomStream(obj);
            
            obj.pRefFrame = ...
                fusion.internal.frames.ReferenceFrame.getMathObject( ...
                obj.ReferenceFrame);
            
            obj.pAccel = createSystemObject(obj.Accelerometer, ...
                'ReferenceFrame', obj.ReferenceFrame);
            obj.pAccel.SampleRate = obj.SampleRate;
            obj.pAccel.Temperature = obj.Temperature;

            if hasGyro(obj)
                obj.pGyro = createSystemObject(obj.Gyroscope);
                obj.pGyro.SampleRate = obj.SampleRate;
                obj.pGyro.Temperature = obj.Temperature;
            end

            if hasMag(obj)
                obj.pMag = createSystemObject(obj.Magnetometer);
                obj.pMag.SampleRate = obj.SampleRate;
                obj.pMag.Temperature = obj.Temperature;
            end
        end

        function validateInputsImpl(~, acceleration, angularvelocity, orientation)
            validateattributes(acceleration, {'single', 'double'}, ...
                {'real', 'finite', '2d', 'ncols', 3});
            expectedDataType = class(acceleration);
            numSamples = size(acceleration, 1);
            validateattributes(angularvelocity, {expectedDataType}, ...
                {'real', 'finite', '2d', 'nrows', numSamples, 'ncols', 3});
            if (nargin == 4)
                if isa(orientation, 'quaternion')
                    quatDataType = classUnderlying(orientation);
                    coder.internal.errorIf(~strcmp(expectedDataType, quatDataType), ...
                        'shared_positioning:imuSensor:invalidUnderlyingType', expectedDataType, quatDataType);
                    validateattributes(orientation, {'quaternion'}, ...
                        {'nrows', numSamples, 'ncols', 1, '2d', 'finite'});
                else
                    validateattributes(orientation, {expectedDataType}, ...
                        {'real', 'finite', '3d', 'size', [3 3 numSamples]});
                end
            end
        end

        function processTunedPropertiesImpl(obj)
            if isChangedProperty(obj, 'Temperature')
                obj.pAccel.Temperature = obj.Temperature;
                updateSystemObject(obj.Accelerometer, obj.pAccel);
                if hasGyro(obj)
                    obj.pGyro.Temperature = obj.Temperature;
                    updateSystemObject(obj.Gyroscope, obj.pGyro);
                end
                if hasMag(obj)
                    obj.pMag.Temperature = obj.Temperature;
                    updateSystemObject(obj.Magnetometer, obj.pMag);
                end
            end
            if isChangedProperty(obj, 'Accelerometer')
                updateSystemObject(obj.Accelerometer, obj.pAccel);
            end
            if hasGyro(obj) && isChangedProperty(obj, 'Gyroscope')
                updateSystemObject(obj.Gyroscope, obj.pGyro);
            end
            if hasMag(obj) && isChangedProperty(obj, 'Magnetometer')
                updateSystemObject(obj.Magnetometer, obj.pMag);
            end
        end

        function flag = isInactivePropertyImpl(obj, prop)
            flag = false;
            if strcmp(prop, 'Seed')
                if strcmp(obj.RandomStream, 'Global stream')
                    flag = true;
                end
            end
            if strcmp(prop, 'Gyroscope')
                if ~hasGyro(obj)
                    flag = true;
                end
            end
            if strcmp(prop, 'Magnetometer')
                if ~hasMag(obj)
                    flag = true;
                end
            end
            if strcmp(prop, 'MagneticField')
                if ~hasMag(obj)
                    flag = true;
                end
            end
        end
        
        function num = getNumOutputsImpl(obj)
            if strcmp(obj.IMUType, 'accel-gyro-mag')
                num = 3;
            else
                num = 2;
            end
        end
        
        function perts = defaultPerturbations(obj)
            if hasMag(obj) && hasGyro(obj)
                perturbableProps = {obj.DefaultAccelPerts{:}, ...
                    obj.DefaultGyroPerts{:}, obj.DefaultMagPerts{:}};
            elseif hasMag(obj) && ~hasGyro(obj)
                perturbableProps = {obj.DefaultAccelPerts{:}, ...
                    obj.DefaultMagPerts{:}};
            elseif ~hasMag(obj) && hasGyro(obj)
                perturbableProps = {obj.DefaultAccelPerts{:}, ...
                    obj.DefaultGyroPerts{:}};
            end
            perts = struct(...
                'Property', perturbableProps, ...
                'Type', "None", ...
                'Value', {{NaN, NaN}}...
                );
        end
        
        function s = saveObjectImpl(obj)
            % Save public properties.
            s = saveObjectImpl@fusion.internal.IMUSensorBase(obj);
            
            % Save perturbation related properties
            s = savePerts(obj, s);
        end
        
        function loadObjectImpl(obj, s, wasLocked)
            % Load public properties.
            loadObjectImpl@fusion.internal.IMUSensorBase(obj, s, wasLocked);
            
            % Load perturbation related properties
            loadPerts(obj, s);
        end
    end
    
    methods (Static, Access=protected)
        function groups = getPropertyGroupsImpl
            groups = matlab.system.display.Section('Title', '', ...
                'PropertyList', {'IMUType', 'SampleRate', 'Temperature', ...
               'MagneticField', 'Accelerometer', 'Gyroscope', 'Magnetometer', ...
               'RandomStream', 'Seed'});
        end
    end

    methods (Hidden, Static)
        function flag = isAllowedInSystemBlock
            flag = false;
        end
    end
end

