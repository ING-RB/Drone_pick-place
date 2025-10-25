classdef complementaryFilter< fusion.internal.PositioningSystemBase
%COMPLEMENTARYFILTER Estimate orientation using complementary filter
%
%   FUSE = COMPLEMENTARYFILTER returns a complementary filter System
%   object, FUSE, for fusion of accelerometer, gyroscope, and magnetometer
%   data to estimate device orientation.
%
%   FUSE = COMPLEMENTARYFILTER("ReferenceFrame", RF) returns a
%   COMPLEMENTARYFILTER System object that fuses accelerometer, gyroscope,
%   and magnetometer data to estimate the device orientation relative to
%   the reference frame RF. Specify the reference frame as "NED"
%   (North-East-Down) or "ENU" (East-North-Up). The default value is "NED".
%
%   FUSE = COMPLEMENTARYFILTER(..., Name, Value) returns a
%   COMPLEMENTARYFILTER System object with each specified property name set
%   to the specified value. You can specify additional name-value pair
%   arguments in any order as (Name1,Value1,...,NameN, ValueN).
%
%   To estimate orientation:
%   1) Create the COMPLEMENTARYFILTER object and set its properties.
%   2) Call the object with arguments, as if it were a function.
%
%   [ORIENT, ANGVEL] = FUSE(ACCEL, GYRO, MAG) fuses the accelerometer data
%   ACCEL, gyroscope data GYRO, and magnetometer data MAG, to compute
%   device orientation ORIENT and angular velocity ANGVEL. This syntax is
%   only valid if HasMagnetometer is set to true.
%
%   [ORIENT, ANGVEL] = FUSE(ACCEL, GYRO) fuses the accelerometer data ACCEL
%   and gyroscope data GYRO to compute device orientation ORIENT and
%   angular velocity ANGVEL. This syntax is only valid if HasMagnetometer
%   is set to false.
%
%   Input Arguments:
%
%       ACCEL     Accelerometer measurement in the local sensor body
%                 coordinate system specified as a real finite N-by-3 array
%                 in meters per second squared. N is the number of samples
%                 in the current frame.
%
%       GYRO      Gyroscope measurement in the local sensor body coordinate
%                 system specified as a real finite N-by-3 array in radians
%                 per second. N is the number of samples in the current
%                 frame.
%
%       MAG       Magnetometer measurement in the local sensor body
%                 coordinate system specified as a real finite N-by-3 array
%                 in microteslas. N is the number of samples in the current
%                 frame.
%
%   Output Arguments:
%
%       ORIENT    Orientation with respect to the local navigation 
%                 coordinate system returned as an N-by-1 array of
%                 quaternions or a 3-by-3-by-N array of rotation matrices.
%                 Each quaternion or rotation matrix is a frame rotation
%                 from the local navigation coordinate system to the
%                 current body coordinate system. N is the number of
%                 samples in the current frame.
%
%       ANGVEL    Angular velocity in the local sensor body coordinate
%                 system returned as a real finite N-by-3 array in radians
%                 per second. N is the number of samples in the current
%                 frame.
%
%   Either single or double datatypes are supported for the inputs to
%   COMPLEMENTARYFILTER. Outputs have the same datatype as the input.
%
%   COMPLEMENTARYFILTER methods:
%
%   step             - Estimate orientation using sensor data
%   release          - Allow property value and input characteristics to 
%                      change, and release COMPLEMENTARYFILTER resources
%   clone            - Create COMPLEMENTARYFILTER object with same property
%                      values
%   isLocked         - Display locked status
%   <a href="matlab:help matlab.System/reset   ">reset</a>            - Reset states of COMPLEMENTARYFILTER
%
%   COMPLEMENTARYFILTER properties:
%
%   SampleRate           - Input sample rate of sensor data (Hz)
%   AccelerometerGain    - Gain of accelerometer versus gyroscope
%   MagnetometerGain     - Gain of magnetometer versus gyroscope
%   HasMagnetometer      - Enable magnetometer input
%   OrientationFormat    - Output format specified as "quaternion" or
%                          "Rotation matrix"
%
%   % EXAMPLE: Estimate orientation from recorded IMU data.
%
%   %  The data in rpy_9axis.mat is recorded accelerometer, gyroscope
%   %  and magnetometer sensor data from a device oscillating in pitch
%   %  (around y-axis) then yaw (around z-axis) then roll (around
%   %  x-axis). The device's x-axis was pointing southward when
%   %  recorded.
%
%   ld = load("rpy_9axis.mat");
%   accel = ld.sensorData.Acceleration;
%   gyro = ld.sensorData.AngularVelocity;
%   mag = ld.sensorData.MagneticField;
%
%   Fs  = ld.Fs;  % Hz
%   fuse = complementaryFilter("SampleRate", Fs);
%
%   % Fuse accelerometer, gyroscope, and magnetometer
%   q = fuse(accel, gyro, mag);
%
%   % Plot Euler angles in degrees
%   plot(eulerd(q, "ZYX", "frame"))
%   title("Orientation Estimate")
%   legend("Z-rotation", "Y-rotation", "X-rotation")
%   ylabel("Degrees")
%
%
%   See also IMUFILTER, AHRSFILTER, ECOMPASS

 
%   Copyright 2019-2023 The MathWorks, Inc.

    methods
        function out=complementaryFilter
        end

        function out=fuse(~) %#ok<STOUT>
        end

        function out=fuseWithMag(~) %#ok<STOUT>
        end

        function out=getNumInputsImpl(~) %#ok<STOUT>
        end

        function out=isInactivePropertyImpl(~) %#ok<STOUT>
        end

        function out=isInputComplexityMutableImpl(~) %#ok<STOUT>
        end

        function out=loadObjectImpl(~) %#ok<STOUT>
            % Load public properties.
        end

        function out=processInputSpecificationChangeImpl(~) %#ok<STOUT>
        end

        function out=processTunedPropertiesImpl(~) %#ok<STOUT>
        end

        function out=resetImpl(~) %#ok<STOUT>
        end

        function out=saveObjectImpl(~) %#ok<STOUT>
            % Save public properties.
        end

        function out=setupImpl(~) %#ok<STOUT>
        end

        function out=stepImpl(~) %#ok<STOUT>
        end

        function out=validateInputsImpl(~) %#ok<STOUT>
        end

    end
    properties
        % AccelerometerGain Accelerometer gain
        % Specify the accelerometer gain as a scalar between 0 and 1,
        % inclusive. This value determines how much the accelerometer
        % measurement is trusted over the gyroscope measurement for the
        % orientation estimation. The default value is 0.01. This property
        % is tunable.
        AccelerometerGain;

        % HasMagnetometer Enable magnetometer input
        % Specify the property as true or false to enable or disable
        % magnetometer input. The default value is true.
        HasMagnetometer;

        % MagnetometerGain Magnetometer gain
        % Specify the magnetometer gain as a scalar between 0 and 1,
        % inclusive. This value determines how much the magnetometer
        % measurement is trusted over the gyroscope measurement for the
        % orientation estimation. The default value is 0.01. This property
        % is tunable.
        MagnetometerGain;

        % OrientationFormat Output orientation format
        % Specify the output format as "quaternion" or "Rotation matrix" to
        % output the computed orientation as an N-by-1 quaternion or a
        % 3-by-3-by-N rotation matrix, respectively. The default value is
        % "quaternion".
        OrientationFormat;

        % SampleRate Sampling rate (Hz)
        % Specify the sampling frequency of the input sensor data as a
        % positive scalar. The default value is 100.
        SampleRate;

    end
end
