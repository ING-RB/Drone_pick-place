classdef complementaryFilter < fusion.internal.PositioningSystemBase
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
%   reset            - Reset states of COMPLEMENTARYFILTER
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

%#codegen

    properties (Nontunable)
        % SampleRate Sampling rate (Hz)
        % Specify the sampling frequency of the input sensor data as a
        % positive scalar. The default value is 100.
        SampleRate = 100;
    end
    
    properties
        % AccelerometerGain Accelerometer gain
        % Specify the accelerometer gain as a scalar between 0 and 1,
        % inclusive. This value determines how much the accelerometer
        % measurement is trusted over the gyroscope measurement for the
        % orientation estimation. The default value is 0.01. This property
        % is tunable.
        AccelerometerGain = 0.01;
        % MagnetometerGain Magnetometer gain
        % Specify the magnetometer gain as a scalar between 0 and 1,
        % inclusive. This value determines how much the magnetometer
        % measurement is trusted over the gyroscope measurement for the
        % orientation estimation. The default value is 0.01. This property
        % is tunable.
        MagnetometerGain = 0.01;
    end
       
    properties (Constant, Access = private)
        BiasAlpha = 0.01;
        AngularVelocityThreshold = 0.2;
        AccelerationThreshold = 0.1;
        DeltaAngularVelocityThreshold = 0.01;
    end

    properties (Access = private)
        GyroBias = [0 0 0];
        PrevAngVel = [0 0 0];
        
        pAccelGain;
        pMagGain;
    end
    
    properties (Nontunable, Hidden)
        ReferenceFrame = fusion.internal.frames.ReferenceFrame.getDefault;
    end
    
    properties (Access = private)
        pPrevOrientation;
        
        pIsInitialized = false;
    end

    properties (Nontunable, Access = private)
        pDeltaTime;
        
        pNorthIndex;
        pEastIndex;
        pGravityAxisSign;
    end

    properties (Nontunable)
        % HasMagnetometer Enable magnetometer input
        % Specify the property as true or false to enable or disable
        % magnetometer input. The default value is true.
        HasMagnetometer (1,1) logical = true;
        % OrientationFormat Output orientation format
        % Specify the output format as "quaternion" or "Rotation matrix" to
        % output the computed orientation as an N-by-1 quaternion or a
        % 3-by-3-by-N rotation matrix, respectively. The default value is
        % "quaternion".
        OrientationFormat = 'quaternion';
    end
    
    properties(Constant, Hidden)
        OrientationFormatSet = matlab.system.internal.MessageCatalogSet({...
            'shared_positioning:internal:IMUFusionCommon:OrientationQuat',...
            'shared_positioning:internal:IMUFusionCommon:OrientationRotmat'});
        ReferenceFrameSet = matlab.system.StringSet( ...
            fusion.internal.frames.ReferenceFrame.getOptions);
    end
    
    methods
        function obj = complementaryFilter(varargin)
            setProperties(obj, nargin, varargin{:});
        end
        
        function set.SampleRate(obj, val)
            validateattributes(val, {'numeric'}, ...
                {'scalar', 'real', 'positive', 'finite'}, ...
                '', 'SampleRate');
            obj.SampleRate = val;
        end
        
        function set.AccelerometerGain(obj, val)
            validateattributes(val, {'numeric'}, ...
                {'scalar', 'real', '>=', 0, '<=', 1}, ...
                '', 'AccelerometerGain');
            obj.AccelerometerGain = val;
        end
        
        function set.MagnetometerGain(obj, val)
            validateattributes(val, {'numeric'}, ...
                {'scalar', 'real', '>=', 0, '<=', 1}, ...
                '', 'MagnetometerGain');
            obj.MagnetometerGain = val;
        end
        
        function set.HasMagnetometer(obj, val)
            validateattributes(val, {'logical'}, {'scalar'}, '', ...
                'HasMagnetometer');
            obj.HasMagnetometer = val;
        end
    end
    
    methods(Access = protected)
        function flag = isInactivePropertyImpl(obj, prop)
            flag = strcmp(prop, 'MagnetometerGain') ...
                && ~obj.HasMagnetometer;
        end
        
        function validateInputsImpl(obj, varargin)
            accel = varargin{1};
            gyro = varargin{2};
            
            validateattributes(accel, {'double', 'single'}, ...
                {'real', 'finite', '2d', 'ncols', 3}, '', 'accel');
            expectedDataType = class(accel);
            numSamples = size(accel, 1);
            
            validateattributes(gyro, {expectedDataType}, ...
                {'real', 'finite', '2d', ...
                'nrows', numSamples, 'ncols', 3}, ...
                '', 'gyro');
            
            if (obj.HasMagnetometer)
                mag = varargin{3};
                validateattributes(mag, {expectedDataType}, ...
                    {'real', 'finite', '2d', ...
                    'nrows', numSamples, 'ncols', 3}, ...
                    '', 'mag');
            end
        end
        
        function setupImpl(obj, varargin)
            obj.pDeltaTime = cast(1/obj.SampleRate, 'like', varargin{1});
        end

        function resetImpl(obj)
            dt = obj.pDeltaTime;
            obj.pIsInitialized = false;
            obj.pPrevOrientation = quaternion.ones(1, 1, 'like', dt);
            obj.GyroBias = zeros(1, 3, 'like', dt);
            obj.PrevAngVel = zeros(1, 3, 'like', dt);
            obj.pDeltaTime = cast(1/obj.SampleRate, 'like', dt);
            obj.pAccelGain = cast(obj.AccelerometerGain, 'like', dt);
            obj.pMagGain = cast(obj.MagnetometerGain, 'like', dt);
            
            refFrameObj = ...
                fusion.internal.frames.ReferenceFrame.getMathObject( ...
                obj.ReferenceFrame);
            obj.pNorthIndex = refFrameObj.NorthIndex;
            obj.pEastIndex = refFrameObj.EastIndex;
            obj.pGravityAxisSign = refFrameObj.GravityAxisSign;
        end

        function processTunedPropertiesImpl(obj)
            dt = obj.pDeltaTime;
            if isChangedProperty(obj, 'AccelerometerGain')
                obj.pAccelGain = cast(obj.AccelerometerGain, ...
                    'like', dt);
            end
            if isChangedProperty(obj, 'MagnetometerGain')
                obj.pMagGain = cast(obj.MagnetometerGain, ...
                    'like', dt);
            end
        end
        
        function processInputSpecificationChangeImpl(obj, varargin)
            datatype = class(varargin{1});
            obj.pPrevOrientation = cast(obj.pPrevOrientation, datatype);
            obj.GyroBias = cast(obj.GyroBias, datatype);
            obj.PrevAngVel = cast(obj.PrevAngVel, datatype);
            obj.pDeltaTime = cast(obj.pDeltaTime, datatype);
        end

        % Roberto G. Valenti, Ivan Dryanovski, and Jizhong Xiao. "Keeping a
        % Good Attitude: A Quaternion-Based Orientation Filter for IMUs and
        % MARGs" MPDI Open Access Sensors Journal. August 2015, pp. 
        % 19302-19330.
        function [orient, angvel] = stepImpl(obj, varargin)
            dt = obj.pDeltaTime;
            % Return empty output when there is empty input.
            if isempty(varargin{1})
                q = quaternion.zeros(0, 1, 'like', dt);
                angvel = zeros(0, 3, 'like', dt);
                if strcmp(obj.OrientationFormat, 'quaternion')
                    orient = q;
                else
                    orient = rotmat(q, 'frame');
                end
                return;
            end
            
            hasMag = obj.HasMagnetometer;
            
            accelData = varargin{1};
            gyroData = varargin{2};
            if hasMag
                magData = varargin{3};
                magGain = obj.pMagGain;
            end
            numSamples = size(accelData, 1);

            if ~obj.pIsInitialized && (numSamples > 0)
                if hasMag
                    obj.pPrevOrientation = ecompass(accelData(1,:), magData(1,:), 'quaternion', 'ReferenceFrame', obj.ReferenceFrame);
                else
                    obj.pPrevOrientation = quaternion.ones(1, 1, 'like', accelData);
                end
                obj.pIsInitialized = true;
            end

            % Adaptive gain based on linear acceleration
            errMag = abs( arrayfun(@(i) norm(accelData(i,:)),1:numSamples) - grav() );
            accelGainFactor = zeros(size(errMag));
            accelGainFactor(errMag < 0.1) = 1;
            accelGainFactor(errMag >= 0.1) = 2 - 10 * errMag(errMag >= 0.1);
            accelGainFactor(errMag > 0.2) = 0;
            accelGain = obj.pAccelGain .* accelGainFactor;
            
            if ~hasMag
                [q, angvel] = fuse(obj, accelData, gyroData, accelGain);
            else
                [q, angvel] = fuseWithMag(obj, accelData, gyroData, magData, accelGain, magGain);
            end
            
            if strcmp(obj.OrientationFormat, 'quaternion')
                orient = q;
            else
                orient = rotmat(q, 'frame');
            end
        end

        function [q, angvel] = fuse(obj, accel, gyro, accelGain)

            dt = obj.pDeltaTime;

            gyroBiasAlpha = obj.BiasAlpha;
            accelerationThreshold = obj.AccelerationThreshold;
            angularVelocityThreshold = obj.AngularVelocityThreshold;
            deltaAngularVelocityThreshold = obj.DeltaAngularVelocityThreshold;
            prevAngVel = obj.PrevAngVel;
            gyroBias = obj.GyroBias;
            
            gravSign = obj.pGravityAxisSign;
            
            numSamples = size(accel, 1);
            q = quaternion.zeros(numSamples, 1, 'like', dt);
            angvel = zeros(numSamples, 3, 'like', dt);
            newAtt = obj.pPrevOrientation;
            for idx = 1:numSamples
                
                [gyroBias, prevAngVel] = updateGyroBias(accel(idx,:), gyro(idx,:), ...
                    accelerationThreshold, deltaAngularVelocityThreshold, angularVelocityThreshold, ...
                    gyroBiasAlpha, gyroBias, prevAngVel);
                
                angvel(idx,:) = gyro(idx,:) - gyroBias;
                
                newAtt = predictGyro(newAtt, gyro(idx,:), dt, gyroBias);
                
                newAtt = correctAccel(newAtt, accel(idx,:), accelGain(idx), gravSign);
                
                newAtt = normalize(newAtt);
                q(idx,:) = newAtt;
            end

            obj.pPrevOrientation = newAtt;
            
            obj.PrevAngVel = prevAngVel;
            obj.GyroBias = gyroBias;
        end

        function [q, angvel] = fuseWithMag(obj, accel, gyro, mag, accelGain, magGain)
            dt = obj.pDeltaTime;

            gyroBiasAlpha = obj.BiasAlpha;
            accelerationThreshold = obj.AccelerationThreshold;
            angularVelocityThreshold = obj.AngularVelocityThreshold;
            deltaAngularVelocityThreshold = obj.DeltaAngularVelocityThreshold;
            prevAngVel = obj.PrevAngVel;
            gyroBias = obj.GyroBias;

            gravSign = obj.pGravityAxisSign;
            northIdx = obj.pNorthIndex;
            eastIdx = obj.pEastIndex;
            
            numSamples = size(accel, 1);
            q = quaternion.zeros(numSamples, 1, 'like', dt);
            angvel = zeros(numSamples, 3, 'like', dt);
            newAtt = obj.pPrevOrientation;
            for idx = 1:numSamples
                
                [gyroBias, prevAngVel] = updateGyroBias(accel(idx,:), gyro(idx,:), ...
                    accelerationThreshold, deltaAngularVelocityThreshold, angularVelocityThreshold, ...
                    gyroBiasAlpha, gyroBias, prevAngVel);
                
                angvel(idx,:) = gyro(idx,:) - gyroBias;
                
                newAtt = predictGyro(newAtt, gyro(idx,:), dt, gyroBias);
                
                newAtt = correctAccel(newAtt, accel(idx,:), accelGain(idx), gravSign);
                
                newAtt = correctMag(newAtt, mag(idx,:), magGain, northIdx, eastIdx);
                
                newAtt = normalize(newAtt);
                q(idx,:) = newAtt;
            end

            obj.pPrevOrientation = newAtt;
            
            obj.PrevAngVel = prevAngVel;
            obj.GyroBias = gyroBias;
        end

        function num = getNumInputsImpl(obj)
            num = 2 + obj.HasMagnetometer;
        end

        function flag = isInputComplexityMutableImpl(~, ~)
            flag = false;
        end

        function s = saveObjectImpl(obj)
            % Save public properties.
            s = saveObjectImpl@matlab.System(obj);

            % Save private properties. 
            if isLocked(obj)
                s.GyroBias = obj.GyroBias;
                s.PrevAngVel = obj.PrevAngVel;
                s.pAccelGain = obj.pAccelGain;
                s.pMagGain = obj.pMagGain;
                s.pPrevOrientation = obj.pPrevOrientation;
                s.pIsInitialized = obj.pIsInitialized;
                s.pDeltaTime = obj.pDeltaTime;
                s.pNorthIndex = obj.pNorthIndex;
                s.pEastIndex = obj.pEastIndex;
                s.pGravityAxisSign = obj.pGravityAxisSign;
            end
        end

        function loadObjectImpl(obj, s, wasLocked)
            % Load public properties. 
            loadObjectImpl@matlab.System(obj, s, wasLocked);

            % Load private properties.
            if wasLocked
                obj.GyroBias = s.GyroBias;
                obj.PrevAngVel = s.PrevAngVel;
                obj.pAccelGain = s.pAccelGain;
                obj.pMagGain = s.pMagGain;
                obj.pPrevOrientation = s.pPrevOrientation;
                obj.pIsInitialized = s.pIsInitialized;
                obj.pDeltaTime = s.pDeltaTime;
                obj.pNorthIndex = s.pNorthIndex;
                obj.pEastIndex = s.pEastIndex;
                obj.pGravityAxisSign = s.pGravityAxisSign;
            end
        end
        
    end

    methods (Hidden, Static)
        function flag = isAllowedInSystemBlock
            flag = false;
        end
    end
    
