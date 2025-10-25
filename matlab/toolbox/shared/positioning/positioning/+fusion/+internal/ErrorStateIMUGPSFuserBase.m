classdef (Hidden) ErrorStateIMUGPSFuserBase < ...
        fusion.internal.INSFilterESKF & fusion.internal.mixin.IMUSynchronous
%ErrorStateIMUGPSFuserBase Base class for insfilterErrorState
%
%   This class is for internal use only. It may be removed in the future.

%   Copyright 2018-2020 The MathWorks, Inc.

%#codegen
    
    properties (Dependent)
        % KF Values
        
        %State Nominal state vector
        %   Specify the state vector as a 17-element real finite vector. 
        %   The units and indices for each state are as follows:
        %
        %       States                            Units    Index
        %       Orientation (quaternion parts)             1:4  
        %       Position (NAV)                    m        5:7  
        %       Velocity (NAV)                    m/s      8:10 
        %       Gyroscope Bias (XYZ)              rad/s    11:13
        %       Accelerometer Bias (XYZ)          m/s^2    14:16
        %       Visual Odometry Scale                      17   
        %
        %   The default value is [1; zeros(15,1); 1].
        State
        %StateCovariance Error covariance matrix
        %   Specify the value of the error covariance matrix. The error
        %   covariance matrix is a 16-by-16 matrix. The default value is
        %   ones(16).
        StateCovariance
    end
    properties
        % Process noises
        
        %AccelerometerNoise Noise in the accelerometer signal (m/s^2)^2
        %   Specify the noise in the accelerometer data as a positive 
        %   scalar or 3-element row vector in (m/s^2)^2. The default value 
        %   is [1.0e-4 1.0e-4 1.0e-4].
        AccelerometerNoise = 1e-4*ones(1,3);
        %GyroscopeNoise Noise in the gyroscope signal (rad/s)^2
        %   Specify the noise in the gyroscope data as a positive scalar or
        %   3-element row vector in (rad/s)^2. The default value is 
        %   [1.0e-6 1.0e-6 1.0e-6].
        GyroscopeNoise = 1e-6*ones(1,3);
        %AccelerometerBiasNoise Noise in the accelerometer bias (m/s^2)^2
        %   Specify the noise in the accelerometer bias as a positive 
        %   scalar or 3-element row vector in (m/s^2)^2. The default value 
        %   is [1.0e-4 1.0e-4 1.0e-4].
        AccelerometerBiasNoise = 1e-4*ones(1,3);
        %GyroscopeBiasNoise Noise in the gyroscope bias (rad/s)^2
        %   Specify the noise in the gyroscope bias as a positive scalar or
        %   3-element row vector in (rad/s)^2. The default value is 
        %   [1.0e-9 1.0e-9 1.0e-9].
        GyroscopeBiasNoise = 1e-9*ones(1,3);
    end
    
    properties (Hidden, Constant)
        NumStates = 17;
        NumErrorStates = 16;
    end

    properties (Access = protected)
        pState = [1; zeros(15,1); 1];
        pStateCovariance = ones(16);
    end

    methods
        function obj = ErrorStateIMUGPSFuserBase(varargin)
            obj = obj@fusion.internal.INSFilterESKF;
            matlabshared.fusionutils.internal.setProperties(obj, nargin, varargin{:});

            % Cache the math object
            obj.ReferenceFrameObject = fusion.internal.frames.ReferenceFrame.getMathObject( ...
                obj.ReferenceFrame);
        end
        
        function predict(obj, accelMeas, gyroMeas)
        %PREDICT(FILT, ACCELMEAS, GYROMEAS) fuses the accelerometer and
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
            
            rf = obj.ReferenceFrameObject;
            % Invert the accelerometer signal if linear acceleration is
            % negative in the reference frame.
            accelMeas = rf.LinAccelSign.*accelMeas;
            
            x = getState(obj);
            setState(obj, stateTransition(obj, x, accelMeas(:), gyroMeas(:)));
            
            F = stateTransitionJacobian(obj, x, accelMeas(:), gyroMeas(:));
            G = processNoiseJacobian(obj, x);
            U = processNoiseCovariance(obj);
            setStateCovariance(obj, predictCovEqn(obj, getStateCovariance(obj), F, U, G));
        end
        
        function [posRes, orientRes, resCov] = residualmvo(obj, voPos, RposIn, voOrientIn, RorientIn)
        %RESIDUALMVO Residuals and residual covariance from MVO
        %
        %   [POSRES,ORIENTRES,RESCOV] = RESIDUALMVO(FILT, VOPOS, RPOS,
        %   VOORIENT, RORIENT) uses the position and orientation data in
        %   the monocular visual odometry (MVO) measurement to compute
        %   residuals and residual covariance.
        %
        %   The inputs to RESIDUALMVO are defined as follows:
        %
        %       VOPOS       Position of the camera in the NAV
        %                   coordinate system specified as a real finite
        %                   3-element row vector in meters.
        %
        %       RPOS        Measurement covariance matrix of the monocular
        %                   visual odometry position measurements in the
        %                   local NAV coordinate system. This is specified
        %                   as a real finite scalar, 3-element vector, or 
        %                   3-by-3 matrix in meters squared.
        %
        %       VOORIENT    Orientation of the camera with respect to the
        %                   NAV coordinate system specified as a scalar
        %                   quaternion or a single or double 3-by-3
        %                   rotation matrix. The quaternion or rotation
        %                   matrix is a frame rotation from the NAV
        %                   coordinate system to the current camera
        %                   coordinate system.
        %
        %       RORIENT     Measurement covariance matrix of the monocular
        %                   visual odometry orientation measurements. This
        %                   is specified as a real finite scalar, 3-element
        %                   vector, or 3-by-3 matrix in radians squared.
        %   The outputs are:
        %       POSRES      The 3-by-1 position residuals in meters
        %       ORIENTRES   The 3-by-1 rotation vector residuals in rads
        %       RESCOV      The 6-by-6 residual covariance
        %
        %   Example:
        %
        %       % Reject measurements that have a normalized residual above
        %       % a specified threshold.
        %       outlierThreshold = 3;
        %       filt = insfilterErrorState;
        %       posMeas = [10 10 10];
        %       Rpos = 0.1;
        %       orientMeas = quaternion([90 90 90], 'eulerd', ...
        %           'ZYX', 'frame');
        %       Rorient = 0.1;
        %       [posRes, orientRes, resCov] = residualmvo(filt, ...
        %           posMeas, Rpos, orientMeas, Rorient);
        %       normRes = [posRes, orientRes] ./ sqrt( diag(resCov).' );
        %       if all(abs(normRes) <= outlierThreshold)
        %           fusemvo(filt, posMeas, Rpos, orientMeas, Rorient);
        %       else
        %           fprintf('Outlier detected and disregarded.\n');
        %       end
        %
        %   See also fusemvo.
        
            validateattributes(voPos, {'double','single'}, ...
                {'real','finite','2d','nrows',1,'ncols',3,'nonempty'}, ...
                '', ...
                'voPos');
            if isa(voOrientIn, 'quaternion')
                validateattributes(voOrientIn, {'quaternion'}, ...
                    {'finite', 'scalar'}, ...
                    '', ...
                    'voOrient');
                voOrient = voOrientIn;
            else
                validateattributes(voOrientIn, {'double','single'}, ...
                    {'real','finite','2d','nrows',3,'ncols',3,'nonempty'}, ...
                    '', ...
                    'voOrient');
                voOrient = quaternion(voOrientIn, 'rotmat', 'frame');
            end
            Rpos = validateExpandNoise(obj, RposIn, 3, 'Rpos', '3');
            Rorient = validateExpandNoise(obj, RorientIn, 3, 'Rorient', '3');
            
            x = getState(obj);
            P = getStateCovariance(obj);
            
            z = [voPos(:); compact(voOrient).'];
            h = measurementMVO(obj, x);
            posRes = z(1:3) - h(1:3);
            zQ = quaternion(z(4:7).');
            hQ = quaternion(h(4:7).');
            deltaQ = conj(hQ) * zQ;
            orientRes = rotvec(deltaQ).';
            zminush = [posRes; orientRes];
            
            H = cast(measurementJacobianMVO(obj, x), 'like', x);
            
            R = cast(blkdiag(Rpos, Rorient), 'like', x);
            
            [~, resCov] = privInnov(obj, P, zminush, H, R);
           
            posRes = reshape(posRes, 1, []);
            orientRes = reshape(orientRes, 1, []);
        end
        
        function [pRes, oRes, resCov] = fusemvo(obj, voPos, RposIn, voOrientIn, RorientIn)
        %FUSEMVO Correct states using monocular visual odometry
        %
        %   [PRES, ORES, RESCOV] = FUSEMVO(FILT, VOPOS, RPOS, VOORIENT,
        %   RORIENT) fuses the position and orientation data in the
        %   monocular visual odometry measurement to correct the state and
        %   state estimation error covariance.
        %
        %   The inputs to FUSEMVO are defined as follows:
        %
        %       VOPOS       Position of the camera in the NAV
        %                   coordinate system specified as a real finite
        %                   3-element row vector in meters.
        %
        %       RPOS        Measurement covariance matrix of the monocular
        %                   visual odometry position measurements in the
        %                   local NAV coordinate system. This is specified
        %                   as a real finite scalar, 3-element vector, or 
        %                   3-by-3 matrix in meters squared.
        %
        %       VOORIENT    Orientation of the camera with respect to the
        %                   NAV coordinate system specified as a scalar
        %                   quaternion or a single or double 3-by-3
        %                   rotation matrix. The quaternion or rotation
        %                   matrix is a frame rotation from the NAV
        %                   coordinate system to the current camera
        %                   coordinate system.
        %
        %       RORIENT     Measurement covariance matrix of the monocular
        %                   visual odometry orientation measurements. This
        %                   is specified as a real finite scalar, 3-element
        %                   vector, or 3-by-3 matrix in radians squared.
        %   The outputs are:
        %       PRES        The 3-by-1 position residual in meters
        %       ORES        The 3-by-1 rotation vector residual in rads
        %       RESCOV      The 6-by-6 residual covariance
        %
        %   See also residualmvo.
        
            validateattributes(voPos, {'double','single'}, ...
                {'real','finite','2d','nrows',1,'ncols',3,'nonempty'}, ...
                '', ...
                'voPos');
            if isa(voOrientIn, 'quaternion')
                validateattributes(voOrientIn, {'quaternion'}, ...
                    {'finite', 'scalar'}, ...
                    '', ...
                    'voOrient');
                voOrient = voOrientIn;
            else
                validateattributes(voOrientIn, {'double','single'}, ...
                    {'real','finite','2d','nrows',3,'ncols',3,'nonempty'}, ...
                    '', ...
                    'voOrient');
                voOrient = quaternion(voOrientIn, 'rotmat', 'frame');
            end
            Rpos = validateExpandNoise(obj, RposIn, 3, 'Rpos', '3');
            Rorient = validateExpandNoise(obj, RorientIn, 3, 'Rorient', '3');
            
            x = getState(obj);
            P = getStateCovariance(obj);
            
            z = [voPos(:); compact(voOrient).'];
            h = measurementMVO(obj, x);
            pRes = z(1:3) - h(1:3);
            zQ = quaternion(z(4:7).');
            hQ = quaternion(h(4:7).');
            deltaQ = conj(hQ) * zQ;
            oRes = rotvec(deltaQ).';
            
            zminush = [pRes; oRes];
            
            H = cast(measurementJacobianMVO(obj, x), 'like', x);
            
            R = cast(blkdiag(Rpos, Rorient), 'like', x);
            
            resCov = H*P*(H.') + R;
            K = P*(H.') / resCov;
            errorState = K*zminush;
            
            setStateCovariance(obj, (eye(size(K*H)) - K*H)*P*((eye(size(K*H)) - K*H).') ...
                + K*R*(K.'));
           
            pRes = reshape(pRes, 1, []);
            oRes = reshape(oRes, 1, []);

            injectError(obj, errorState);
            resetError(obj);
        end
        
        function [res, resCov] = residualgps(obj, gpsPos, RposIn, gpsVel, RvelIn)
        %RESIDUALGPS Residuals and residual covariance from GPS 
        %   [RES, RESCOV] = residualgps(FUSE, LLA, RPOS) uses GPS position
        %   data to compute residuals and residual covariance.
        %
        %   [RES, RESCOV] = residualgps(FUSE, LLA, RPOS, VEL, RVEL) uses
        %   GPS position and velocity data to compute residuals and
        %   residual covariance. The inputs are:
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
        %       RES            - 1-by-6 position and velocity residuals
        %                        in meters (m) and m/s, respectively
        %       RESCOV         - 6-by-6 residual covariance
        %
        %   Example:
        %
        %       % Reject measurements that have a normalized residual above
        %       % a specified threshold.
        %       outlierThreshold = 3;
        %       filt = insfilterErrorState;
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
        
            validateMeasurement(gpsPos, 'gpsPos');
            Rpos = validateExpandNoise(obj, RposIn, 3, 'Rpos', '3');
            if (nargin == 3)
                x = getState(obj);
                P = getStateCovariance(obj);

                rf = obj.ReferenceFrameObject;
                z = rf.lla2frame(gpsPos, obj.ReferenceLocation).';
                h = measurementGPSPosition(obj, x);
                zminush = z - h;

                H = measurementJacobianGPSPosition(obj, x);

                R = Rpos;

                [res, resCov] = privInnov(obj, P, zminush, H, R);
            else
                validateattributes(gpsVel, {'double','single'}, ...
                    {'real','finite','2d','nrows',1,'ncols',3,'nonempty'}, ...
                    '', ...
                    'gpsVel');
                Rvel = validateExpandNoise(obj, RvelIn, 3, 'Rvel', '3');

                x = getState(obj);
                P = getStateCovariance(obj);

                rf = obj.ReferenceFrameObject;
                z = [rf.lla2frame(gpsPos, obj.ReferenceLocation).'; gpsVel(:)];
                h = measurementGPS(obj, x);
                zminush = z - h;

                H = measurementJacobianGPS(obj, x);

                R = blkdiag(Rpos, Rvel);

                [res, resCov] = privInnov(obj, P, zminush, H, R);
            end
        end
        
        function  [res, resCov] = fusegps(obj, gpsPos, RposIn, gpsVel, RvelIn)
        %FUSEGPS Correct state estimates using GPS 
        %   [RES, RESCOV] = fusegps(FUSE, LLA, RPOS) fuses GPS position
        %   data to correct the state estimate.
        %
        %   [RES, RESCOV] = fusegps(FUSE, LLA, RPOS, VEL, RVEL)
        %   fuses GPS position and velocity data to correct the state 
        %   estimate. The inputs are:
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
        %       RES              - 1-by-6 position and velocity residuals
        %                          in meters (m) and m/s, respectively
        %       RESCOV           - 6-by-6 residual covariance
        %
        %   See also residualgps.
        
            validateMeasurement(gpsPos, 'gpsPos');
            Rpos = validateExpandNoise(obj, RposIn, 3, 'Rpos', '3');
            if (nargin == 3)
                [res, resCov] = fusegpsPosition(obj, gpsPos, Rpos);
            else
                validateattributes(gpsVel, {'double','single'}, ...
                    {'real','finite','2d','nrows',1,'ncols',3,'nonempty'}, ...
                    '', ...
                    'gpsVel');
                Rvel = validateExpandNoise(obj, RvelIn, 3, 'Rvel', '3');

                x = getState(obj);

                rf = obj.ReferenceFrameObject;
                z = [rf.lla2frame(gpsPos, obj.ReferenceLocation).'; gpsVel(:)];
                h = measurementGPS(obj, x);
                zminush = z - h;

                H = measurementJacobianGPS(obj, x);

                R = blkdiag(Rpos, Rvel);

                [res, resCov] = correctEqn(obj, zminush, H, R);
            end
        end
        
        function reset(obj)
            %RESET Set state and state error covariance to default values 
            %   reset(FUSE) resets the State and StateCovariance to their 
            %   default values and resets the internal states of the 
            %   filter.
            
            setState(obj, cast([1; zeros(15,1); 1], 'like', getState(obj)));
            setStateCovariance(obj,  ones(16, 'like', getStateCovariance(obj)));
        end
    end
    
    methods % Set methods
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
    end
    
    methods (Access = protected)
        function setState(obj, val)
            validateattributes(val, {'double','single'}, ...
                {'real','finite','vector','numel',fusion.internal.ErrorStateIMUGPSFuserBase.NumStates}, ...
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
                'numel',(fusion.internal.ErrorStateIMUGPSFuserBase.NumErrorStates).^2, ...
                'nonempty','nonsparse'}, ...
                '', ...
                'StateCovariance');
            obj.pStateCovariance = val;
        end
        function val = getStateCovariance(obj)
            val = obj.pStateCovariance;
        end
        function s = saveObject(obj)
            % Call each base class's saveObject 
            s = saveObject@fusion.internal.INSFilterESKF(obj);
            s = saveObject@fusion.internal.mixin.IMUSynchronous(obj,s);

            s.State = obj.State; 
            s.StateCovariance = obj.StateCovariance; 
            s.AccelerometerNoise = obj.AccelerometerNoise;
            s.GyroscopeNoise = obj.GyroscopeNoise;
            s.AccelerometerBiasNoise = obj.AccelerometerBiasNoise;
            s.GyroscopeBiasNoise = obj.GyroscopeBiasNoise;
        end
        
        function loadObject(obj, s)
            % Call both base class's loadObject methods
            loadObject@fusion.internal.INSFilterESKF(obj, s);
            loadObject@fusion.internal.mixin.IMUSynchronous(obj, s);

            obj.State = s.State;
            obj.StateCovariance = s.StateCovariance;
            obj.AccelerometerNoise = s.AccelerometerNoise;
            obj.GyroscopeNoise = s.GyroscopeNoise;
            obj.AccelerometerBiasNoise = s.AccelerometerBiasNoise;
            obj.GyroscopeBiasNoise = s.GyroscopeBiasNoise;
        end
        
        function pos = getPosition(obj)
            st = getState(obj);
            pos = st(5:7).';
        end
        
        function orient = getOrientation(obj)
            st = getState(obj);
            orient = quaternion(st(1:4).');
        end
        
        function vel = getVelocity(obj)
            st = getState(obj);
            vel = st(8:10).';
        end
        
        % Predict Helper Functions
        function x = stateTransition(obj, x, accelMeas, gyroMeas)
            quat = quaternion(x(1:4).');
            pos = x(5:7);
            vel = x(8:10);
            gyroBias = x(11:13);
            accelBias = x(14:16);
            scaleVO = x(17);
            
            dt = 1 ./ obj.IMUSampleRate;
            
            newQuat = quat * quaternion([1, 0.5*dt*(gyroMeas(:).'-gyroBias(:).')]); %quaternion((gyroMeas.'-gyroBias.')*dt, 'rotvec');
            newPos = pos + vel*dt;
            
            rf = obj.ReferenceFrameObject;
            grav = zeros(1,3, 'like', x);
            grav(rf.GravityIndex) = -rf.GravitySign*rf.GravityAxisSign*gravms2();
            newAcc = rotatepoint(quat, accelMeas(:).' - accelBias(:).') - grav(:).';
            newVel = vel + newAcc(:) * dt;
            newGyroBias = gyroBias;
            newAccelBias = accelBias;
            newScaleVO = scaleVO;
            x = [compact(normalize(newQuat)).'; newPos(:); newVel(:); newGyroBias(:); newAccelBias(:); newScaleVO(:)];
        end
        
        function F = stateTransitionJacobian(obj, x, accelMeas, ~) %gyroMeas)
            qw = x(1);
            qx = x(2);
            qy = x(3);
            qz = x(4);
            pn = x(5); %#ok<NASGU>
            pe = x(6); %#ok<NASGU>
            pd = x(7); %#ok<NASGU>
            vn = x(8); %#ok<NASGU>
            ve = x(9); %#ok<NASGU>
            vd = x(10); %#ok<NASGU>
            wbx = x(11); %#ok<NASGU>
            wby = x(12); %#ok<NASGU>
            wbz = x(13); %#ok<NASGU>
            abx = x(14);
            aby = x(15);
            abz = x(16);
            scaleVO = x(17); %#ok<NASGU>
            
            dt = 1 ./ obj.IMUSampleRate;
            
            amx = accelMeas(1);
            amy = accelMeas(2);
            amz = accelMeas(3);
            
            F = [ ...  
                1,                                                                                                                 0,                                                                                                                 0, 0, 0, 0,  0,  0,  0, -dt*(qw^2 + qx^2 - qy^2 - qz^2),          dt*(2*qw*qz - 2*qx*qy),         -dt*(2*qw*qy + 2*qx*qz),                               0,                               0,                               0, 0; ...
                0,                                                                                                                 1,                                                                                                                 0, 0, 0, 0,  0,  0,  0,         -dt*(2*qw*qz + 2*qx*qy), -dt*(qw^2 - qx^2 + qy^2 - qz^2),          dt*(2*qw*qx - 2*qy*qz),                               0,                               0,                               0, 0; ...
                0,                                                                                                                 0,                                                                                                                 1, 0, 0, 0,  0,  0,  0,          dt*(2*qw*qy - 2*qx*qz),         -dt*(2*qw*qx + 2*qy*qz), -dt*(qw^2 - qx^2 - qy^2 + qz^2),                               0,                               0,                               0, 0; ...
                0,                                                                                                                 0,                                                                                                                 0, 1, 0, 0, dt,  0,  0,                               0,                               0,                               0,                               0,                               0,                               0, 0; ...
                0,                                                                                                                 0,                                                                                                                 0, 0, 1, 0,  0, dt,  0,                               0,                               0,                               0,                               0,                               0,                               0, 0; ...
                0,                                                                                                                 0,                                                                                                                 0, 0, 0, 1,  0,  0, dt,                               0,                               0,                               0,                               0,                               0,                               0, 0; ...
                0, -dt*((abz - amz)*(qw^2 - qx^2 - qy^2 + qz^2) - (abx - amx)*(2*qw*qy - 2*qx*qz) + (aby - amy)*(2*qw*qx + 2*qy*qz)),  dt*((aby - amy)*(qw^2 - qx^2 + qy^2 - qz^2) + (abx - amx)*(2*qw*qz + 2*qx*qy) - (abz - amz)*(2*qw*qx - 2*qy*qz)), 0, 0, 0,  1,  0,  0,                               0,                               0,                               0, -dt*(qw^2 + qx^2 - qy^2 - qz^2),          dt*(2*qw*qz - 2*qx*qy),         -dt*(2*qw*qy + 2*qx*qz), 0; ...
                dt*((abz - amz)*(qw^2 - qx^2 - qy^2 + qz^2) - (abx - amx)*(2*qw*qy - 2*qx*qz) + (aby - amy)*(2*qw*qx + 2*qy*qz)),                                                                                                                 0, -dt*((abx - amx)*(qw^2 + qx^2 - qy^2 - qz^2) - (aby - amy)*(2*qw*qz - 2*qx*qy) + (abz - amz)*(2*qw*qy + 2*qx*qz)), 0, 0, 0,  0,  1,  0,                               0,                               0,                               0,         -dt*(2*qw*qz + 2*qx*qy), -dt*(qw^2 - qx^2 + qy^2 - qz^2),          dt*(2*qw*qx - 2*qy*qz), 0; ...
                -dt*((aby - amy)*(qw^2 - qx^2 + qy^2 - qz^2) + (abx - amx)*(2*qw*qz + 2*qx*qy) - (abz - amz)*(2*qw*qx - 2*qy*qz)),  dt*((abx - amx)*(qw^2 + qx^2 - qy^2 - qz^2) - (aby - amy)*(2*qw*qz - 2*qx*qy) + (abz - amz)*(2*qw*qy + 2*qx*qz)),                                                                                                                 0, 0, 0, 0,  0,  0,  1,                               0,                               0,                               0,          dt*(2*qw*qy - 2*qx*qz),         -dt*(2*qw*qx + 2*qy*qz), -dt*(qw^2 - qx^2 - qy^2 + qz^2), 0; ...
                0,                                                                                                                 0,                                                                                                                 0, 0, 0, 0,  0,  0,  0,                               1,                               0,                               0,                               0,                               0,                               0, 0; ...
                0,                                                                                                                 0,                                                                                                                 0, 0, 0, 0,  0,  0,  0,                               0,                               1,                               0,                               0,                               0,                               0, 0; ...
                0,                                                                                                                 0,                                                                                                                 0, 0, 0, 0,  0,  0,  0,                               0,                               0,                               1,                               0,                               0,                               0, 0; ...
                0,                                                                                                                 0,                                                                                                                 0, 0, 0, 0,  0,  0,  0,                               0,                               0,                               0,                               1,                               0,                               0, 0; ...
                0,                                                                                                                 0,                                                                                                                 0, 0, 0, 0,  0,  0,  0,                               0,                               0,                               0,                               0,                               1,                               0, 0; ...
                0,                                                                                                                 0,                                                                                                                 0, 0, 0, 0,  0,  0,  0,                               0,                               0,                               0,                               0,                               0,                               1, 0; ...
                0,                                                                                                                 0,                                                                                                                 0, 0, 0, 0,  0,  0,  0,                               0,                               0,                               0,                               0,                               0,                               0, 1; ...
                ];
        end
        
        function G = processNoiseJacobian(obj, x)
            qw = x(1);
            qx = x(2);
            qy = x(3);
            qz = x(4);
            pn = x(5); %#ok<NASGU>
            pe = x(6); %#ok<NASGU>
            pd = x(7); %#ok<NASGU>
            vn = x(8); %#ok<NASGU>
            ve = x(9); %#ok<NASGU>
            vd = x(10); %#ok<NASGU>
            wbx = x(11); %#ok<NASGU>
            wby = x(12); %#ok<NASGU>
            wbz = x(13); %#ok<NASGU>
            abx = x(14); %#ok<NASGU>
            aby = x(15); %#ok<NASGU>
            abz = x(16); %#ok<NASGU>
            scaleVO = x(17); %#ok<NASGU>
            
            dt = 1 ./ obj.IMUSampleRate;
            
            G = [ ...
                0,                              0,                              0, dt*(qw^2 + qx^2 - qy^2 - qz^2),        -dt*(2*qw*qz - 2*qx*qy),         dt*(2*qw*qy + 2*qx*qz),  0,  0,  0,  0,  0,  0; ...
                0,                              0,                              0,         dt*(2*qw*qz + 2*qx*qy), dt*(qw^2 - qx^2 + qy^2 - qz^2),        -dt*(2*qw*qx - 2*qy*qz),  0,  0,  0,  0,  0,  0; ...
                0,                              0,                              0,        -dt*(2*qw*qy - 2*qx*qz),         dt*(2*qw*qx + 2*qy*qz), dt*(qw^2 - qx^2 - qy^2 + qz^2),  0,  0,  0,  0,  0,  0; ...
                0,                              0,                              0,                              0,                              0,                              0,  0,  0,  0,  0,  0,  0; ...
                0,                              0,                              0,                              0,                              0,                              0,  0,  0,  0,  0,  0,  0; ...
                0,                              0,                              0,                              0,                              0,                              0,  0,  0,  0,  0,  0,  0; ...
                dt*(qw^2 + qx^2 - qy^2 - qz^2),        -dt*(2*qw*qz - 2*qx*qy),         dt*(2*qw*qy + 2*qx*qz),                              0,                              0,                              0,  0,  0,  0,  0,  0,  0; ...
                dt*(2*qw*qz + 2*qx*qy), dt*(qw^2 - qx^2 + qy^2 - qz^2),        -dt*(2*qw*qx - 2*qy*qz),                              0,                              0,                              0,  0,  0,  0,  0,  0,  0; ...
                -dt*(2*qw*qy - 2*qx*qz),         dt*(2*qw*qx + 2*qy*qz), dt*(qw^2 - qx^2 - qy^2 + qz^2),                              0,                              0,                              0,  0,  0,  0,  0,  0,  0; ...
                0,                              0,                              0,                              0,                              0,                              0,  0,  0,  0, dt,  0,  0; ...
                0,                              0,                              0,                              0,                              0,                              0,  0,  0,  0,  0, dt,  0; ...
                0,                              0,                              0,                              0,                              0,                              0,  0,  0,  0,  0,  0, dt; ...
                0,                              0,                              0,                              0,                              0,                              0, dt,  0,  0,  0,  0,  0; ...
                0,                              0,                              0,                              0,                              0,                              0,  0, dt,  0,  0,  0,  0; ...
                0,                              0,                              0,                              0,                              0,                              0,  0,  0, dt,  0,  0,  0; ...
                0,                              0,                              0,                              0,                              0,                              0,  0,  0,  0,  0,  0,  0; ...
                ];
        end
        
        function U = processNoiseCovariance(obj)
            
            U = obj.IMUSampleRate .* blkdiag(diag(obj.AccelerometerNoise), ...
                diag(obj.GyroscopeNoise), ...
                diag(obj.AccelerometerBiasNoise), ...
                diag(obj.GyroscopeBiasNoise));
        end
        
        % Correct Helper Functions
        function h = measurementGPS(~, x)
            quat = quaternion(x(1:4).'); %#ok<NASGU>
            pos = x(5:7);
            vel = x(8:10);
            gyroBias = x(11:13); %#ok<NASGU>
            accelBias = x(14:16); %#ok<NASGU>
            scaleVO = x(17); %#ok<NASGU>
            
            h = [pos; vel];
        end
        
        function H = measurementJacobianGPS(~, x)
            qw = x(1); %#ok<NASGU>
            qx = x(2); %#ok<NASGU>
            qy = x(3); %#ok<NASGU>
            qz = x(4); %#ok<NASGU>
            pn = x(5); %#ok<NASGU>
            pe = x(6); %#ok<NASGU>
            pd = x(7); %#ok<NASGU>
            vn = x(8); %#ok<NASGU>
            ve = x(9); %#ok<NASGU>
            vd = x(10); %#ok<NASGU>
            wbx = x(11); %#ok<NASGU>
            wby = x(12); %#ok<NASGU>
            wbz = x(13); %#ok<NASGU>
            abx = x(14); %#ok<NASGU>
            aby = x(15); %#ok<NASGU>
            abz = x(16); %#ok<NASGU>
            scale = x(17); %#ok<NASGU>
            
            H = [ ...
                0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0; ...
                0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0; ...
                0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0; ...
                0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0; ...
                0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0; ...
                0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0; ...
                ];
        end
        
        function [innov, iCov] = fusegpsPosition(obj, gpsPos, Rpos)
            x = getState(obj);

            rf = obj.ReferenceFrameObject;
            z = rf.lla2frame(gpsPos, obj.ReferenceLocation).';
            h = measurementGPSPosition(obj, x);
            zminush = z - h;

            H = measurementJacobianGPSPosition(obj, x);
            
            R = Rpos;

            [innov, iCov] = correctEqn(obj, zminush, H, R);
        end
        
        function h = measurementGPSPosition(~, x)
            quat = quaternion(x(1:4).'); %#ok<NASGU>
            pos = x(5:7);
            vel = x(8:10); %#ok<NASGU>
            gyroBias = x(11:13); %#ok<NASGU>
            accelBias = x(14:16); %#ok<NASGU>
            scaleVO = x(17); %#ok<NASGU>
            
            h = pos;
        end
        
        function H = measurementJacobianGPSPosition(~, x)
            qw = x(1); %#ok<NASGU>
            qx = x(2); %#ok<NASGU>
            qy = x(3); %#ok<NASGU>
            qz = x(4); %#ok<NASGU>
            pn = x(5); %#ok<NASGU>
            pe = x(6); %#ok<NASGU>
            pd = x(7); %#ok<NASGU>
            vn = x(8); %#ok<NASGU>
            ve = x(9); %#ok<NASGU>
            vd = x(10); %#ok<NASGU>
            wbx = x(11); %#ok<NASGU>
            wby = x(12); %#ok<NASGU>
            wbz = x(13); %#ok<NASGU>
            abx = x(14); %#ok<NASGU>
            aby = x(15); %#ok<NASGU>
            abz = x(16); %#ok<NASGU>
            scale = x(17); %#ok<NASGU>
            
            H = [ ...
                0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0; ...
                0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0; ...
                0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0; ...
                ];
        end
        
        function h = measurementMVO(~, x)
            quat = quaternion(x(1:4).');
            pos = x(5:7);
            vel = x(8:10); %#ok<NASGU>
            gyroBias = x(11:13); %#ok<NASGU>
            accelBias = x(14:16); %#ok<NASGU>
            scaleVO = x(17);
            
            h = [pos.*scaleVO; compact(quat).'];
        end
        
        function H = measurementJacobianMVO(~, x)
            qw = x(1); %#ok<NASGU>
            qx = x(2); %#ok<NASGU>
            qy = x(3); %#ok<NASGU>
            qz = x(4); %#ok<NASGU>
            pn = x(5); 
            pe = x(6);
            pd = x(7);
            vn = x(8); %#ok<NASGU>
            ve = x(9); %#ok<NASGU>
            vd = x(10); %#ok<NASGU>
            wbx = x(11); %#ok<NASGU>
            wby = x(12); %#ok<NASGU>
            wbz = x(13); %#ok<NASGU>
            abx = x(14); %#ok<NASGU>
            aby = x(15); %#ok<NASGU>
            abz = x(16); %#ok<NASGU>
            scale = x(17);
            
            % The lower-left identity is an estimate of the change in
            % quaternion.
            H = [ ...
                0,           0,           0, scale,     0,     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, pn; ...
                0,           0,           0,     0, scale,     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, pe; ...
                0,           0,           0,     0,     0, scale, 0, 0, 0, 0, 0, 0, 0, 0, 0, pd; ...
                1,           0,           0,     0,     0,     0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  0; ...
                0,           1,           0,     0,     0,     0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  0; ...
                0,           0,           1,     0,     0,     0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  0; ...
                ];
        end
        
        function injectError(obj, deltaX)
            x = getState(obj);
            
            quat = quaternion(x(1:4).');
            pos = x(5:7);
            vel = x(8:10);
            gyroBias = x(11:13);
            accelBias = x(14:16);
            scaleVO = x(17);
            
            quatErr = quaternion(deltaX(1:3).', 'rotvec');
            posErr = deltaX(4:6);
            velErr = deltaX(7:9);
            gyroBiasErr = deltaX(10:12);
            accelBiasErr = deltaX(13:15);
            scaleVOErr = deltaX(16);
            
            quat = quat .* quatErr;
            pos = pos + posErr;
            vel = vel + velErr;
            gyroBias = gyroBias + gyroBiasErr;
            accelBias = accelBias + accelBiasErr;
            scaleVO = scaleVO + scaleVOErr;
            
            setState(obj, ...
                [compact(normalize(quat)).'; pos; vel; gyroBias; accelBias; scaleVO]);
        end
        
        function resetError(obj)
            G = eye(obj.NumErrorStates);
            setStateCovariance(obj,  G* getStateCovariance(obj) *(G.'));
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
                    'Position', 5:7, ...
                    'Velocity', 8:10, ...
                    'GyroscopeBias', 11:13, ...
                    'AccelerometerBias', 14:16, ...
                    'VisualOdometryScale', 17);
                    
            else
                % Purely display
                stateCellArr = {'States', 'Orientation (quaternion parts)', ...
                    'Position (NAV)', ...
                    'Velocity (NAV)', ...
                    'Gyroscope Bias (XYZ)', 'Accelerometer Bias (XYZ)', ...
                    'Visual Odometry Scale'};
                unitCellArr = {'Units', '', 'm', 'm/s', 'rad/s', acceleration, ''};
                indexCellArr = {'Index', '1:4', '5:7', '8:10', '11:13', '14:16', '17'};
                
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

%Helper Functions
function str = squared
str = char(178);
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
