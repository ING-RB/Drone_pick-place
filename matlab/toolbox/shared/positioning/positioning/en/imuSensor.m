classdef imuSensor< fusion.internal.IMUSensorBase & scenario.internal.mixin.Perturbable
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
%   <a href="matlab:help matlab.System/reset   ">reset</a>            - Reset the states of the IMUSENSOR
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

    methods
        function out=imuSensor
        end

        function out=defaultPerturbations(~) %#ok<STOUT>
        end

        function out=getNumOutputsImpl(~) %#ok<STOUT>
        end

        function out=getPropertyGroupsImpl(~) %#ok<STOUT>
        end

        function out=hasGyro(~) %#ok<STOUT>
        end

        function out=hasMag(~) %#ok<STOUT>
        end

        function out=isInactivePropertyImpl(~) %#ok<STOUT>
        end

        function out=loadObjectImpl(~) %#ok<STOUT>
            % Load public properties.
        end

        function out=loadparams(~) %#ok<STOUT>
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
        end

        function out=processTunedPropertiesImpl(~) %#ok<STOUT>
        end

        function out=saveObjectImpl(~) %#ok<STOUT>
            % Save public properties.
        end

        function out=setupImpl(~) %#ok<STOUT>
        end

        function out=validateInputsImpl(~) %#ok<STOUT>
        end

    end
    properties
        % Accelerometer Accelerometer sensor parameters
        % accelparams object containing accelerometer parameters
        % This property is tunable.
        Accelerometer;

        % Gyroscope Gyroscope sensor parameters
        % gyroparams object containing gyroscope parameters.
        % This property is tunable.
        Gyroscope;

        % MagneticField Magnetic field vector (uT)
        % Specify the magnetic field as a real 3-element row vector in the
        % navigation frame. This property is tunable. The default value is
        % [27.5550 -2.4169 -16.0849].
        MagneticField;

        % Magnetometer Magnetometer sensor parameters
        % magparams object containing magnetometer parameters.
        % This property is tunable.
        Magnetometer;

        % SampleRate Sampling rate (Hz)
        % Specify the sampling frequency of the IMU as a positive scalar. 
        % The default value is 100.
        SampleRate;

    end
end
