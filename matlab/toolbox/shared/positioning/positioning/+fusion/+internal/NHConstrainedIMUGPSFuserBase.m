classdef (Hidden) NHConstrainedIMUGPSFuserBase < ...
    fusion.internal.INSFilterEKF & fusion.internal.mixin.IMUSynchronous
%NHConstrainedIMUGPSFuserBase Base class for insfilterNonholonomic
%
%   This class is for internal use only. It may be removed in the future.

%   Copyright 2018-2020 The MathWorks, Inc.

%#codegen
    
    properties
        % DecimationFactor
        % Specify the factor by which to reduce kinematic constraint 
        % correction. The decimation factor must be a positive integer 
        % scalar value. The default value of is 2.
        DecimationFactor = 2;
        
        % EKF values
    end
    properties (Dependent)
        % State EKF state vector
        % Specify the state vector as a 16-element real finite vector. The 
        % units and indices for each state are as follows:
        %
        %     State                         Units    Index
        %     Orientation as a quaternion             1:4
        %     Gyroscope bias (XYZ)           rad/s    5:7
        %     Position (NED)                 m        8:10
        %     Velocity (NED)                 m/s      11:13
        %     Accelerometer bias (XYZ)       m/s^2    14:16
        %
        % The default value is [1; zeros(15,1)].
        State
        % StateCovariance EKF error covariance matrix
        % Specify the value of the error covariance matrix. The error 
        % covariance matrix is a 16-by-16 matrix. The default value
        % is eye(16).
        StateCovariance
    end
    properties
        % Process noises
        
        % GyroscopeNoise Noise in the gyroscope signal (rad/s)^2
        % Specify the noise in the gyroscope data as a positive scalar or
        % 3-element row vector in (rad/s)^2. The default value is 
        % [4.8e-6, 4.8e-6, 4.8e-6].
        GyroscopeNoise = [4.8e-6, 4.8e-6, 4.8e-6];
        % AccelerometerNoise Noise in the accelerometer signal (m/s^2)^2
        % Specify the noise in the accelerometer data as a positive scalar 
        % or 3-element row vector in (m/s^2)^2. The default value is 
        % [4.8e-2, 4.8e-2, 4.8e-2].
        AccelerometerNoise = [4.8e-2, 4.8e-2, 4.8e-2];
        % GyroscopeBiasNoise Noise in the gyroscope bias (rad/s)^2
        % Gyroscope bias is modeled as a lowpass filtered white noise
        % process. Specify the noise in the gyroscope bias as a positive 
        % scalar or 3-element row vector in (rad/s)^2. The default value is
        % [4.0e-14, 4.0e-14, 4.0e-14].
        GyroscopeBiasNoise = [4.0e-14, 4.0e-14, 4.0e-14];
        % GyroscopeBiasDecayFactor Decay factor for gyroscope bias
        % Gyroscope bias is modeled as a lowpass filtered white noise
        % process. Specify the decay factor as a real scalar with a value
        % between 0 and 1, inclusive. A decay factor of 0 models the
        % gyroscope bias as a white noise process. A decay factor of 1
        % models the gyroscope bias as a random walk process. The default
        % value is 0.999.
        GyroscopeBiasDecayFactor = 0.999;
        % AccelerometerBiasNoise Noise in the accelerometer bias (m/s^2)^2
        % Accelerometer bias is modeled as a lowpass filtered white noise
        % process. Specify the noise in the accelerometer bias as a 
        % positive scalar or 3-element row vector in (m/s^2)^2. The default
        % value is [4.0e-14, 4.0e-14, 4.0e-14].
        AccelerometerBiasNoise = [4.0e-14, 4.0e-14, 4.0e-14];
        % AccelerometerBiasDecayFactor Decay factor for accelerometer bias
        % Accelerometer bias is modeled as a lowpass filtered white noise
        % process. Specify the decay factor as a real scalar with a value
        % between 0 and 1, inclusive. A decay factor of 0 models the
        % accelerometer bias as a white noise process. A decay factor of 1
        % models the accelerometer bias as a random walk process. The
        % default value is 0.9999.
        AccelerometerBiasDecayFactor = 0.9999;
        
        % Measurement noises
        
        % ZeroVelocityConstraintNoise Noise in velocity measurement ((m/s)^2)
        % Specify the noise in the velocity measurement as a nonnegative
        % scalar in (m/s)^2. The default value is 1.0e-2.
        ZeroVelocityConstraintNoise = 1.0e-2;
    end
    
    properties (Access = private)
        applyConstraintCount = int32(0);
    end
   
    properties (Access = protected)
        pState = [1; zeros(fusion.internal.NHConstrainedIMUGPSFuserBase.NumStates-1,1)];
        pStateCovariance = eye(fusion.internal.NHConstrainedIMUGPSFuserBase.NumStates);
    end

    properties (Hidden, Constant)
        NumStates = 16;
    end
    
    methods
        function obj = NHConstrainedIMUGPSFuserBase(varargin)
            obj = obj@fusion.internal.INSFilterEKF;
            matlabshared.fusionutils.internal.setProperties(obj, nargin, varargin{:});

            % Cache the math object
            obj.ReferenceFrameObject = fusion.internal.frames.ReferenceFrame.getMathObject( ...
                obj.ReferenceFrame);
        end
        
        function predict(obj, accelMeas, gyroMeas)
        %PREDICT Update states using accelerometer and gyroscope            
        %   predict(FUSE, ACCELMEAS, GYROMEAS) fuses the accelerometer and
        %   gyroscope data to update the state and the state estimation
        %   error covariance.
        %
        %   The inputs to predict are defined as follows:
        %
        %       ACCELMEAS    Accelerometer measurement in the local sensor 
        %                    body reference frame, specified as a 3-element
        %                    row vector in meters per second squared.
        %
        %       GYROMEAS     Gyroscope measurement in the local sensor body 
        %                    reference frame, specified as a 3-element row
        %                    vector in radians per second.
        %
        %   The kinematic model for this filter assumes there is no
        %   bouncing or skidding during movement. These two constraints can
        %   be applied as a zero velocity update of the lateral and
        %   vertical body axes. The update is weighted by the
        %   ZeroVelocityConstraintNoise property. The frequency of this
        %   update is determined by the DecimationFactor and IMUSampleRate
        %   properties.

            validateattributes(accelMeas, {'double','single'}, ...
                {'real','finite','2d','ncols',3,'nonempty'}, ...
                '', ...
                'acceleration');
            validateattributes(gyroMeas, {'double','single'}, ...
                {'real','finite','2d','ncols',3,'nonempty'}, ...
                '', ...
                'angularVelocity');
            n = size(accelMeas, 1);
            coder.internal.assert(size(gyroMeas, 1) == n, ...
                'shared_positioning:insfilter:RowMismatch');
            
            x = getState(obj);
            dt = 1 / obj.IMUSampleRate;
            accelBiasDecayFactor = obj.AccelerometerBiasDecayFactor;
            gyroBiasDecayFactor = obj.GyroscopeBiasDecayFactor;
            
            % Extended Kalman filter predict algorithm.
            setState(obj,  stateTransitionFcn(obj, x, dt, ...
                accelMeas, gyroMeas, ...
                accelBiasDecayFactor, gyroBiasDecayFactor));
            
            F = stateTransitionJacobianFcn(obj, x, dt, ...
                accelMeas, gyroMeas, ...
                accelBiasDecayFactor, gyroBiasDecayFactor);
            G = processNoiseJacobianFcn(obj, x, dt);
            U = processNoiseCovariance(obj);
            setStateCovariance(obj, predictCovEqn(obj, ...
                getStateCovariance(obj), F, U, G));
            
            % Apply vehicle kinematic constraints.
            obj.applyConstraintCount = obj.applyConstraintCount + 1;
            if (obj.applyConstraintCount == obj.DecimationFactor)
                correctKinematics(obj);
                obj.applyConstraintCount = int32(0);
            end
        end
        
        function [res, resCov] = residualgps(obj, gpsPos, RposIn, gpsVel, RvelIn)
        %RESIDUALGPS Residuals and residual covariance from GPS 
        %   [RES, RESCOV] = residualgps(FUSE, LLA, RPOS) uses GPS position
        %   data to compute residuals and residual covariance.
        %
        %   [RES, RESCOV] = residualgps(FUSE, LLA, RPOS, VEL, RVEL) uses
        %   GPS position and course data to compute residuals and residual
        %   covariance. The inputs are:
        %       
        %       FUSE    - ErrorStateIMUGPSFuserBase object
        %       LLA     - 1-by-3 vector of latitude, longitude and altitude 
        %       RPOS    - scalar, 1-by-3, or 3-by-3 covariance of the
        %                 NAV position measurement error in m^2
        %       VEL     - 1-by-3 vector of NAV velocities in units of m/s
        %       RVEL    - scalar, 1-by-3, or 3-by-3 covariance of the
        %                 NAV velocity measurement error in (m/s)^2
        %
        %   The outputs are:
        %       RES            - 1-by-4 position and course residuals in 
        %                        meters (m) and rad/s, respectively
        %       RESCOV         - 4-by-4 residual covariance
        %
        %   Example:
        %
        %       % Reject measurements that have a normalized residual above
        %       % a specified threshold.
        %       outlierThreshold = 3;
        %       filt = insfilterNonholonomic;
        %       llaMeas = [1 1 1];
        %       Rlla = 0.1;
        %       velMeas = [1 1 1];
        %       Rvel = 0.1;
        %       [res, resCov] = residualgps(filt, llaMeas, Rlla, ...
        %           velMeas, Rvel);
        %       normRes = res ./ sqrt( diag(resCov).' );
        %       if all(abs(normRes) <= outlierThreshold)
        %           fusegps(filt, llaMeas, Rlla, velMeas, Rvel);
        %       else
        %           fprintf('Outlier detected and disregarded.\n');
        %       end
        %
        %   See also fusegps.
            
            validateMeasurement(gpsPos, 'latitude-longitude-altitude');
            Rpos = validateExpandNoise(obj, RposIn, 3, 'Rpos', '3');
            if (nargin == 3)
                x = getState(obj);
                P = getStateCovariance(obj);

                h = measurementGPSPosition(obj, x);
                H = measurementJacobianGPSPosition(obj, x);
                rf = obj.ReferenceFrameObject;
                pos = rf.lla2frame(gpsPos, obj.ReferenceLocation).';
                z = pos;
                R = Rpos;

                [res, resCov] = privInnov(obj, P, h, H, z, R);
            else
                validateMeasurement(gpsVel, 'velocity');
                
                Rvel = validateExpandNoise(obj, RvelIn, 3, 'Rvel', '3');

                x = getState(obj);
                P = getStateCovariance(obj);

                h = measurementFcnGPS(obj, x);
                H = measurementJacobianFcnGPS(obj, x);
                [course, courseR] = velAndCovToCourseAndCov(obj, gpsVel, Rvel);
                course = adjustMeasuredCourse(obj, course, h(end));
                rf = obj.ReferenceFrameObject;
                pos = rf.lla2frame(gpsPos, obj.ReferenceLocation).';
                z = [pos; course];
                R = blkdiag(Rpos, courseR);

                [res, resCov] = privInnov(obj, P, h, H, z, R);
            end
        end
        
        function [res, resCov] = fusegps(obj, gpsLLA, RposIn, gpsVel, RvelIn)
        %FUSEGPS Correct state estimates using GPS 
        %   [RES, RESCOV] = fusegps(FUSE, LLA, RPOS) fuses GPS position
        %   data to correct the state estimate.
        %
        %   [RES, RESCOV] = fusegps(FUSE, LLA, RPOS, VEL, RVEL) fuses GPS
        %   position and course data to correct the state estimate. The
        %   inputs are:
        %       
        %       FUSE    - ErrorStateIMUGPSFuserBase object
        %       LLA     - 1-by-3 vector of latitude, longitude and altitude 
        %       RPOS    - scalar, 1-by-3, or 3-by-3 covariance of the
        %                 NAV position measurement error in m^2
        %       VEL     - 1-by-3 vector of NAV velocities in units of m/s
        %       RVEL    - scalar, 1-by-3, or 3-by-3 covariance of the
        %                 NAV velocity measurement error in (m/s)^2
        %
        %   The outputs are:
        %       RES              - 1-by-4 position and course residuals
        %                          in meters (m) and rad/s, respectively
        %       RESCOV           - 4-by-4 residual covariance
        %
        %   See also residualgps.
            
            validateMeasurement(gpsLLA, 'latitude-longitude-altitude');
            Rpos = validateExpandNoise(obj, RposIn, 3, 'Rpos', '3');
            if (nargin == 3)
                [res, resCov] = fusegpsPosition(obj, gpsLLA, Rpos);
            else
                validateMeasurement(gpsVel, 'velocity');
                
                Rvel = validateExpandNoise(obj, RvelIn, 3, 'Rvel', '3');

                x = getState(obj);
                P = getStateCovariance(obj);

                h = measurementFcnGPS(obj, x);
                H = measurementJacobianFcnGPS(obj, x);
                [course, courseR] = velAndCovToCourseAndCov(obj, gpsVel, Rvel);
                course = adjustMeasuredCourse(obj, course, h(end));
                rf = obj.ReferenceFrameObject;
                pos = rf.lla2frame(gpsLLA, obj.ReferenceLocation).';
                z = [pos; course];
                R = blkdiag(Rpos, courseR);

                [x, sCov, res, resCov] = correctEqn(obj, x, ...
                    P, h, H, z, R);
                setStateCovariance(obj, sCov);
                setState(obj, x);
            end
        end
        
        function reset(obj)
        %RESET Set state and state estimation error covariance to defaults
        %   reset(FUSE) resets the State and StateCovariance to their
        %   default values and resets the internal states of the filter.

            obj.applyConstraintCount = int32(0);
            setState(obj, [1; zeros(fusion.internal.NHConstrainedIMUGPSFuserBase.NumStates-1,1)]);
            setStateCovariance(obj, 1e-9*ones(fusion.internal.NHConstrainedIMUGPSFuserBase.NumStates));
        end
    end
    
    methods (Access = protected)
        function s = saveObject(obj)
            % Call each base class's saveObject 
            s = saveObject@fusion.internal.INSFilterEKF(obj);
            s = saveObject@fusion.internal.mixin.IMUSynchronous(obj,s);

            s.DecimationFactor = obj.DecimationFactor;
            s.State = obj.State;
            s.StateCovariance = obj.StateCovariance;
            s.GyroscopeNoise = obj.GyroscopeNoise;
            s.AccelerometerNoise = obj.AccelerometerNoise;
            s.GyroscopeBiasNoise = obj.GyroscopeBiasNoise;
            s.GyroscopeBiasDecayFactor = obj.GyroscopeBiasDecayFactor;
            s.AccelerometerBiasNoise = obj.AccelerometerBiasNoise;
            s.AccelerometerBiasDecayFactor = obj.AccelerometerBiasDecayFactor;
            s.ZeroVelocityConstraintNoise = obj.ZeroVelocityConstraintNoise;
            s.applyConstraintCount = obj.applyConstraintCount;
        end
        function loadObject(obj, s)
            % Call both base class's loadObject methods
            loadObject@fusion.internal.INSFilterEKF(obj, s);
            loadObject@fusion.internal.mixin.IMUSynchronous(obj, s);

            obj.DecimationFactor = s.DecimationFactor;
            obj.State = s.State;
            obj.StateCovariance = s.StateCovariance;
            obj.GyroscopeNoise = s.GyroscopeNoise;
            obj.AccelerometerNoise = s.AccelerometerNoise;
            obj.GyroscopeBiasNoise = s.GyroscopeBiasNoise;
            obj.GyroscopeBiasDecayFactor = s.GyroscopeBiasDecayFactor;
            obj.AccelerometerBiasNoise = s.AccelerometerBiasNoise;
            obj.AccelerometerBiasDecayFactor = s.AccelerometerBiasDecayFactor;
            obj.ZeroVelocityConstraintNoise = s.ZeroVelocityConstraintNoise;
            obj.applyConstraintCount = s.applyConstraintCount;
        end

        function [course, courseR] = velAndCovToCourseAndCov(~, vel, velR)
            groundspeed = sqrt(sum(vel(:,1:2).^2, 2));
            groundspeedR = norm(velR(1:2,1:2), 'fro');
            courseR = groundspeedR / (groundspeed^2);
            % Always use the y- and x-coordinate as inputs 1 and 2,
            % respectively, since this will be compared against the current
            % heading estimate, which is 0 whenever the body x-axis is
            % aligned with the navigation x-axis.
            course = atan2(vel(:,2), vel(:,1));
            if course < 0
                course = course + 2*pi;
            end
        end
        
        function zCourse = adjustMeasuredCourse(~, zCourse, hCourse)
            %ADJUSTMEASUREDCOURSE adjust course to compute correct angle 
            %difference
            %   Adjust measured course so that the magnitude of the 
            %   difference between it and the estimated course is less than
            %   or equal to 180 degrees. This helper method assumes the 
            %   following input ranges:
            %
            %   0 <= zCourse <= (2*pi)
            %   -pi <= hCourse <= pi
            
            courseDiff = zCourse - hCourse;
            if courseDiff > pi
                zCourse = zCourse - (2*pi);
            end
        end
        
        function correctKinematics(obj)
            % CORRECTKINEMATICS correct state estimates based on the
            % kinematic constraints
            
            x = getState(obj);
            P = getStateCovariance(obj);
            
            h = measurementFcnKinematics(obj, x);
            H = measurementJacobianFcnKinematics(obj, x);
            R = measurementNoiseKinematics(obj);
            
            zeroVel = [0; 0];
            z = zeroVel;
            
            [x, sCov] = correctEqn(obj, x, P, h, H, z, R);
            setStateCovariance(obj, sCov); 
            setState(obj, x);
        end
        
        function U = processNoiseCovariance(obj)
            % Process noises.
            
            gyroVar = diag(obj.GyroscopeNoise);
            gyroBiasVar = diag(obj.GyroscopeBiasNoise);
            accelVar = diag(obj.AccelerometerNoise);
            accelBiasVar = diag(obj.AccelerometerBiasNoise);
            
            U = blkdiag(gyroVar, gyroBiasVar, accelVar, accelBiasVar);
        end
        
        function R = measurementNoiseKinematics(obj)
            % Measurement noises for kinematic constraints.
            zeroVelVar = obj.ZeroVelocityConstraintNoise .* eye(2);
            
            R = zeroVelVar;
        end
    end
    
    methods % Set methods
        function set.DecimationFactor(obj, val)
            validateattributes(val, {'numeric'}, ...
                {'real', 'finite', 'positive', 'scalar', 'integer'}, ...
                '', ...
                'DecimationFactor');
            obj.DecimationFactor = int32(val);
        end

        function set.State(obj, val)
            setState(obj, val);
        end

        function val = get.State(obj)
            val = getState(obj);
        end
        
        function set.StateCovariance(obj, val)
            setStateCovariance(obj, val);
        end

        function val = get.StateCovariance(obj)
            val = getStateCovariance(obj);
        end
        
        function set.GyroscopeNoise(obj, val)
            validateattributes(val, {'double', 'single'}, ...
                {'finite', 'real', 'positive', '2d', ...
                'nonnan', 'nonempty', 'nonsparse'}, ...
                '', 'GyroscopeNoise');
           
            % Enforce scalar or 3-element vector inputs.
            n = numel(val);
            coder.internal.assert((n == 1) || (n == 3), ... 
                'shared_positioning:insfilter:OneorThreeElements', ...
                'GyroscopeNoise');

            obj.GyroscopeNoise(:) = val(:).';
        end
        
        function set.AccelerometerNoise(obj, val)
            validateattributes(val, {'double', 'single'}, ...
                {'finite', 'real', 'positive', '2d', ...
                'nonnan', 'nonempty', 'nonsparse'}, ...
                '', 'AccelerometerNoise');
           
            % Enforce scalar or 3-element vector inputs.
            n = numel(val);
            coder.internal.assert((n == 1) || (n == 3), ... 
                'shared_positioning:insfilter:OneorThreeElements', ...
                'AccelerometerNoise');

            obj.AccelerometerNoise(:) = val(:).';
        end
        
        function set.GyroscopeBiasNoise(obj, val)
            validateattributes(val, {'double', 'single'}, ...
                {'finite', 'real', 'positive', '2d', ...
                'nonnan', 'nonempty', 'nonsparse'}, ...
                '', 'GyroscopeBiasNoise');
           
            % Enforce scalar or 3-element vector inputs.
            n = numel(val);
            coder.internal.assert((n == 1) || (n == 3), ... 
                'shared_positioning:insfilter:OneorThreeElements', ...
                'GyroscopeBiasNoise');

            obj.GyroscopeBiasNoise(:) = val(:).';
        end
        
        function set.GyroscopeBiasDecayFactor(obj, val)
            validateattributes(val, {'double','single'}, ...
                {'real','scalar','>=',0,'<=',1}, ...
                '', ...
                'GyroscopeBiasDecayFactor');
            obj.GyroscopeBiasDecayFactor = val;
        end
        
        function set.AccelerometerBiasNoise(obj, val)
            validateattributes(val, {'double', 'single'}, ...
                {'finite', 'real', 'positive', '2d', ...
                'nonnan', 'nonempty', 'nonsparse'}, ...
                '', 'AccelerometerBiasNoise');
           
            % Enforce scalar or 3-element vector inputs.
            n = numel(val);
            coder.internal.assert((n == 1) || (n == 3), ... 
                'shared_positioning:insfilter:OneorThreeElements', ...
                'AccelerometerBiasNoise');

            obj.AccelerometerBiasNoise(:) = val(:).';
        end
        
        function set.AccelerometerBiasDecayFactor(obj, val)
            validateattributes(val, {'double','single'}, ...
                {'real','scalar','>=',0,'<=',1}, ...
                '', ...
                'AccelerometerBiasDecayFactor');
            obj.AccelerometerBiasDecayFactor = val;
        end
        
        function set.ZeroVelocityConstraintNoise(obj, val)
            validateattributes(val, {'double','single'}, ...
                {'real','scalar','positive','finite'}, ...
                '', ...
                'ZeroVelocityConstraintNoise');
            obj.ZeroVelocityConstraintNoise = val;
        end
    end
    
    methods (Access = protected)
        function setState(obj, val)
            validateattributes(val, {'double','single'}, ...
                {'real','finite','vector','numel',fusion.internal.NHConstrainedIMUGPSFuserBase.NumStates}, ...
                '', ...
                'State');
            % Ensure it is a column vector.
            obj.pState = val(:);
        end
        function val = getState(obj)
            val = obj.pState;
        end
        function setStateCovariance(obj, val)
            validateattributes(val, {'double','single'}, ...
                {'finite','real','2d','square', ...
                'numel',fusion.internal.NHConstrainedIMUGPSFuserBase.NumStates.^2, ...
                'nonempty','nonsparse'}, ...
                '', ...
                'StateCovariance');
            obj.pStateCovariance = val;
        end
        function val = getStateCovariance(obj)
            val = obj.pStateCovariance;
        end
        function pos = getPosition(obj)
            st = getState(obj);
            pos = st(8:10).';
        end
        
        function orient = getOrientation(obj)
            st = getState(obj);
            orient = quaternion(st(1:4).');
        end

        function vel = getVelocity(obj)
            st = getState(obj);
            vel = st(11:13).';
        end
        
        % Predict Helper Functions
        function x = stateTransitionFcn(obj, x, dt, accelMeas, gyroMeas, accelBiasDecayFactor, gyroBiasDecayFactor)
            %STATETRANSITIONFCN new filter states based on current IMU data
            %   Predict forward the state estimate one time sample, based on control
            %   inputs:
            %       new gyroscope readings, and
            %       new accelerometer readings.
            
            q0 = x(1);
            q1 = x(2);
            q2 = x(3);
            q3 = x(4);
            gbX = x(5);
            gbY = x(6);
            gbZ = x(7);
            pn = x(8);
            pe = x(9);
            pd = x(10);
            vn = x(11);
            ve = x(12);
            vd = x(13);
            abX = x(14);
            abY = x(15);
            abZ = x(16);
            
            amX = accelMeas(1);
            amY = accelMeas(2);
            amZ = accelMeas(3);
            gmX = gyroMeas(1);
            gmY = gyroMeas(2);
            gmZ = gyroMeas(3);
            
            lambdaAccel = 1-accelBiasDecayFactor;
            lambdaGyro = 1-gyroBiasDecayFactor;
            
            rf = obj.ReferenceFrameObject;
            grav = zeros(1,3, 'like', x);
            grav(rf.GravityIndex) = -rf.GravitySign*rf.GravityAxisSign*gravms2();
            gravX = grav(1);
            gravY = grav(2);
            gravZ = grav(3);
            
            % State update equation
            % Orientation is updated below. This line updates position, velocity, and
            % sensor biases.
            %
            % x(1:4) - pre-allocated placeholders of the current quaternion parts.
            % x(5:7) - gyroscope bias update equation. The new gyroscope bias is the
            %    current bias times the decay factor filter parameter.
            % x(8:10) - position update equation. The new position is
            %    the current position plus the effect of the current velocity.
            % x(11:13) - velocity update equation. The new velocity is
            %    the current velocity plus the current acceleration estimate times the
            %        sample time.
            %        The current acceleration estimate is the accelerometer measurement
            %        minus accelerometer bias, rotated to the global frame, then
            %        subtracted by the gravity vector's effect.
            % x(14:16) - accelerometer bias update equation. The new accelerometer bias
            %    is the current bias times the decay factor filter parameter.
            %
            % In all of the above, a "plus white noise" is assumed by the Extended
            % Kalman Filter formulation. So, for example, the new position
            % is the previous position plus the effect of the current velocity plus
            % white noise.
            x = ...
                [
                q0 + dt*q1*(gbX/2 - gmX/2) + dt*q2*(gbY/2 - gmY/2) + dt*q3*(gbZ/2 - gmZ/2);
                q1 - dt*q0*(gbX/2 - gmX/2) + dt*q3*(gbY/2 - gmY/2) - dt*q2*(gbZ/2 - gmZ/2);
                q2 - dt*q3*(gbX/2 - gmX/2) - dt*q0*(gbY/2 - gmY/2) + dt*q1*(gbZ/2 - gmZ/2);
                q3 + dt*q2*(gbX/2 - gmX/2) - dt*q1*(gbY/2 - gmY/2) - dt*q0*(gbZ/2 - gmZ/2);
                -gbX*(dt*lambdaGyro - 1);
                -gbY*(dt*lambdaGyro - 1);
                -gbZ*(dt*lambdaGyro - 1);
                pn + dt*vn;
                pe + dt*ve;
                pd + dt*vd;
                vn + dt*(q0*(q0*(abX - amX) - q3*(abY - amY) + q2*(abZ - amZ)) - gravX + q2*(q1*(abY - amY) - q2*(abX - amX) + q0*(abZ - amZ)) + q1*(q1*(abX - amX) + q2*(abY - amY) + q3*(abZ - amZ)) - q3*(q3*(abX - amX) + q0*(abY - amY) - q1*(abZ - amZ)));
                ve + dt*(q0*(q3*(abX - amX) + q0*(abY - amY) - q1*(abZ - amZ)) - gravY - q1*(q1*(abY - amY) - q2*(abX - amX) + q0*(abZ - amZ)) + q2*(q1*(abX - amX) + q2*(abY - amY) + q3*(abZ - amZ)) + q3*(q0*(abX - amX) - q3*(abY - amY) + q2*(abZ - amZ)));
                vd + dt*(q0*(q1*(abY - amY) - q2*(abX - amX) + q0*(abZ - amZ)) - gravZ + q1*(q3*(abX - amX) + q0*(abY - amY) - q1*(abZ - amZ)) - q2*(q0*(abX - amX) - q3*(abY - amY) + q2*(abZ - amZ)) + q3*(q1*(abX - amX) + q2*(abY - amY) + q3*(abZ - amZ)));
                -abX*(dt*lambdaAccel - 1);
                -abY*(dt*lambdaAccel - 1);
                -abZ*(dt*lambdaAccel - 1);
                ];
            x = repairQuaternion(obj, x);
        end
        
        function F = stateTransitionJacobianFcn(~, x, dt, accelMeas, gyroMeas, accelBiasDecayFactor, gyroBiasDecayFactor)
            % STATETRANSITIONJACOBIANFCN Jacobian of process equations
            %   Compute the Jacobian matrix F of the state transition function f(x)
            %   with respect to state x.
            
            q0 = x(1);
            q1 = x(2);
            q2 = x(3);
            q3 = x(4);
            gbX = x(5);
            gbY = x(6);
            gbZ = x(7);
            pn = x(8); %#ok<NASGU>
            pe = x(9); %#ok<NASGU>
            pd = x(10); %#ok<NASGU>
            vn = x(11); %#ok<NASGU>
            ve = x(12); %#ok<NASGU>
            vd = x(13); %#ok<NASGU>
            abX = x(14);
            abY = x(15);
            abZ = x(16);
            
            amX = accelMeas(1);
            amY = accelMeas(2);
            amZ = accelMeas(3);
            gmX = gyroMeas(1);
            gmY = gyroMeas(2);
            gmZ = gyroMeas(3);
            
            lambdaAccel = 1-accelBiasDecayFactor;
            lambdaGyro = 1-gyroBiasDecayFactor;
            
            % The matrix here is the Jacobian of the equations in stateTransitionFcn().
            % The orientation quaternion update portion uses an approximation of
            % the quaternion incremental rotation update equation. The state
            % equation of the quaternion update (ignoring positive angle and
            % normalization requirements) is
            %   q_next = q_current * q_increment
            %
            %   where q_increment = quaternion( deltaAngle, 'rotvec')
            %
            % A quaternion is computed from a rotation vector as :
            %   q = (cos(ang)^2 + sin(ang)^2 *( ax(1) *i + ax(2)*j + ax(3)*k)
            % for axis 1-by-3 axis 'ax' and angle of rotation 'ang'.
            %
            % Using a small angle approximation,
            %   cos(ang)^2 == 0
            % Using the Maclaurin expansion and truncating after the first term:
            %   sin(ang)^2 * ax(n) == 1/2 * ax(n)
            % So the rotation vector to quaternion approximation used in the
            % Jacobian calculation below is:
            %   q_increment = quaternion(0, ax(1)/2, ax(2)/2, ax(3)/2)
            F = ...
                [
                1,                                           dt*(gbX/2 - gmX/2),                                           dt*(gbY/2 - gmY/2),                                           dt*(gbZ/2 - gmZ/2),         (dt*q1)/2,         (dt*q2)/2,         (dt*q3)/2, 0, 0, 0,  0,  0,  0,                              0,                              0,                              0;
                -dt*(gbX/2 - gmX/2),                                                            1,                                          -dt*(gbZ/2 - gmZ/2),                                           dt*(gbY/2 - gmY/2),        -(dt*q0)/2,         (dt*q3)/2,        -(dt*q2)/2, 0, 0, 0,  0,  0,  0,                              0,                              0,                              0;
                -dt*(gbY/2 - gmY/2),                                           dt*(gbZ/2 - gmZ/2),                                                            1,                                          -dt*(gbX/2 - gmX/2),        -(dt*q3)/2,        -(dt*q0)/2,         (dt*q1)/2, 0, 0, 0,  0,  0,  0,                              0,                              0,                              0;
                -dt*(gbZ/2 - gmZ/2),                                          -dt*(gbY/2 - gmY/2),                                           dt*(gbX/2 - gmX/2),                                                            1,         (dt*q2)/2,        -(dt*q1)/2,        -(dt*q0)/2, 0, 0, 0,  0,  0,  0,                              0,                              0,                              0;
                0,                                                            0,                                                            0,                                                            0, 1 - dt*lambdaGyro,                 0,                 0, 0, 0, 0,  0,  0,  0,                              0,                              0,                              0;
                0,                                                            0,                                                            0,                                                            0,                 0, 1 - dt*lambdaGyro,                 0, 0, 0, 0,  0,  0,  0,                              0,                              0,                              0;
                0,                                                            0,                                                            0,                                                            0,                 0,                 0, 1 - dt*lambdaGyro, 0, 0, 0,  0,  0,  0,                              0,                              0,                              0;
                0,                                                            0,                                                            0,                                                            0,                 0,                 0,                 0, 1, 0, 0, dt,  0,  0,                              0,                              0,                              0;
                0,                                                            0,                                                            0,                                                            0,                 0,                 0,                 0, 0, 1, 0,  0, dt,  0,                              0,                              0,                              0;
                0,                                                            0,                                                            0,                                                            0,                 0,                 0,                 0, 0, 0, 1,  0,  0, dt,                              0,                              0,                              0;
                dt*(2*q0*(abX - amX) - 2*q3*(abY - amY) + 2*q2*(abZ - amZ)),  dt*(2*q1*(abX - amX) + 2*q2*(abY - amY) + 2*q3*(abZ - amZ)),  dt*(2*q1*(abY - amY) - 2*q2*(abX - amX) + 2*q0*(abZ - amZ)), -dt*(2*q3*(abX - amX) + 2*q0*(abY - amY) - 2*q1*(abZ - amZ)),                 0,                 0,                 0, 0, 0, 0,  1,  0,  0, dt*(q0^2 + q1^2 - q2^2 - q3^2),        -dt*(2*q0*q3 - 2*q1*q2),         dt*(2*q0*q2 + 2*q1*q3);
                dt*(2*q3*(abX - amX) + 2*q0*(abY - amY) - 2*q1*(abZ - amZ)), -dt*(2*q1*(abY - amY) - 2*q2*(abX - amX) + 2*q0*(abZ - amZ)),  dt*(2*q1*(abX - amX) + 2*q2*(abY - amY) + 2*q3*(abZ - amZ)),  dt*(2*q0*(abX - amX) - 2*q3*(abY - amY) + 2*q2*(abZ - amZ)),                 0,                 0,                 0, 0, 0, 0,  0,  1,  0,         dt*(2*q0*q3 + 2*q1*q2), dt*(q0^2 - q1^2 + q2^2 - q3^2),        -dt*(2*q0*q1 - 2*q2*q3);
                dt*(2*q1*(abY - amY) - 2*q2*(abX - amX) + 2*q0*(abZ - amZ)),  dt*(2*q3*(abX - amX) + 2*q0*(abY - amY) - 2*q1*(abZ - amZ)), -dt*(2*q0*(abX - amX) - 2*q3*(abY - amY) + 2*q2*(abZ - amZ)),  dt*(2*q1*(abX - amX) + 2*q2*(abY - amY) + 2*q3*(abZ - amZ)),                 0,                 0,                 0, 0, 0, 0,  0,  0,  1,        -dt*(2*q0*q2 - 2*q1*q3),         dt*(2*q0*q1 + 2*q2*q3), dt*(q0^2 - q1^2 - q2^2 + q3^2);
                0,                                                            0,                                                            0,                                                            0,                 0,                 0,                 0, 0, 0, 0,  0,  0,  0,             1 - dt*lambdaAccel,                              0,                              0;
                0,                                                            0,                                                            0,                                                            0,                 0,                 0,                 0, 0, 0, 0,  0,  0,  0,                              0,             1 - dt*lambdaAccel,                              0;
                0,                                                            0,                                                            0,                                                            0,                 0,                 0,                 0, 0, 0, 0,  0,  0,  0,                              0,                              0,             1 - dt*lambdaAccel;
                ];
        end
        
        function G = processNoiseJacobianFcn(~, x, dt)
            %PROCESSNOISEJACOBIANFCN Compute jacobian for multiplicative process noise
            %   The process noise Jacobian G for state vector x and multiplicative
            %   process noise w is L* W * (L.') where
            %       L = jacobian of update function f with respect to drive inputs
            %       W = covariance matrix of multiplicative process noise w.
            
            q0 = x(1);
            q1 = x(2);
            q2 = x(3);
            q3 = x(4);
            gbX = x(5); %#ok<NASGU>
            gbY = x(6); %#ok<NASGU>
            gbZ = x(7); %#ok<NASGU>
            pn = x(8); %#ok<NASGU>
            pe = x(9); %#ok<NASGU>
            pd = x(10); %#ok<NASGU>
            vn = x(11); %#ok<NASGU>
            ve = x(12); %#ok<NASGU>
            vd = x(13); %#ok<NASGU>
            abX = x(14); %#ok<NASGU>
            abY = x(15); %#ok<NASGU>
            abZ = x(16); %#ok<NASGU>
            
            G = ...
                [
                -(dt*q1)/2, -(dt*q2)/2, -(dt*q3)/2, 0, 0, 0,                               0,                               0,                               0, 0, 0, 0;
                (dt*q0)/2, -(dt*q3)/2,  (dt*q2)/2, 0, 0, 0,                               0,                               0,                               0, 0, 0, 0;
                (dt*q3)/2,  (dt*q0)/2, -(dt*q1)/2, 0, 0, 0,                               0,                               0,                               0, 0, 0, 0;
                -(dt*q2)/2,  (dt*q1)/2,  (dt*q0)/2, 0, 0, 0,                               0,                               0,                               0, 0, 0, 0;
                0,          0,          0, 0, 0, 0,                               0,                               0,                               0, 0, 0, 0;
                0,          0,          0, 0, 0, 0,                               0,                               0,                               0, 0, 0, 0;
                0,          0,          0, 0, 0, 0,                               0,                               0,                               0, 0, 0, 0;
                0,          0,          0, 0, 0, 0,                               0,                               0,                               0, 0, 0, 0;
                0,          0,          0, 0, 0, 0,                               0,                               0,                               0, 0, 0, 0;
                0,          0,          0, 0, 0, 0,                               0,                               0,                               0, 0, 0, 0;
                0,          0,          0, 0, 0, 0, -dt*(q0^2 + q1^2 - q2^2 - q3^2),          dt*(2*q0*q3 - 2*q1*q2),         -dt*(2*q0*q2 + 2*q1*q3), 0, 0, 0;
                0,          0,          0, 0, 0, 0,         -dt*(2*q0*q3 + 2*q1*q2), -dt*(q0^2 - q1^2 + q2^2 - q3^2),          dt*(2*q0*q1 - 2*q2*q3), 0, 0, 0;
                0,          0,          0, 0, 0, 0,          dt*(2*q0*q2 - 2*q1*q3),         -dt*(2*q0*q1 + 2*q2*q3), -dt*(q0^2 - q1^2 - q2^2 + q3^2), 0, 0, 0;
                0,          0,          0, 0, 0, 0,                               0,                               0,                               0, 0, 0, 0;
                0,          0,          0, 0, 0, 0,                               0,                               0,                               0, 0, 0, 0;
                0,          0,          0, 0, 0, 0,                               0,                               0,                               0, 0, 0, 0;
                ];
        end
        
        % Correct Helper Functions
        function h = measurementFcnGPS(~, x)
            %MEASUREMENTFCNGPS Measurement function h(x) for state vector x
            %   4 measurements from GPS
            %   [posN, posE, posD, heading];
            
            q0 = x(1);
            q1 = x(2);
            q2 = x(3);
            q3 = x(4);
            gbX = x(5); %#ok<NASGU>
            gbY = x(6); %#ok<NASGU>
            gbZ = x(7); %#ok<NASGU>
            pn = x(8);
            pe = x(9);
            pd = x(10);
            vn = x(11); %#ok<NASGU>
            ve = x(12); %#ok<NASGU>
            vd = x(13); %#ok<NASGU>
            abX = x(14); %#ok<NASGU>
            abY = x(15); %#ok<NASGU>
            abZ = x(16); %#ok<NASGU>
            
            h = ...
                [
                pn;
                pe;
                pd;
                atan2((q0.*q3.*2 + q1.*q2.*2),(q0.^2.*2 - 1 + q1.^2.*2));
                ];
        end
        
        function h = measurementFcnKinematics(~, x)
            %MEASUREMENTFCNKINEMATICS Measurement function h(x) for state vector x
            %   2 measurements from kinematic constraints
            %   [velY, velZ];
            
            q0 = x(1);
            q1 = x(2);
            q2 = x(3);
            q3 = x(4);
            gbX = x(5); %#ok<NASGU>
            gbY = x(6); %#ok<NASGU>
            gbZ = x(7); %#ok<NASGU>
            pn = x(8); %#ok<NASGU>
            pe = x(9); %#ok<NASGU>
            pd = x(10); %#ok<NASGU>
            vn = x(11);
            ve = x(12);
            vd = x(13);
            abX = x(14); %#ok<NASGU>
            abY = x(15); %#ok<NASGU>
            abZ = x(16); %#ok<NASGU>
            
            h = ...
                [
                q0*(q1*vd + q0*ve - q3*vn) + q1*(q0*vd - q1*ve + q2*vn) + q2*(q3*vd + q2*ve + q1*vn) - q3*(q3*ve - q2*vd + q0*vn);
                q0*(q0*vd - q1*ve + q2*vn) - q1*(q1*vd + q0*ve - q3*vn) + q2*(q3*ve - q2*vd + q0*vn) + q3*(q3*vd + q2*ve + q1*vn);
                ];
        end
        
        function H = measurementJacobianFcnGPS(~, x)
            %MEASUREMENTJACOBIANFCNGPS Compute the jacobian H of measurement function h(x)
            q0 = x(1);
            q1 = x(2);
            q2 = x(3);
            q3 = x(4);
            gbX = x(5); %#ok<NASGU>
            gbY = x(6); %#ok<NASGU>
            gbZ = x(7); %#ok<NASGU>
            pn = x(8); %#ok<NASGU>
            pe = x(9); %#ok<NASGU>
            pd = x(10); %#ok<NASGU>
            vn = x(11); %#ok<NASGU>
            ve = x(12); %#ok<NASGU>
            vd = x(13); %#ok<NASGU>
            abX = x(14); %#ok<NASGU>
            abY = x(15); %#ok<NASGU>
            abZ = x(16); %#ok<NASGU>
            
            H = ...
                [
                0,                                                                                                                                                               0,                                                                              0,                                                                              0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0;
                0,                                                                                                                                                               0,                                                                              0,                                                                              0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0;
                0,                                                                                                                                                               0,                                                                              0,                                                                              0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0;
                (((2*q3)/(2*q0^2 + 2*q1^2 - 1) - (4*q0*(2*q0*q3 + 2*q1*q2))/(2*q0^2 + 2*q1^2 - 1)^2)*(2*q0^2 + 2*q1^2 - 1)^2)/((2*q0^2 + 2*q1^2 - 1)^2 + (2*q0*q3 + 2*q1*q2)^2), (((2*q2)/(2*q0^2 + 2*q1^2 - 1) - (4*q1*(2*q0*q3 + 2*q1*q2))/(2*q0^2 + 2*q1^2 - 1)^2)*(2*q0^2 + 2*q1^2 - 1)^2)/((2*q0^2 + 2*q1^2 - 1)^2 + (2*q0*q3 + 2*q1*q2)^2), (2*q1*(2*q0^2 + 2*q1^2 - 1))/((2*q0^2 + 2*q1^2 - 1)^2 + (2*q0*q3 + 2*q1*q2)^2), (2*q0*(2*q0^2 + 2*q1^2 - 1))/((2*q0^2 + 2*q1^2 - 1)^2 + (2*q0*q3 + 2*q1*q2)^2), 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0;               
                ];
            
        end
        
        function [innov, iCov] = fusegpsPosition(obj, gpsPos, Rpos)
            x = getState(obj);
            P = getStateCovariance(obj);

            h = measurementGPSPosition(obj, x);
            H = measurementJacobianGPSPosition(obj, x);
            rf = obj.ReferenceFrameObject;
            pos = rf.lla2frame(gpsPos, obj.ReferenceLocation).';
            z = pos;
            R = Rpos;

            [x, sCov, innov, iCov] = correctEqn(obj, x, ...
                P, h, H, z, R);
            setStateCovariance(obj, sCov); 
            setState(obj, x);
        end
        
        function h = measurementGPSPosition(~, x)
            pos = x(8:10);
            
            h = pos;
        end
        
        function H = measurementJacobianGPSPosition(~, ~)
            
            H = [...
                0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0;
                0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0;
                0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0;
                ];
        end
        
        function H = measurementJacobianFcnKinematics(~, x)
            %MEASUREMENTJACOBIANFCNKINEMATICS Compute the jacobian H of measurement function h(x)
            q0 = x(1);
            q1 = x(2);
            q2 = x(3);
            q3 = x(4);
            gbX = x(5); %#ok<NASGU>
            gbY = x(6); %#ok<NASGU>
            gbZ = x(7); %#ok<NASGU>
            pn = x(8); %#ok<NASGU>
            pe = x(9); %#ok<NASGU>
            pd = x(10); %#ok<NASGU>
            vn = x(11);
            ve = x(12);
            vd = x(13);
            abX = x(14); %#ok<NASGU>
            abY = x(15); %#ok<NASGU>
            abZ = x(16); %#ok<NASGU>
                        
            H = ...
                [
                2*q1*vd + 2*q0*ve - 2*q3*vn, 2*q0*vd - 2*q1*ve + 2*q2*vn, 2*q3*vd + 2*q2*ve + 2*q1*vn, 2*q2*vd - 2*q3*ve - 2*q0*vn, 0, 0, 0, 0, 0, 0, 2*q1*q2 - 2*q0*q3, q0^2 - q1^2 + q2^2 - q3^2,         2*q0*q1 + 2*q2*q3, 0, 0, 0;
                2*q0*vd - 2*q1*ve + 2*q2*vn, 2*q3*vn - 2*q0*ve - 2*q1*vd, 2*q3*ve - 2*q2*vd + 2*q0*vn, 2*q3*vd + 2*q2*ve + 2*q1*vn, 0, 0, 0, 0, 0, 0, 2*q0*q2 + 2*q1*q3,         2*q2*q3 - 2*q0*q1, q0^2 - q1^2 - q2^2 + q3^2, 0, 0, 0;
                ];
            
        end
    end

    methods
        function s = stateinfo(~)
        %STATEINFO Display state vector information
        %   STATEINFO(FUSE) displays the meaning of each index of the State 
        %   property and the associated units. 
        %   
        %   S = STATEINFO(FUSE) returns a struct with fields describing the
        %   elements of the state vector of FUSE. The values of each field 
        %   are the corresponding indices of the state vector.
            if (nargout == 1)
                s = struct(...
                    'Orientation', 1:4, ...
                    'GyroscopeBias', 5:7, ...
                    'Position', 8:10, ...
                    'Velocity', 11:13, ...
                    'AccelerometerBias', 14:16);

            else
                % Purely display.
                stateCellArr = {'States', 'Orientation (quaternion parts)', ...
                    'Gyroscope Bias (XYZ)', 'Position (NAV)', ...
                    'Velocity (NAV)', 'Accelerometer Bias (XYZ)'};
                unitCellArr = {'Units', '', 'rad/s', 'm', 'm/s', acceleration};
                indexCellArr = {'Index', '1:4', '5:7', '8:10', '11:13', '14:16'};
                
                states = char(stateCellArr(:));
                units = char(unitCellArr(:));
                indices = char(indexCellArr(:));
                spaces = repmat('    ',size(states, 1), 1);
                infoStr = [states, spaces, units, spaces, indices];
                
                fprintf('\n');
                for i = 1:size(infoStr, 1)
                    fprintf(infoStr(i,:));
                    fprintf('\n');
                end
                fprintf('\n');
            end
        end
    end


end %classdef

% Other helper functions
function s = squared
    s = char(178);
end

function s = acceleration
    s = ['m/s', squared];
end

function validateMeasurement(meas, argName)
validateattributes(meas, {'double','single'}, ...
    {'real','finite','2d','nrows',1,'ncols',3,'nonempty'}, ...
    '', ...
    argName);
end

function g = gravms2()
    g = fusion.internal.UnitConversions.geeToMetersPerSecondSquared(1);
end