end

function [gyroBias, prevAngVel] = updateGyroBias(accel, gyro, ...
    accelerationThreshold, deltaAngularVelocityThreshold, angularVelocityThreshold, ...
    gyroBiasAlpha, gyroBias, prevAngVel)
    % Update biases
    accMagnitude = norm(accel);
    % Check if at steady state.
    if (abs(accMagnitude - grav) <= accelerationThreshold) ...
        && (abs(gyro(1)-prevAngVel(1)) <= deltaAngularVelocityThreshold) ...
        && (abs(gyro(2)-prevAngVel(2)) <= deltaAngularVelocityThreshold) ...
        && (abs(gyro(3)-prevAngVel(3)) <= deltaAngularVelocityThreshold) ...
        && (abs(gyro(1) - gyroBias(1)) <= angularVelocityThreshold) ...
        && (abs(gyro(2) - gyroBias(2)) <= angularVelocityThreshold) ...
        && (abs(gyro(3) - gyroBias(3)) <= angularVelocityThreshold)
        gyroBias = gyroBias + gyroBiasAlpha .* (gyro - gyroBias);
    end
    prevAngVel = gyro;
end

function q = predictGyro(q, gyro, dt, gyroBias)
    % Prediction
    % 1. Convert the gyro data to a change in attitude.
    % 2. Integrate to get a new attitude estimation.
    q = q * quaternion((gyro-gyroBias)*dt, 'rotvec');
