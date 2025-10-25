classdef (Hidden) AsyncMARGGPSFuserBase < fusion.internal.INSFilterEKF & ...
        positioning.internal.ContinuousEKFPredictor
%   This class is for internal use only. It may be removed in the future. 
%

%   Copyright 2018-2021 The MathWorks, Inc.


%#codegen

    properties
        %QuaternionNoise Quaternion process noise variance
        %   Specify the process noise variance of the orientation
        %   quaternion in the fusion algorithm as a scalar or 4-element
        %   vector. The default value of this property is 1e-6.
        QuaternionNoise = [1e-6 1e-6 1e-6 1e-6];

        %AngularVelocityNoise Angular velocity process noise variance (rad/s)^2 
        %   Specify the process noise variance of the angular velocity in
        %   the fusion algorithm as a scalar or 3-element vector. The angular
        %   velocity noise is specified in units of (rad/s)^2. The default
        %   value of this property is 5e-3 (rad/s)^2.
        AngularVelocityNoise = [5e-3 5e-3 5e-3]
        
        %PositionNoise Position process noise variance m^2
        %   Specify the process noise variance of the position 
        %   in the fusion algorithm as a scalar or 3-element vector. The
        %   position noise is specified in units of m^2. The default
        %   value of this property is 1e-6 m^2.
        PositionNoise = [1e-6 1e-6 1e-6];
        
        %VelocityNoise Velocity process noise variance (m/s)^2 
        %   Specify the process noise variance of the velocity 
        %   in the fusion algorithm as a scalar or 3-element vector. The
        %   velocity noise is specified in units of (m/s)^2. The default
        %   value of this property is 1e-6 (m/s)^2.
        VelocityNoise = [1e-6 1e-6 1e-6];

        %AccelerationNoise Acceleration process noise variance (m/s^2)^2 
        %   Specify the process noise variance of the acceleration 
        %   in the fusion algorithm as a scalar or 3-element vector. The
        %   acceleration noise is specified in units of (m/s^2)^2. The default
        %   value of this property is 50 (m/s^2)^2.
        AccelerationNoise = [50 50 50]

        %GyroscopeBiasNoise Process noise variance from the gyroscope bias (rad/s)^2 
        %   Specify the process noise variance of the bias in the gyroscope
        %   input to the fusion algorithm as a scalar or 3-element vector. The
        %   gyroscope bias noise is specified in units of (rad/s)^2. The
        %   default value of this property is 1e-10 (rad/s)^2.
        GyroscopeBiasNoise = [1e-10 1e-10 1e-10]
        
        %AccelerometerBiasNoise Process noise variance from the accelerometer bias (m/s^2)^2 
        %   Specify the process noise variance of the bias in the
        %   accelerometer input to the fusion algorithm as a scalar or
        %   3-element vector. The accelerometer bias noise is specified in
        %   units of (m/s^2)^2. The default value of this property is 1e-4
        %   (m/s^2)^2.
        AccelerometerBiasNoise = [1e-4 1e-4 1e-4]

        %GeomagneticVectorNoise Process noise variance for geomagnetic vector (uT^2) 
        %   Specify the process noise variance of the geomagnetic vector
        %   state estimate as a scalar or 3-element vector. The geomagnetic
        %   vector noise is specified in units of uT^2. The default value of
        %   this property is 1e-6 uT^2
        GeomagneticVectorNoise = [1e-6 1e-6 1e-6]

        %MagnetometerBiasNoise Process variance noise for magnetometer bias (uT^2)
        %   Specify the process noise variance of the magnetometer offset bias
        %   state estimate as a scalar or 3-element vector. The magnetometer
        %   offset bias noise is specified in units of uT^2. The default value
        %   of this property is 0.1 uT^2
        MagnetometerBiasNoise = [0.1 0.1 0.1]
    end
    
        % State and Error Covariance 
    
    properties (Dependent)
        %State State vector of the internal extended Kalman Filter 
        %   Specify the initial value of the extended Kalman filter state
        %   vector. The state values represent:
        %       State                           Units       Index
        %   Orientation (quaternion parts)                  1:4
        %   Angular Velocity (XYZ)              rad/s       5:7
        %   Position (NAV)                      m           8:10
        %   Velocity (NAV)                      m/s         11:13
        %   Acceleration (NED)                  m/s^2       14:16
        %   Accelerometer Bias (XYZ)            m/s^2       17:19
        %   Gyroscope Bias (XYZ)                rad/s       20:22
        %   Geomagnetic Field Vector (NAV)      uT          23:25
        %   Magnetometer Bias (XYZ)             uT          26:28
        State;
        %StateCovariance State error covariance for the internal extended Kalman Filter
        %   Specify the initial value of the error covariance matrix. The
        %   error covariance matrix is a 28-by-28 element matrix. The
        %   default value of this property is eye(28)*1e-3
        StateCovariance;
    end
    
    properties
    end
    
    properties (Hidden, Constant)
        NumStates = 28;
    end
    
    
    properties (Access = private, Constant)
        MAG_FIELD_INDEX = 23;
    end
    
    properties (Access = protected)
        pState = defaultState(fusion.internal.frames.ReferenceFrame.getDefault);
        pStateCovariance = defaultCov();
    end

    methods (Hidden)
        function obj = AsyncMARGGPSFuserBase(varargin)
            obj = obj@fusion.internal.INSFilterEKF;
            matlabshared.fusionutils.internal.setProperties(obj, nargin, varargin{:});
           
            % Cache the math object
            obj.ReferenceFrameObject = fusion.internal.frames.ReferenceFrame.getMathObject( ...
                obj.ReferenceFrame);

            % Set the state if the user specifies it, to ensure the initial
            % value is correct, regardless of the reference frame.
            for i = 1:2:numel(varargin)-1
                if strcmp(varargin{i}, 'State')
                    setState(obj, varargin{i+1});
                end
            end
        end    
    end
    

    methods % Public API

        function predict(obj, dt)
        %PREDICT Predict forward state estimates
        %   predict(FUSE, DT) Updates state estimates based on the motion
        %   model. The inputs are: 
        %
        %       FUSE    - insfilterAsync object
        %       DT      - Scalar delta time to propagate forward 

            xk = getState(obj);
            validateattributes(dt, {'double', 'single'}, ...
                {'scalar', 'finite', 'nonempty', 'real'}, '', ...
                'dt');
        
            P = getStateCovariance(obj);
            
            addProcNoise = additiveProcessNoiseFcn(obj);
            xdot = obj.stateTransFcn(xk);
            dfdx = obj.stateTransJacobianFcn(xk);
            
            Pdot = obj.predictCovarianceDerivative(P, dfdx, addProcNoise);
            xnext = obj.eulerIntegrate(xk, xdot, dt);
            Pnext = obj.eulerIntegrate(P, Pdot, dt);
            
            xnext = repairQuaternion(obj, xnext);

            setStateCovariance(obj, Pnext);
            setState(obj, xnext); 
        end
        
        function [res, resCov] = residualgps(obj, lla, RposIn, vel, RvelIn)
        %RESIDUALGPS Residuals and residual covariance from GPS 
        %   [RES, RESCOV] = residualgps(FUSE, LLA, RPOS) uses GPS position
        %   data to compute residuals and residual covariance.
        %
        %   [RES, RESCOV] = residualgps(FUSE, LLA, RPOS, VEL, RVEL) uses
        %   GPS position and velocity data to compute residuals and
        %   residual covariance. The inputs are:
        %       
        %       FUSE    - insfilterAsync object
        %       LLA     - 1-by-3 vector of latitude, longitude and altitude 
        %       RPOS    - scalar, 1-by-3, or 3-by-3 covariance of the
        %                 NAV position measurement error in m^2
        %       VEL     - 1-by-3 vector of NAV velocities in units of m/s
        %       RVEL    - scalar, 1-by-3, or 3-by-3 covariance of the
        %                 NAV velocity measurement error in (m/s)^2
        %
        %   The outputs are:
        %       RES            - 1-by-6 position and velocity residuals in 
        %                        meters (m) and m/s, respectively
        %       RESCOV         - 6-by-6 residual covariance
        %
        %   Example:
        %
        %       % Reject measurements that have a normalized residual above
        %       % a specified threshold.
        %       outlierThreshold = 3;
        %       filt = insfilterAsync;
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
        
            validateMeasurement(lla, 'latitude-longitude-altitude');
            Rposmat = obj.validateExpandNoise(RposIn,  3, ...
                'Rpos', '3'); 
            if (nargin == 3)
                x = getState(obj);
                
                rf = obj.ReferenceFrameObject;
                z = rf.lla2frame(lla, obj.ReferenceLocation).';
                h = measurementGPSPosition(obj, x);
                H = measurementJacobianGPSPosition(obj, x);
                
                [res, resCov] = privInnov(obj, getStateCovariance(obj), ...
                    h, H, z, Rposmat);
            else
                validateattributes(vel, {'double', 'single'}, ...
                    {'2d', 'ncols', 3, 'nrows', 1, 'nonempty', 'real'}, '', ...
                    'velocity');
                Rvelmat = obj.validateExpandNoise(RvelIn,  3, ...
                    'Rvel', '3'); 
                
                x = getState(obj);
                
                measNoise = blkdiag(Rposmat, Rvelmat);
                rf = obj.ReferenceFrameObject;
                pos = rf.lla2frame(lla, obj.ReferenceLocation);            
                z = [pos, vel].';
                h = gpsMeasFcn(obj, x);
                H = gpsMeasJacobianFcn(obj, x);
                
                [res, resCov] = privInnov(obj, getStateCovariance(obj), ...
                    h, H, z, measNoise);
            end
        end
        
        function [res, resCov] = fusegps(obj, lla, Rpos, vel, Rvel)
        %FUSEGPS Correct state estimates using GPS 
        %   [RES, RESCOV] = fusegps(FUSE, LLA, RPOS) fuses GPS position
        %   data to correct the state estimate.
        %
        %   [RES, RESCOV] = fusegps(FUSE, LLA, RPOS, VEL, RVEL)
        %   fuses GPS position and velocity data to correct the state 
        %   estimate. The inputs are:
        %       
        %       FUSE    - insfilterAsync object
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

            validateMeasurement(lla, 'latitude-longitude-altitude');
            Rposmat = obj.validateExpandNoise(Rpos,  3, ...
                'Rpos', '3');
            if (nargin == 3)
                [res, resCov] = fusegpsPosition(obj, lla, Rposmat);
            else
                validateattributes(vel, {'double', 'single'}, ...
                    {'2d', 'ncols', 3, 'nrows', 1, 'nonempty', 'real'}, '', ...
                    'velocity');
                Rvelmat = obj.validateExpandNoise(Rvel,  3, ...
                    'Rvel', '3'); 
                
                measNoise = blkdiag(Rposmat, Rvelmat);
                rf = obj.ReferenceFrameObject;
                pos = rf.lla2frame(lla, obj.ReferenceLocation);            
                z = [pos, vel].';
                [res, resCov] = basicCorrect(obj, z, @gpsMeasFcn, measNoise, ...
                    @gpsMeasJacobianFcn);
            end
        end
        
        function [res, resCov] = residualaccel(obj, accel, Raccel)
        %RESIDUALACCEL Residuals and residual covariance from accelerometer
        %   [RES,RESCOV] = residualaccel(FUSE, ACCEL, RACCEL) uses
        %   accelerometer data to compute residuals and residual
        %   covariance. The inputs are:
        %
        %       FUSE        - insfilterAsync object
        %       ACCEL       - 1-by-3 vector of acceleration in (m/s^2)
        %       RACCEL      - scalar, 1-by-3, or 3-by-3 covariance of the
        %                     accelerometer measurement error in (m/s^2)^2
        %
        %   The outputs are:
        %       RES         - 1-by-3 residuals in m/s^2
        %       RESCOV      - 3-by-3 residual covariance
        %
        %   Example:
        %
        %       % Reject measurements that have a normalized residual above
        %       % a specified threshold.
        %       outlierThreshold = 3;
        %       filt = insfilterAsync;
        %       meas = [3 -2 12];
        %       R = 0.1;
        %       [res, resCov] = residualaccel(filt, meas, R);
        %       normRes = res ./ sqrt( diag(resCov).' );
        %       if all(abs(normRes) <= outlierThreshold)
        %           fuseaccel(filt, meas, R);
        %       else
        %           fprintf('Outlier detected and disregarded.\n');
        %       end
        %
        %   See also fuseaccel.
            
            validateattributes(accel, {'double', 'single'}, ...
                {'2d', 'ncols', 3, 'nrows', 1, 'nonempty', 'real'}, '', ...
                'acceleration');
            
            Raccelmat = obj.validateExpandNoise(Raccel, 3, ...
                'Raccel', '3');
            
            x = getState(obj);
            z = accel(:);
            
            h = accelMeasFcn(obj, x);
            H = accelMeasJacobianFcn(obj, x);
            [res, resCov] = privInnov(obj, getStateCovariance(obj), h, H, z, Raccelmat);
        end

        function [res, resCov] = fuseaccel(obj, accel, Raccel)
        %FUSEACCEL Correct state estimates using accelerometer
        %   [RES, RESCOV] = fuseaccel(FUSE, ACCEL, RACCEL) fuses
        %   accelerometer data to correct the state estimate. The inputs
        %   are: 
        %       
        %       FUSE        - insfilterAsync object
        %       ACCEL       - 1-by-3 vector of acceleration in (m/s^2) 
        %       RACCEL      - scalar, 1-by-3, or 3-by-3 covariance of the
        %                     accelerometer measurement error in (m/s^2)^2
        %
        %   The outputs are:
        %       RES             - 1-by-3 residuals in m/s^2
        %       RESCOV          - 3-by-3 residual covariance
        %
        %   See also residualaccel.

            validateattributes(accel, {'double', 'single'}, ...
                {'2d', 'ncols', 3, 'nrows', 1, 'nonempty', 'real'}, '', ...
                'acceleration');

            Raccelmat = obj.validateExpandNoise(Raccel, 3, ...
                'Raccel', '3'); 

           z = accel(:);
           [res, resCov] = basicCorrect(obj, z, @accelMeasFcn, Raccelmat, ...
                @accelMeasJacobianFcn);
        end

        function [res, resCov] = residualgyro(obj, gyro, Rgyro)
        %RESIDUALGYRO Residuals and residual covariance gyroscope
        %   [RES, RESCOV] = residualgyro(FUSE, GYRO, RGYRO) uses gyroscope
        %   data to compute residuals and residual covariance. The inputs
        %   are:
        %       
        %       FUSE       - insfilterAsync object
        %       GYRO       - 1-by-3 vector of angular velocity measurements
        %                    in rad/s. 
        %       RGYRO      - scalar, 1-by-3, or 3-by-3 covariance of the
        %                    gyroscope measurement error in (rad/s)^2
        %
        %   The outputs are:
        %       RES        - 1-by-3 residuals in rad/s
        %       RESCOV     - 3-by-3 residual covariance
        %
        %   Example:
        %
        %       % Reject measurements that have a normalized residual above
        %       % a specified threshold.
        %       outlierThreshold = 3;
        %       filt = insfilterAsync;
        %       meas = [3 3 3];
        %       R = 0.1;
        %       [res, resCov] = residualgyro(filt, meas, R);
        %       normRes = res ./ sqrt( diag(resCov).' );
        %       if all(abs(normRes) <= outlierThreshold)
        %           fusegyro(filt, meas, R);
        %       else
        %           fprintf('Outlier detected and disregarded.\n');
        %       end
        %
        %   See also fusegyro.

            validateattributes(gyro, {'double', 'single'}, ...
                {'2d', 'ncols', 3, 'nrows', 1, 'nonempty', 'real'}, '', ...
                'gyro');

            Rgyromat = obj.validateExpandNoise(Rgyro, 3, ...
                'Rgyro', '3'); 

            x = getState(obj);
            
            z = gyro(:);
            h = gyroMeasFcn(obj, x);
            H = gyroMeasJacobianFcn(obj, x);
            [res, resCov] = privInnov(obj, getStateCovariance(obj), h, H, z, Rgyromat);
        end
        
        function [res, resCov] = fusegyro(obj, gyro, Rgyro)
        %FUSEGYRO Correct state estimates using gyroscope
        %   [RES, RESCOV] = fusegyro(FUSE, GYRO, RGYRO) fuses gyroscope
        %   data to correct the state estimate. The inputs are: 
        %       
        %       FUSE       - insfilterAsync object
        %       GYRO       - 1-by-3 vector of angular velocity measurements
        %                    in rad/s. 
        %       RGYRO      - scalar, 1-by-3, or 3-by-3 covariance of the
        %                    gyroscope measurement error in (rad/s)^2
        %
        %   The outputs are:
        %       RES             - 1-by-3 residuals in rad/s
        %       RESCOV          - 3-by-3 residual covariance
        %
        %   See also residualgyro.

            validateattributes(gyro, {'double', 'single'}, ...
                {'2d', 'ncols', 3, 'nrows', 1, 'nonempty', 'real'}, '', ...
                'gyro');

            Rgyromat = obj.validateExpandNoise(Rgyro, 3, ...
                'Rgyro', '3'); 

           z = gyro(:);
           [res, resCov] = basicCorrect(obj, z, @gyroMeasFcn, Rgyromat, ...
                @gyroMeasJacobianFcn);
        end

        function [res, resCov] = residualmag(obj, mag, Rmag)
        %RESIDUALMAG Residuals and residual covariance from magnetometer
        %   [RES, RESCOV] = residualmag(FUSE, MAG, RMAG) uses magnetometer
        %   data to compute residuals and residual covariance. The inputs
        %   are:
        %       
        %       FUSE      - insfilterAsync object
        %       MAG       - 1-by-3 vector of magnetic field measurements
        %                   in uT. 
        %       RMAG      - scalar, 1-by-3, or 3-by-3 covariance of the
        %                   magnetometer measurement error in uT^2
        %
        %   The outputs are:
        %       RES       - 1-by-3 residuals in uT
        %       RESCOV    - 3-by-3 residual covariance
        %
        %   Example:
        %
        %       % Reject measurements that have a normalized residual above
        %       % a specified threshold.
        %       outlierThreshold = 3;
        %       filt = insfilterAsync;
        %       meas = [0 0 0];
        %       R = 0.1;
        %       [res, resCov] = residualmag(filt, meas, R);
        %       normRes = res ./ sqrt( diag(resCov).' );
        %       if all(abs(normRes) <= outlierThreshold)
        %           fusemag(filt, meas, R);
        %       else
        %           fprintf('Outlier detected and disregarded.\n');
        %       end
        %
        %   See also fusemag.

            validateattributes(mag, {'double', 'single'}, ...
                {'2d', 'ncols', 3, 'nrows', 1, 'nonempty', 'real'}, '', ...
                'magneticField');

            Rmagmat = obj.validateExpandNoise(Rmag, 3, ...
                'Rmag', '3'); 

            x = getState(obj);
            
            z = mag(:);
            h = magMeasFcn(obj, x);
            H = magMeasJacobianFcn(obj, x);
            
            [res, resCov] = privInnov(obj, getStateCovariance(obj), h, H, z, Rmagmat);
        end
        
        function [res, resCov] = fusemag(obj, mag, Rmag)
        %FUSEMAG Correct state estimates using magnetometer
        %   [RES, RESCOV] = fusemag(FUSE, MAG, RMAG) fuses magnetometer data
        %   to correct the state estimate. The inputs are: 
        %       
        %       FUSE      - insfilterAsync object
        %       MAG       - 1-by-3 vector of magnetic field measurements
        %                   in uT. 
        %       RMAG      - scalar, 1-by-3, or 3-by-3 covariance of the
        %                   magnetometer measurement error in uT^2
        %
        %   The outputs are:
        %       RES             - 1-by-3 residuals in uT
        %       RESCOV          - 3-by-3 residual covariance
        %
        %   See also residualmag.

            validateattributes(mag, {'double', 'single'}, ...
                {'2d', 'ncols', 3, 'nrows', 1, 'nonempty', 'real'}, '', ...
                'magneticField');

            Rmagmat = obj.validateExpandNoise(Rmag, 3, ...
                'Rmag', '3'); 

           z = mag(:);
           [res, resCov] = basicCorrect(obj, z, @magMeasFcn, Rmagmat, ...
                @magMeasJacobianFcn);
        end
        
        function reset(obj)
        %RESET Reset internal states
        %   RESET(FUSE) resets the State, StateCovariance, and internal
        %   integrators to their default values.

            obj.privReset;
        end
    end

    methods % Public API - sets and gets

       function set.QuaternionNoise(obj,val)
            validateattributes(val, {'numeric'}, ...
                {'finite', 'real', 'positive', '2d', ...
                'nonnan', 'nonempty', 'nonsparse'}, ...
                '', 'QuaternionNoise' );
           
            % Enforce scalar or 4-element vector inputs.
            n = numel(val);
            coder.internal.assert((n == 1) || (n == 4), ... 
                'shared_positioning:insfilter:OneorFourElements', 'QuaternionNoise');

            obj.QuaternionNoise(:) = val(:).';
       end

       function set.AngularVelocityNoise(obj,val)
            validateattributes(val, {'numeric'}, ...
                {'finite', 'real', 'positive', '2d', ...
                'nonnan', 'nonempty', 'nonsparse'}, ...
                '', 'AngularVelocityNoise' );
           
            % Enforce scalar or 3-element vector inputs.
            n = numel(val);
            coder.internal.assert((n == 1) || (n == 3), ... 
                'shared_positioning:insfilter:OneorThreeElements', 'AngularVelocityNoise');

            obj.AngularVelocityNoise(:) = val(:).';
       end

       function set.PositionNoise(obj,val)
            validateattributes(val, {'numeric'}, ...
                {'finite', 'real', 'positive', '2d', ...
                'nonnan', 'nonempty', 'nonsparse'}, ...
                '', 'PositionNoise' );
           
            % Enforce scalar or 3-element vector inputs.
            n = numel(val);
            coder.internal.assert((n == 1) || (n == 3), ... 
                'shared_positioning:insfilter:OneorThreeElements', 'PositionNoise');

            obj.PositionNoise(:) = val(:).';
       end

       function set.VelocityNoise(obj,val)
            validateattributes(val, {'numeric'}, ...
                {'finite', 'real', 'positive', '2d', ...
                'nonnan', 'nonempty', 'nonsparse'}, ...
                '', 'VelocityNoise' );
           
            % Enforce scalar or 3-element vector inputs.
            n = numel(val);
            coder.internal.assert((n == 1) || (n == 3), ... 
                'shared_positioning:insfilter:OneorThreeElements', 'VelocityNoise');

            obj.VelocityNoise(:) = val(:).';
       end

       function set.AccelerationNoise(obj,val)
            validateattributes(val, {'numeric'}, ...
                {'finite', 'real', 'positive', '2d', ...
                'nonnan', 'nonempty', 'nonsparse'}, ...
                '', 'AccelerationNoise' );
           
            % Enforce scalar or 3-element vector inputs.
            n = numel(val);
            coder.internal.assert((n == 1) || (n == 3), ... 
                'shared_positioning:insfilter:OneorThreeElements', 'AccelerationNoise');

            obj.AccelerationNoise(:) = val(:).';
       end

       function set.GyroscopeBiasNoise(obj,val)
            validateattributes(val, {'numeric'}, ...
                {'finite', 'real', 'positive', '2d', ...
                'nonnan', 'nonempty', 'nonsparse'}, ...
                '', 'GyroscopeBiasNoise' );
           
            % Enforce scalar or 3-element vector inputs.
            n = numel(val);
            coder.internal.assert((n == 1) || (n == 3), ... 
                'shared_positioning:insfilter:OneorThreeElements', 'GyroscopeBiasNoise');

            obj.GyroscopeBiasNoise(:) = val(:).';
       end

       function set.AccelerometerBiasNoise(obj,val)
            validateattributes(val, {'numeric'}, ...
                {'finite', 'real', 'positive', '2d', ...
                'nonnan', 'nonempty', 'nonsparse'}, ...
                '', 'AccelerometerBiasNoise' );
           
            % Enforce scalar or 3-element vector inputs.
            n = numel(val);
            coder.internal.assert((n == 1) || (n == 3), ... 
                'shared_positioning:insfilter:OneorThreeElements', 'AccelerometerBiasNoise');

            obj.AccelerometerBiasNoise(:) = val(:).';
       end

       function set.GeomagneticVectorNoise(obj,val)
            validateattributes(val, {'numeric'}, ...
                {'finite', 'real', 'positive', '2d', ...
                'nonnan', 'nonempty', 'nonsparse'}, ...
                '', 'GeomagneticVectorNoise' );
           
            % Enforce scalar or 3-element vector inputs.
            n = numel(val);
            coder.internal.assert((n == 1) || (n == 3), ... 
                'shared_positioning:insfilter:OneorThreeElements', 'GeomagneticVectorNoise');

            obj.GeomagneticVectorNoise(:) = val(:).';
       end

       function set.MagnetometerBiasNoise(obj,val)
            validateattributes(val, {'numeric'}, ...
                {'finite', 'real', 'positive', '2d', ...
                'nonnan', 'nonempty', 'nonsparse'}, ...
                '', 'MagnetometerBiasNoise' );
           
            % Enforce scalar or 3-element vector inputs.
            n = numel(val);
            coder.internal.assert((n == 1) || (n == 3), ... 
                'shared_positioning:insfilter:OneorThreeElements', 'MagnetometerBiasNoise');

            obj.MagnetometerBiasNoise(:) = val(:).';
       end
       
       function val = get.State(obj)
           val = getState(obj);
       end
       
       function set.State(obj, val)
           setState(obj, val);
       end
       
       function set.StateCovariance(obj, val)
           obj.setStateCovariance(val);
       end
       function val = get.StateCovariance(obj)
           val = getStateCovariance(obj); 
       end
    end
    
    methods (Access = protected)
        function val = getState(obj)
           rf = obj.ReferenceFrameObject;
           val = obj.pState;
           mfIdx = obj.MAG_FIELD_INDEX;
           val(mfIdx+2) = -rf.ZAxisUpSign*val(mfIdx+2);
           magN = val(mfIdx);
           magE = val(mfIdx+1);
           val((mfIdx-1)+rf.NorthIndex) = magN;
           val((mfIdx-1)+rf.EastIndex) = magE;
        end
        function setState(obj, val)
           validateattributes(val, {'numeric'}, ...
               {'finite', 'real', 'vector', ...
               'numel', 28, ...
               'nonnan', 'nonempty', 'nonsparse'}, ...
               '', 'State' );
           rf = obj.ReferenceFrameObject;
           mfIdx = obj.MAG_FIELD_INDEX;
           val(mfIdx+2) = -rf.ZAxisUpSign*val(mfIdx+2);
           magX = val(mfIdx);
           magY = val(mfIdx+1);
           val((mfIdx-1)+rf.NorthIndex) = magX;
           val((mfIdx-1)+rf.EastIndex) = magY;
           obj.pState = val(:);
        end
        function x = getStateCovariance(obj)
            x = obj.pStateCovariance;
        end
        function setStateCovariance(obj,val)
            validateattributes(val, {'numeric'}, ...
                {'finite', 'real', '2d', ...
                'ncols', 28, 'nrows', 28 ...
                'nonnan', 'nonempty', 'nonsparse'}, ...
                '', 'StateCovariance' );
            obj.pStateCovariance = val;
        end
        function s = saveObject(obj)
            s = saveObject@fusion.internal.INSFilterEKF(obj);
            s.QuaternionNoise = obj.QuaternionNoise;
            s.AngularVelocityNoise = obj.AngularVelocityNoise;
            s.PositionNoise = obj.PositionNoise;
            s.VelocityNoise = obj.VelocityNoise;
            s.AccelerationNoise = obj.AccelerationNoise;
            s.GyroscopeBiasNoise = obj.GyroscopeBiasNoise;
            s.AccelerometerBiasNoise = obj.AccelerometerBiasNoise;
            s.GeomagneticVectorNoise = obj.GeomagneticVectorNoise;
            s.MagnetometerBiasNoise = obj.MagnetometerBiasNoise;
            s.StateCovariance = obj.StateCovariance; % R2021b -for backwards compat use public set API
            s.pState = obj.pState;
        end
        
        function loadObject(obj, s)
            loadObject@fusion.internal.INSFilterEKF(obj, s);
            obj.QuaternionNoise = s.QuaternionNoise;
            obj.AngularVelocityNoise = s.AngularVelocityNoise;
            obj.PositionNoise = s.PositionNoise;
            obj.VelocityNoise = s.VelocityNoise;
            obj.AccelerationNoise = s.AccelerationNoise;
            obj.GyroscopeBiasNoise = s.GyroscopeBiasNoise;
            obj.AccelerometerBiasNoise = s.AccelerometerBiasNoise;
            obj.GeomagneticVectorNoise = s.GeomagneticVectorNoise;
            obj.MagnetometerBiasNoise = s.MagnetometerBiasNoise;
            obj.StateCovariance = s.StateCovariance; % R2021b -for backwards compat use public set API
            obj.pState = s.pState;
        end
        
        function orient = getOrientation(obj)
            s = getState(obj);
            orient = quaternion(s(1:4).');
        end
        
        function pos = getPosition(obj)
            s = getState(obj);
            pos = s(8:10).';
        end

        function vel = getVelocity(obj)
            s = getState(obj);
            vel = s(11:13).';
        end
        
        function privReset(obj)
            % Reset private and public states
            setState(obj, defaultState(obj.ReferenceFrame));
            obj.setStateCovariance(defaultCov());
        end
        
        function Qs = additiveProcessNoiseFcn(obj)
            % Additive process noise used to compute StateCovariance in
            % predict. 

            Qs = diag([...
                obj.QuaternionNoise, ...
                obj.AngularVelocityNoise, ...
                obj.PositionNoise, ...
                obj.VelocityNoise, ...
                obj.AccelerationNoise, ...
                obj.AccelerometerBiasNoise, ...
                obj.GyroscopeBiasNoise, ...
                obj.GeomagneticVectorNoise, ...
                obj.MagnetometerBiasNoise]);
        end

        function [innov, innovCov] = basicCorrect(obj, z, measFcn, measNoise, measJacobianFcn)
            % Basic EKF correct 

            xk = getState(obj);
            h = measFcn(obj, xk);
            dhdx = measJacobianFcn(obj, xk);
            P = getStateCovariance(obj);
            [xest, P, innov, innovCov] = correctEqn(obj, xk, P, h, dhdx, z, measNoise);

            setStateCovariance(obj, P);
            setState(obj, xest);
        end


        function x  = stateTransFcn(~, x)
            q0   = x(1);  
            q1   = x(2);  
            q2   = x(3);  
            q3   = x(4);  
            wx   = x(5);  
            wy   = x(6);  
            wz   = x(7);  
            pn   = x(8); %#ok<NASGU> 
            pe   = x(9); %#ok<NASGU>
            pd  = x(10); %#ok<NASGU>
            vn  = x(11); 
            ve  = x(12); 
            vd  = x(13);
            an  = x(14); 
            ae  = x(15); 
            ad  = x(16); 
            accx_b  = x(17); %#ok<NASGU>
            accy_b  = x(18); %#ok<NASGU>
            accz_b  = x(19); %#ok<NASGU>
            gyrox_b  = x(20); %#ok<NASGU> 
            gyroy_b  = x(21); %#ok<NASGU>
            gyroz_b  = x(22); %#ok<NASGU>
            magNavX  = x(23); %#ok<NASGU>
            magNavY  = x(24); %#ok<NASGU> 
            magNavZ  = x(25); %#ok<NASGU> 
            magX  = x(26); %#ok<NASGU>
            magY  = x(27); %#ok<NASGU>
            magZ  = x(28); %#ok<NASGU>

            x = [...
                - (q1*wx)/2 - (q2*wy)/2 - (q3*wz)/2
                (q0*wx)/2 - (q3*wy)/2 + (q2*wz)/2
                (q3*wx)/2 + (q0*wy)/2 - (q1*wz)/2
                (q1*wy)/2 - (q2*wx)/2 + (q0*wz)/2
                0
                0
                0
                vn
                ve
                vd
                an
                ae
                ad
                0
                0
                0
                0
                0
                0
                0
                0
                0
                0
                0
                0
                0
                0
                0];
            
            % The derivative quaternion is not necessarily unit length, so
            % no need to repair.
            
        end

        function dfdx = stateTransJacobianFcn(~, x)
            q0   = x(1);  
            q1   = x(2);  
            q2   = x(3);  
            q3   = x(4);  
            wx   = x(5);  
            wy   = x(6);  
            wz   = x(7);  
            pn   = x(8); %#ok<NASGU>
            pe   = x(9); %#ok<NASGU>  
            pd  = x(10); %#ok<NASGU> 
            vn  = x(11); %#ok<NASGU> 
            ve  = x(12); %#ok<NASGU>
            vd  = x(13); %#ok<NASGU>
            an  = x(14); %#ok<NASGU>
            ae  = x(15); %#ok<NASGU>
            ad  = x(16); %#ok<NASGU>
            accx_b  = x(17); %#ok<NASGU>
            accy_b  = x(18); %#ok<NASGU>
            accz_b  = x(19); %#ok<NASGU>
            gyrox_b  = x(20); %#ok<NASGU>
            gyroy_b  = x(21); %#ok<NASGU>
            gyroz_b  = x(22); %#ok<NASGU>
            magNavX  = x(23); %#ok<NASGU>
            magNavY  = x(24); %#ok<NASGU>
            magNavZ  = x(25); %#ok<NASGU>
            magX  = x(26); %#ok<NASGU>
            magY  = x(27); %#ok<NASGU>
            magZ  = x(28); %#ok<NASGU>

            dfdx = [...
                    0, -wx/2, -wy/2, -wz/2, -q1/2, -q2/2, -q3/2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0;
                 wx/2,     0,  wz/2, -wy/2,  q0/2, -q3/2,  q2/2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0;
                 wy/2, -wz/2,     0,  wx/2,  q3/2,  q0/2, -q1/2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0;
                 wz/2,  wy/2, -wx/2,     0, -q2/2,  q1/2,  q0/2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0;
                    0,     0,     0,     0,     0,     0,     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0;
                    0,     0,     0,     0,     0,     0,     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0;
                    0,     0,     0,     0,     0,     0,     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0;
                    0,     0,     0,     0,     0,     0,     0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0;
                    0,     0,     0,     0,     0,     0,     0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0;
                    0,     0,     0,     0,     0,     0,     0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0;
                    0,     0,     0,     0,     0,     0,     0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0;
                    0,     0,     0,     0,     0,     0,     0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0;
                    0,     0,     0,     0,     0,     0,     0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0;
                    0,     0,     0,     0,     0,     0,     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0;
                    0,     0,     0,     0,     0,     0,     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0;
                    0,     0,     0,     0,     0,     0,     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0;
                    0,     0,     0,     0,     0,     0,     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0;
                    0,     0,     0,     0,     0,     0,     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0;
                    0,     0,     0,     0,     0,     0,     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0;
                    0,     0,     0,     0,     0,     0,     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0;
                    0,     0,     0,     0,     0,     0,     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0;
                    0,     0,     0,     0,     0,     0,     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0;
                    0,     0,     0,     0,     0,     0,     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0;
                    0,     0,     0,     0,     0,     0,     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0;
                    0,     0,     0,     0,     0,     0,     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0;
                    0,     0,     0,     0,     0,     0,     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0;
                    0,     0,     0,     0,     0,     0,     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0;
                    0,     0,     0,     0,     0,     0,     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        end

        %% Magnetometer Correct Helper Functions
        function z = magMeasFcn(obj, x)%#ok<INUSL>
        %MAGMEASFCN Measurement function Hmag(x) for state vector x
        %   3 measurements from magnetometer
        %   [magx, magy, magz];
            
            q0 = x(1);
            q1 = x(2);
            q2 = x(3);
            q3 = x(4);
            magNavX = x(23);
            magNavY = x(24);
            magNavZ = x(25);
            magBiasX = x(26);
            magBiasY = x(27);
            magBiasZ = x(28);
            
            mx = magBiasX + magNavX*(q0^2 + q1^2 - q2^2 - q3^2) - magNavZ*(2*q0*q2 - 2*q1*q3) + magNavY*(2*q0*q3 + 2*q1*q2);
            my = magBiasY + magNavY*(q0^2 - q1^2 + q2^2 - q3^2) + magNavZ*(2*q0*q1 + 2*q2*q3) - magNavX*(2*q0*q3 - 2*q1*q2);
            mz = magBiasZ + magNavZ*(q0^2 - q1^2 - q2^2 + q3^2) - magNavY*(2*q0*q1 - 2*q2*q3) + magNavX*(2*q0*q2 + 2*q1*q3);
            
            z = [mx my mz]';
            
        end

        function dhdx = magMeasJacobianFcn(obj, x)%#ok<INUSL>
        %MAGMEASJACOBIANFCN Compute the jacobian dHmag/dx of measurement function Hmag(x)
            q0 = x(1);
            q1 = x(2);
            q2 = x(3);
            q3 = x(4);
            magNavX = x(23);
            magNavY = x(24);
            magNavZ = x(25);
            
            dhdx = [ ...
            2*magNavY*q3 - 2*magNavZ*q2 + 2*magNavX*q0, 2*magNavZ*q3 + 2*magNavY*q2 + 2*magNavX*q1, 2*magNavY*q1 - 2*magNavZ*q0 - 2*magNavX*q2, 2*magNavZ*q1 + 2*magNavY*q0 - 2*magNavX*q3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, q0^2 + q1^2 - q2^2 - q3^2,         2*q0*q3 + 2*q1*q2,         2*q1*q3 - 2*q0*q2, 1, 0, 0
            2*magNavZ*q1 + 2*magNavY*q0 - 2*magNavX*q3, 2*magNavZ*q0 - 2*magNavY*q1 + 2*magNavX*q2, 2*magNavZ*q3 + 2*magNavY*q2 + 2*magNavX*q1, 2*magNavZ*q2 - 2*magNavY*q3 - 2*magNavX*q0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,         2*q1*q2 - 2*q0*q3, q0^2 - q1^2 + q2^2 - q3^2,         2*q0*q1 + 2*q2*q3, 0, 1, 0
            2*magNavZ*q0 - 2*magNavY*q1 + 2*magNavX*q2, 2*magNavX*q3 - 2*magNavY*q0 - 2*magNavZ*q1, 2*magNavY*q3 - 2*magNavZ*q2 + 2*magNavX*q0, 2*magNavZ*q3 + 2*magNavY*q2 + 2*magNavX*q1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,         2*q0*q2 + 2*q1*q3,         2*q2*q3 - 2*q0*q1, q0^2 - q1^2 - q2^2 + q3^2, 0, 0, 1];

        end      

        %% GPS Correct Helper Functions
        function z = gpsMeasFcn(obj, x)%#ok<INUSL>
        %GPSMEASFCN Measurement function Hgps(x) for state vector x
        %   6 measurements from GPS
        %   [posNavX, posNavY, posNavZ, velNavX, velNavY, velNavZ]
            
            pnx = x(8);
            pny = x(9);
            pnz = x(10);
            vnx = x(11);
            vny = x(12);
            vnz = x(13);
           
            z = [pnx pny pnz vnx vny vnz]';
            
        end

        function dhdx = gpsMeasJacobianFcn(obj, ~) %#ok<INUSD>
        %GPSMEASJACOBIANFCN Compute the jacobian dHgps/dx of measurement function Hgps(x)
           
            dhdx = [...
                0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
            
            
        end 
        
        function [innov, iCov] = fusegpsPosition(obj, gpsPos, Rpos)
            rf = obj.ReferenceFrameObject;
            z = rf.lla2frame(gpsPos, obj.ReferenceLocation).';

            [innov, iCov] = basicCorrect(obj, z, @measurementGPSPosition, Rpos, ...
                    @measurementJacobianGPSPosition);
        end
        
        function h = measurementGPSPosition(~, x)
            pos = x(8:10);
            
            h = pos;
        end
        
        function H = measurementJacobianGPSPosition(~, ~)
            
            H = [...
                0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                ];
        end

        %% Accelerometer helper functions
        function z = accelMeasFcn(obj, x)
            q0   = x(1);  
            q1   = x(2);  
            q2   = x(3);  
            q3   = x(4);  
            wx   = x(5); %#ok<NASGU>
            wy   = x(6); %#ok<NASGU>
            wz   = x(7); %#ok<NASGU>
            pn   = x(8); %#ok<NASGU>
            pe   = x(9); %#ok<NASGU>
            pd  = x(10); %#ok<NASGU>
            vn  = x(11); %#ok<NASGU>
            ve  = x(12); %#ok<NASGU>
            vd  = x(13); %#ok<NASGU>
            an  = x(14);
            ae  = x(15); 
            ad  = x(16); 
            accx_b  = x(17); 
            accy_b  = x(18); 
            accz_b  = x(19); 
            gyrox_b  = x(20); %#ok<NASGU>
            gyroy_b  = x(21); %#ok<NASGU>
            gyroz_b  = x(22); %#ok<NASGU>
            magNavX  = x(23); %#ok<NASGU>
            magNavY  = x(24); %#ok<NASGU>
            magNavZ  = x(25); %#ok<NASGU>
            magX  = x(26); %#ok<NASGU>
            magY  = x(27); %#ok<NASGU>
            magZ  = x(28); %#ok<NASGU>

            rf = obj.ReferenceFrameObject;
            grav = zeros(1,3, 'like', x);
            grav(rf.GravityIndex) = rf.GravitySign*rf.GravityAxisSign*gravms2();
            gnavx = grav(1);
            gnavy = grav(2);
            gnavz = grav(3);
            
                z = [...    
                    accx_b - (an - gnavx)*(q0^2 + q1^2 - q2^2 - q3^2) + (ad - gnavz)*(2*q0*q2 - 2*q1*q3) - (ae - gnavy)*(2*q0*q3 + 2*q1*q2)
                    accy_b - (ae - gnavy)*(q0^2 - q1^2 + q2^2 - q3^2) - (ad - gnavz)*(2*q0*q1 + 2*q2*q3) + (an - gnavx)*(2*q0*q3 - 2*q1*q2)
                    accz_b - (ad - gnavz)*(q0^2 - q1^2 - q2^2 + q3^2) + (ae - gnavy)*(2*q0*q1 - 2*q2*q3) - (an - gnavx)*(2*q0*q2 + 2*q1*q3)];
 
         end

        function dhdx = accelMeasJacobianFcn(obj, x)
            q0   = x(1);  
            q1   = x(2);  
            q2   = x(3);  
            q3   = x(4);  
            wx   = x(5); %#ok<NASGU> 
            wy   = x(6); %#ok<NASGU>
            wz   = x(7); %#ok<NASGU>
            pn   = x(8); %#ok<NASGU>
            pe   = x(9); %#ok<NASGU>
            pd  = x(10); %#ok<NASGU>
            vn  = x(11); %#ok<NASGU>
            ve  = x(12); %#ok<NASGU>
            vd  = x(13); %#ok<NASGU>
            an  = x(14); 
            ae  = x(15); 
            ad  = x(16); 
            accx_b  = x(17); %#ok<NASGU>
            accy_b  = x(18); %#ok<NASGU>
            accz_b  = x(19); %#ok<NASGU>
            gyrox_b  = x(20); %#ok<NASGU>
            gyroy_b  = x(21); %#ok<NASGU>
            gyroz_b  = x(22); %#ok<NASGU>
            magN  = x(23); %#ok<NASGU>
            magE  = x(24); %#ok<NASGU>
            magD  = x(25); %#ok<NASGU>
            magX  = x(26); %#ok<NASGU>
            magY  = x(27); %#ok<NASGU>
            magZ  = x(28); %#ok<NASGU>
            
            rf = obj.ReferenceFrameObject;
            grav = zeros(1,3, 'like', x);
            grav(rf.GravityIndex) = rf.GravitySign*rf.GravityAxisSign*gravms2();
            gnavx = grav(1);
            gnavy = grav(2);
            gnavz = grav(3);
            
            dhdx = [... 
                 2*q2*(ad - gnavz) - 2*q3*(ae - gnavy) - 2*q0*(an - gnavx), - 2*q3*(ad - gnavz) - 2*q2*(ae - gnavy) - 2*q1*(an - gnavx),   2*q0*(ad - gnavz) - 2*q1*(ae - gnavy) + 2*q2*(an - gnavx),   2*q3*(an - gnavx) - 2*q0*(ae - gnavy) - 2*q1*(ad - gnavz), 0, 0, 0, 0, 0, 0, 0, 0, 0, - q0^2 - q1^2 + q2^2 + q3^2,         - 2*q0*q3 - 2*q1*q2,           2*q0*q2 - 2*q1*q3, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                 2*q3*(an - gnavx) - 2*q0*(ae - gnavy) - 2*q1*(ad - gnavz),   2*q1*(ae - gnavy) - 2*q0*(ad - gnavz) - 2*q2*(an - gnavx), - 2*q3*(ad - gnavz) - 2*q2*(ae - gnavy) - 2*q1*(an - gnavx),   2*q3*(ae - gnavy) - 2*q2*(ad - gnavz) + 2*q0*(an - gnavx), 0, 0, 0, 0, 0, 0, 0, 0, 0,           2*q0*q3 - 2*q1*q2, - q0^2 + q1^2 - q2^2 + q3^2,         - 2*q0*q1 - 2*q2*q3, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                 2*q1*(ae - gnavy) - 2*q0*(ad - gnavz) - 2*q2*(an - gnavx),   2*q1*(ad - gnavz) + 2*q0*(ae - gnavy) - 2*q3*(an - gnavx),   2*q2*(ad - gnavz) - 2*q3*(ae - gnavy) - 2*q0*(an - gnavx), - 2*q3*(ad - gnavz) - 2*q2*(ae - gnavy) - 2*q1*(an - gnavx), 0, 0, 0, 0, 0, 0, 0, 0, 0,         - 2*q0*q2 - 2*q1*q3,           2*q0*q1 - 2*q2*q3, - q0^2 + q1^2 + q2^2 - q3^2, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0];
 
        end

        %% Gyroscope helper functions
        function z = gyroMeasFcn(obj, x) %#ok<INUSL>
            q0   = x(1); %#ok<NASGU>
            q1   = x(2); %#ok<NASGU>
            q2   = x(3); %#ok<NASGU>
            q3   = x(4); %#ok<NASGU>
            wx   = x(5);  
            wy   = x(6);  
            wz   = x(7);  
            pn   = x(8); %#ok<NASGU>
            pe   = x(9); %#ok<NASGU>
            pd  = x(10); %#ok<NASGU>
            vn  = x(11); %#ok<NASGU>
            ve  = x(12); %#ok<NASGU>
            vd  = x(13); %#ok<NASGU>
            an  = x(14); %#ok<NASGU>
            ae  = x(15); %#ok<NASGU>
            ad  = x(16); %#ok<NASGU>
            accx_b  = x(17); %#ok<NASGU>
            accy_b  = x(18); %#ok<NASGU>
            accz_b  = x(19); %#ok<NASGU>
            gyrox_b  = x(20); 
            gyroy_b  = x(21); 
            gyroz_b  = x(22); 
            magNavX  = x(23); %#ok<NASGU>
            magNavY  = x(24); %#ok<NASGU>
            magNavZ  = x(25); %#ok<NASGU>
            magX  = x(26); %#ok<NASGU>
            magY  = x(27); %#ok<NASGU>
            magZ  = x(28); %#ok<NASGU>

                z = [...
                     gyrox_b + wx
                     gyroy_b + wy
                     gyroz_b + wz];
        end

        function dhdx = gyroMeasJacobianFcn(obj, x) %#ok<INUSL>
            q0   = x(1); %#ok<NASGU>
            q1   = x(2); %#ok<NASGU>
            q2   = x(3); %#ok<NASGU>
            q3   = x(4); %#ok<NASGU>
            wx   = x(5); %#ok<NASGU>
            wy   = x(6); %#ok<NASGU>
            wz   = x(7); %#ok<NASGU>
            pn   = x(8); %#ok<NASGU>
            pe   = x(9); %#ok<NASGU>
            pd  = x(10); %#ok<NASGU>
            vn  = x(11); %#ok<NASGU>
            ve  = x(12); %#ok<NASGU>
            vd  = x(13); %#ok<NASGU>
            an  = x(14); %#ok<NASGU>
            ae  = x(15); %#ok<NASGU>
            ad  = x(16); %#ok<NASGU>
            accx_b  = x(17); %#ok<NASGU>
            accy_b  = x(18); %#ok<NASGU>
            accz_b  = x(19); %#ok<NASGU>
            gyrox_b  = x(20); %#ok<NASGU>
            gyroy_b  = x(21); %#ok<NASGU>
            gyroz_b  = x(22); %#ok<NASGU>
            magNavX  = x(23); %#ok<NASGU>
            magNavY  = x(24); %#ok<NASGU>
            magNavZ  = x(25); %#ok<NASGU>
            magX  = x(26); %#ok<NASGU>
            magY  = x(27); %#ok<NASGU>
            magZ  = x(28); %#ok<NASGU>
          
            dhdx = [... 
                 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0
                 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0
                 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0];
        end
    end

    methods 
        function s = stateinfo(obj) %#ok<MANU>
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
                    'AngularVelocity', 5:7, ...
                    'Position', 8:10, ...
                    'Velocity', 11:13, ...
                    'Acceleration', 14:16, ...
                    'AccelerometerBias', 17:19, ...
                    'GyroscopeBias', 20:22, ...
                    'GeomagneticFieldVector', 23:25, ...
                    'MagnetometerBias', 26:28);

            else
                % Purely display.
                stateCellArr = {'States', ...
                    'Orientation (quaternion parts)', ...
                    'Angular Velocity (XYZ)', ...
                    'Position (NAV)', ...
                    'Velocity (NAV)', ...
                    'Acceleration (NAV)', ...
                    'Accelerometer Bias (XYZ)', ...
                    'Gyroscope Bias (XYZ)', ...
                    'Geomagnetic Field Vector (NAV)', ...
                    'Magnetometer Bias (XYZ)'};
                uT = [char(181) 'T'];
                unitCellArr = {'Units', '', 'rad/s', 'm', 'm/s', 'm/s^2', 'm/s^2', 'rad/s', uT, uT};
                indexCellArr = {'Index', '1:4', '5:7', '8:10', '11:13', ...
                    '14:16', '17:19', '20:22', '23:25', '26:28'};
                
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
end

%% Other Helper Functions

function validateMeasurement(meas, argName)
validateattributes(meas, {'double','single'}, ...
    {'real','finite','2d','nrows',1,'ncols',3,'nonempty'}, ...
    '', ...
    argName);
end

function g = gravms2()
    g = fusion.internal.UnitConversions.geeToMetersPerSecondSquared(1);
end


function s = defaultState(refStr)
    rf = rfconfig(refStr);

    magFieldNED = defaultMagFieldNED;
    magField = magFieldNED;
    magField(rf.NorthIndex) = magFieldNED(1);
    magField(rf.EastIndex) = magFieldNED(2);
    magField(3) = -rf.ZAxisUpSign * magFieldNED(3);
    
    s = [1; zeros(21,1); magField(:); 0; 0; 0];
end

function p = defaultCov()
    p = 1e-3*eye(28);
end

function rf = rfconfig(refStr)
%RFCONFIG Return the reference frame configuration object based on the 
%   reference frame string.
rf = fusion.internal.frames.ReferenceFrame.getMathObject( ...
                refStr);
end

function mfNED = defaultMagFieldNED
mfNED = fusion.internal.ConstantValue.MagneticFieldNED;
end