end

function q = correctAccel(q, accel, accelGain, gravSign)
    % Accelerometer Correction
    % 1. Rotate the accel data from the sensor frame to the
    %    global frame.
    % 2. Convert to a change in attitude.
    % 3. Filter the change based on the accel gain.
    % 4. Adjust attitude estimation.
    accelNormalized = accel ./ norm(accel);
    ap = rotatepoint(q, accelNormalized);
    
    deltaAccel0 = sqrt((gravSign*ap(3) + 1) / 2);
    deltaAccel1 = gravSign*ap(2) / sqrt(2*(gravSign*ap(3)+1));
    deltaAccel2 = -gravSign*ap(1) / sqrt(2*(gravSign*ap(3)+1));
    deltaAccel3 = cast(0, 'like', ap);
    q = applyCorrection(deltaAccel0, deltaAccel1, deltaAccel2, deltaAccel3, accelGain) * q;
    q = posangle(q);
end

function q = correctMag(q, mag, magGain, northIdx, eastIdx)
    % Magnetometer Correction
    % 1. Rotate the mag data from the sensor frame to the
    %    global frame.
    % 2. Convert to a change in attitude.
    % 3. Filter the change based on the mag gain.
    % 4. Adjust attitude estimation.
    magNormalized = mag ./ norm(mag);
    mp = rotatepoint(q, magNormalized);
    r = mp(1).^2 + mp(2).^2;
    
    deltaMag0 = sqrt(r + mp(northIdx).*sqrt(r)) / sqrt(2*r);
    deltaMag1 = cast(0, 'like', mp);
    deltaMag2 = cast(0, 'like', mp);
    deltaMag3 = -mp(eastIdx) / sqrt(2*(r+mp(northIdx)*sqrt(r)));
    q = applyCorrection(deltaMag0, deltaMag1, deltaMag2, deltaMag3, magGain) * q;
    q = posangle(q);
end

function deltaData = applyCorrection(q0, q1, q2, q3, a)

    thresh = cast(0.9, 'like', q0);

    if thresh >= q0 % SLERP
        omega = acos(q0);
        alphaSLERP = ( sin((a)*omega) / sin(omega) );
        
        q0 = ( sin((1-a)*omega) / sin(omega) ) + alphaSLERP*q0;
        q1 = alphaSLERP*q1;
        q2 = alphaSLERP*q2;
        q3 = alphaSLERP*q3;
    else % LERP
        q0 = (1-a) + a*q0;
        q1 = a*q1;
        q2 = a*q2;
        q3 = a*q3;
    end
    deltaData = normalize( quaternion(q0, q1, q2, q3) );
end

function g = grav()
g = fusion.internal.ConstantValue.Gravity;
end

function q = posangle(q)
    q = sign(parts(q)).*q;
end

