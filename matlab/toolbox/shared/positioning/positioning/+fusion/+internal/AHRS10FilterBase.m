classdef (Hidden) AHRS10FilterBase < fusion.internal.BasicEKF & ...
    fusion.internal.mixin.IMUSynchronous
%   This class is for internal use only. It may be removed in the future. 
%

%   Copyright 2018-2020 The MathWorks, Inc.


%#codegen

    properties
        % Multiplicative Process Noises
        
        %GyroscopeNoise Multiplicative process noise variance from the gyroscope (rad/s)^2 
        %   Specify the process noise variance of the gyroscope input to
        %   the fusion algorithm. The gyroscope noise is specified in
        %   units of (rad/s)^2. The default value of this property is 1e-9
        %   (rad/s)^2.
        GyroscopeNoise = [1e-9 1e-9 1e-9]
        
        %AccelerometerNoise Multiplicative process noise variance from the accelerometer (m/s^2)^2 
        %   Specify the process noise variance of the accelerometer input
        %   to the fusion algorithm. The accelerometer noise is specified
        %   in units of (m/s^2)^2. The default value of this property is
        %   1e-4 (m/s^2)^2.
        AccelerometerNoise = [1e-4 1e-4 1e-4]
        
        %GyroscopeBiasNoise Multiplicative process noise variance from the gyroscope bias (rad/s)^2 
        %   Specify the process noise variance of the bias in the gyroscope
        %   input to the fusion algorithm. The gyroscope bias noise is
        %   specified in units of (rad/s)^2. The default value of this
        %   property is 1e-10 (rad/s)^2.
        GyroscopeBiasNoise = [1e-10 1e-10 1e-10]
        
        %AccelerometerBiasNoise Multiplicative process noise variance from the accelerometer bias (m/s^2)^2 
        %   Specify the process noise variance of the bias in the
        %   accelerometer input to the fusion algorithm. The accelerometer
        %   bias noise is specified in units of (m/s^2)^2. The default
        %   value of this property is 1e-4 (m/s^2)^2.
        AccelerometerBiasNoise = [1e-4 1e-4 1e-4]

        % Additive Process Noises

        %GeomagneticVectorNoise Additive process noise for geomagnetic vector (uT^2) 
        %   Specify the process noise variance of the geomagnetic vector
        %   state estimate. The geomagnetic vector noise is specified in
        %   units of uT^2. The default value of this property is 1e-6 uT^2
        GeomagneticVectorNoise = [1e-6 1e-6 1e-6]

        %MagnetometerBiasNoise Additive process noise for magnetometer bias (uT^2)
        %   Specify the process noise variance of the magnetometer offset bias
        %   state estimate. The magnetometer offset bias noise is specified in
        %   units of uT^2. The default value of this property is 0.1 uT^2
        MagnetometerBiasNoise = [0.1 0.1 0.1]
    end
        % State and Error Covariance 
    properties (Dependent)
        %State State vector of the internal extended Kalman Filter 
        %   Specify the initial value of the extended Kalman filter state
        %   vector. The state values represent:
        %       State                           Units        Index
        %   Orientation (quaternion parts)                   S(1:4)
        %   Altitude (NAV)                      m            S(5)
        %   Vertical Velocity (NAV)             m/s          S(6)
        %   Delta Angle Bias (XYZ)              rad/s        S(7:9)
        %   Delta Velocity Bias (XYZ)           m/s          S(10:12)
        %   Geomagnetic Field Vector (NAV)      uT           S(13:15)
        %   Magnetometer Bias (XYZ)             uT           S(16:18)
        %
        State;
        %StateCovariance State error covariance for the internal extended Kalman Filter
        %   Specify the initial value of the error covariance matrix. The
        %   error covariance matrix is a 18-by-18 element matrix. The
        %   default value of this property is eye(18)*1e-6
        StateCovariance;  
    end
    
    properties (Hidden)
        OtherAdditiveNoise = 1e-9;
    end
    
    properties (Hidden, Constant)
        NumStates = 18;
    end
    
    properties (Access = private, Constant)
        MAG_FIELD_INDEX = 13;
    end
    
    properties (Access = protected)
        pGyroInteg
        pAccelInteg
        
        pState = defaultState(fusion.internal.frames.ReferenceFrame.getDefault);
        pStateCovariance = defaultCov();
    end

    methods (Hidden)
        function obj = AHRS10FilterBase(varargin)
            obj = obj@fusion.internal.BasicEKF;
            obj = matlabshared.fusionutils.internal.setProperties(obj, nargin, varargin{:});
            
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
            
            obj.pGyroInteg = fusion.internal.TrapezoidalIntegrator(...
                'InitialValue', [0 0 0]);
            rf = obj.ReferenceFrameObject; 
            grav = zeros(1,3);
            grav(rf.GravityIndex) = -rf.GravitySign*rf.GravityAxisSign*gravms2();
            obj.pAccelInteg = fusion.internal.TrapezoidalIntegrator(...
                'InitialValue', grav);
        end    
    end
    
    methods % Public API
        function predict(obj, accFrame, gyroFrame)
        %PREDICT predict forward state estimates
        %   predict(FUSE, ACC, GYRO) fuses accelerometer and gyroscope
        %   data to update the state estimate. The inputs are: 
        %
        %       FUSE    - ahrs10filter object
        %       ACC     - N-by-3 matrix of accelerometer readings in m/s^2 
        %       GYRO    - N-by-3 matrix of gyroscope readings in rad/s
        
            validateattributes(accFrame, {'double', 'single'}, ...
                {'2d', 'ncols', 3, 'nonempty', 'real'}, '', ...
                'acceleration');
            validateattributes(gyroFrame, {'double', 'single'}, ...
                {'2d', 'ncols', 3, 'nonempty', 'real'}, '', ...
                'angularVelocity');
            n = size(accFrame,1);
            coder.internal.assert(size(gyroFrame,1) == n, ...
                'shared_positioning:insfilter:RowMismatch');
          
            rf = obj.ReferenceFrameObject;
            % Invert the accelerometer signal if linear acceleration is
            % negative in the reference frame.
            accFrame = rf.LinAccelSign.*accFrame;
            xk = getState(obj);
            dt = 1./obj.IMUSampleRate;
            P = getStateCovariance(obj);
            
            
            addProcNoise = additiveProcessNoiseFcn(obj);
            multNoise = procNoiseCov(obj);
            for ii=1:n
                accel = accFrame(ii,:);
                gyro = gyroFrame(ii,:);
              
                dang = integrateGyro(obj, gyro);
                dvel = integrateAccel(obj, accel);
                % Extended Kalman Filter predict algorithm
                
                xnext = obj.stateTransFcn(xk, dang, dvel, dt);
                dfdx = obj.stateTransJacobianFcn(xk, dang, dvel, dt);
                dwdx = obj.processNoiseJacobianFcn(xk, multNoise);
                Pnext = dfdx * P * (dfdx.') + dwdx  + addProcNoise;
                    
                xk = xnext;
                P = Pnext;
            end
            setStateCovariance(obj, P);
            setState(obj, xk);
        end
        
        function [res, resCov] = residualaltimeter(obj, altitude, Rpos)
        %RESIDUALALTIMETER Residuals and residual covariance from altimeter 
        %   [RES,RESCOV] = RESIDUALALTIMETER(FUSE, ALTITUDE, RPOS) uses
        %   altimeter data to compute residuals and residual covariance.
        %   The inputs are:
        %       
        %       FUSE      - ahrs10filter object
        %       ALTITUDE  - scalar altitude in meters 
        %       RPOS      - scalar, covariance of the NAV position
        %                   measurement error in m^2
        %                   
        %   The outputs are:
        %
        %       RES       - 1-by-1 residual in meters
        %       RESCOV    - 1-by-1 residual covariance
        %
        %   Example:
        %
        %       % Reject measurements that have a normalized residual above
        %       % a specified threshold.
        %       outlierThreshold = 3;
        %       filt = ahrs10filter;
        %       meas = 10;
        %       R = 0.1;
        %       [res, resCov] = residualaltimeter(filt, meas, R);
        %       normRes = res ./ sqrt( diag(resCov).' );
        %       if (abs(normRes) <= outlierThreshold)
        %           fusealtimeter(filt, meas, R);
        %       else
        %           fprintf('Outlier detected and disregarded.\n');
        %       end
        %
        %   See also fusealtimeter.

            validateattributes(altitude, {'double', 'single'}, ...
                {'2d', 'scalar', 'nonempty', 'real'}, '', ...
                'altitude');
            validateattributes(Rpos, {'double', 'single'}, ...
                {'2d', 'scalar', 'nonempty', 'real'}, '', ...
                'Rpos');
       
            rf = obj.ReferenceFrameObject;
            measNoise = Rpos; 
            % Set altitude to the same sign as the z-axis.
            z = rf.ZAxisUpSign.*altitude; 
            
            x = getState(obj);
            h = altMeasFcn(obj, x);
            H = altMeasJacobianFcn(obj, x);
            [res, resCov] = privInnov(obj, getStateCovariance(obj), ...
                h, H, z, measNoise);
        end
        
        function [res, resCov] = fusealtimeter(obj, altitude, Rpos)
        %FUSEALTIMETER Correct state estimates using altimeter 
        %   [RES, RESCOV} = FUSEALTIMETER(FUSE, ALTITUDE, RPOS) fuses
        %   altimeter data to correct the state estimate. The inputs are:
        %       
        %       FUSE      - ahrs10filter object
        %       ALTITUDE  - scalar altitude in meters 
        %       RPOS      - scalar, covariance of the NAV position
        %                   measurement error in m^2
        %                   
        %   The outputs are:
        %
        %       RES       - 1-by-1 residual in meters
        %       RESCOV    - 1-by-1 residual covariance
        %
        %   See also residualaltimeter.

            validateattributes(altitude, {'double', 'single'}, ...
                {'2d', 'scalar', 'nonempty', 'real'}, '', ...
                'altitude');
            validateattributes(Rpos, {'double', 'single'}, ...
                {'2d', 'scalar', 'nonempty', 'real'}, '', ...
                'Rpos');
       
            rf = obj.ReferenceFrameObject;
            measNoise = Rpos; 
            % Set altitude to the same sign as the z-axis.
            z = rf.ZAxisUpSign.*altitude; 
            
            [res, resCov] = basicCorrect(obj, z, @altMeasFcn, measNoise, ...
                @altMeasJacobianFcn);
        end

        function [res, resCov] = residualmag(obj, mag, Rmag)
        %RESIDUALMAG Residuals and residual covariance from magnetometer
        %   [RES, RESCOV] = residualmag(FUSE, MAG, RMAG) uses magnetometer
        %   data to compute residuals and residual covariance. The inputs
        %   are:
        %       
        %       FUSE      - ahrs10filter object
        %       MAG       - 1-by-3 vector of magnetic field measurements
        %                   in uT. 
        %       RMAG      - scalar, 1-by-3, or 3-by-3 covariance of the
        %                   magnetometer measurement error in uT^2
        %                   
        %   The outputs are:
        %
        %       RES       - 1-by-3 residuals in uT
        %       RESCOV    - 3-by-3 residual covariance
        %
        %   Example:
        %
        %       % Reject measurements that have a normalized residual above
        %       % a specified threshold.
        %       outlierThreshold = 3;
        %       filt = ahrs10filter;
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
           
            [res, resCov] = privInnov(obj, getStateCovariance(obj), ...
                h, H, z, Rmagmat);
        end
        
        function [res, resCov] = fusemag(obj, mag, Rmag)
        %FUSEMAG Correct state estimates using magnetometer
        %   [RES, RESCOV] = fusemag(FUSE, MAG, RMAG) fuses magnetometer
        %   data to correct the state estimate. The inputs are:
        %       
        %       FUSE      - ahrs10filter object
        %       MAG       - 1-by-3 vector of magnetic field measurements
        %                   in uT. 
        %       RMAG      - scalar, 1-by-3, or 3-by-3 covariance of the
        %                   magnetometer measurement error in uT^2
        %                   
        %   The outputs are:
        %
        %       RES       - 1-by-3 residuals in uT
        %       RESCOV    - 3-by-3 residual covariance
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
        %RESET reset the internal states
        %   RESET(FUSE) resets the State, StateCovariance, and internal
        %   integrators to their default values.

            obj.privReset;
        end
        
        function [pos, orient, vel] = pose(obj, format) 
        %POSE Current orientation and position estimate
        %   [POS, ORIENT, VEL] = POSE(FUSE) returns the current estimate of the pose.
        %
        %   [POS, ORIENT, VEL] = POSE(FUSE, FORMAT) returns the current estimate of the
        %   pose with ORIENT in the specified orientation format FORMAT.
        %
        %   The inputs to POSE are defined as follows:
        %
        %       FORMAT    The output orientation format. Specify the format as
        %                 either 'quaternion' for a quaternion or 'rotmat' for a
        %                 rotation matrix. The default is 'quaternion'.
        %
        %   The outputs of POSE are defined as follows:
        %
        %       POS       Vertical position as a scalar in the navigation
        %                 reference frame in meters. 
        %                 
        %       ORIENT    Orientation estimate with respect to the local navigation
        %                 reference frame specified as a scalar quaternion or a
        %                 3-by-3 rotation matrix. The quaternion or rotation matrix
        %                 is a frame rotation from the local navigation reference frame to
        %                 the body reference frame.
        %
        %       VEL       Vertical velocity, as a scalar, in the navigation
        %                 reference frame in m/s 
        %
            
            isQuat = true;
            if (nargin > 1)
                isQuat = fusion.internal.parseOrientFormat(format, 'pose');
            end
            
            q = getOrientation(obj);
            if ~isQuat
                orient = rotmat(q, 'frame');
            else
                orient = q;
            end
            
            pos = getPosition(obj);
            vel = getVelocity(obj);
        end
    end

    methods % Public API - sets and gets
       function set.GyroscopeNoise(obj,val)
            validateattributes(val, {'numeric'}, ...
                {'finite', 'real', 'positive', '2d', ...
                'nonnan', 'nonempty', 'nonsparse'}, ...
                '', 'GyroscopeNoise' );
           
            % Enforce scalar or 3-element vector inputs.
            n = numel(val);
            coder.internal.assert((n == 1) || (n == 3), ... 
                'shared_positioning:insfilter:OneorThreeElements', 'GyroscopeNoise');

            obj.GyroscopeNoise(:) = val(:).';
       end

       function set.AccelerometerNoise(obj,val)
            validateattributes(val, {'numeric'}, ...
                {'finite', 'real', 'positive', '2d', ...
                'nonnan', 'nonempty', 'nonsparse'}, ...
                '', 'AccelerometerNoise' );
           
            % Enforce scalar or 3-element vector inputs.
            n = numel(val);
            coder.internal.assert((n == 1) || (n == 3), ... 
                'shared_positioning:insfilter:OneorThreeElements', 'AccelerometerNoise');

            obj.AccelerometerNoise(:) = val(:).';
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
       function setStateSpecified(obj)
           obj.pIsStateSpecified = true;
       end
       function set.StateCovariance(obj, val)
           setStateCovariance(obj, val);
       end
       function val = get.StateCovariance(obj)
           val = getStateCovariance(obj);
       end
    end
    
    methods (Access = protected)
        function setState(obj, val)
           validateattributes(val, {'numeric'}, ...
               {'finite', 'real', 'vector', ...
               'numel', 18, ...
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
        function setStateCovariance(obj, val)
            validateattributes(val, {'numeric'}, ...
               {'finite', 'real', '2d', ...
               'ncols', 18, 'nrows', 18 ...
               'nonnan', 'nonempty', 'nonsparse'}, ...
               '', 'StateCovariance' );
            obj.pStateCovariance = val;
        end
        function val = getStateCovariance(obj)
            val = obj.pStateCovariance;
        end
        function s = saveObject(obj)
            s = struct();
            s = saveObject@fusion.internal.mixin.IMUSynchronous(obj,s);

            s.GyroscopeNoise = obj.GyroscopeNoise;
            s.AccelerometerNoise = obj.AccelerometerNoise;
            s.GyroscopeBiasNoise = obj.GyroscopeBiasNoise;
            s.AccelerometerBiasNoise = obj.AccelerometerBiasNoise;
            s.GeomagneticVectorNoise = obj.GeomagneticVectorNoise;
            s.MagnetometerBiasNoise = obj.MagnetometerBiasNoise;
            s.StateCovariance = obj.StateCovariance;
            s.OtherAdditiveNoise = obj.OtherAdditiveNoise;
            s.pGyroInteg = clone(obj.pGyroInteg);
            s.pAccelInteg = clone(obj.pAccelInteg);
            s.pState = obj.pState;
        end
        
        function loadObject(obj, s)
            loadObject@fusion.internal.mixin.IMUSynchronous(obj,s);

            obj.GyroscopeNoise = s.GyroscopeNoise;
            obj.AccelerometerNoise = s.AccelerometerNoise;
            obj.GyroscopeBiasNoise = s.GyroscopeBiasNoise;
            obj.AccelerometerBiasNoise = s.AccelerometerBiasNoise;
            obj.GeomagneticVectorNoise = s.GeomagneticVectorNoise;
            obj.MagnetometerBiasNoise = s.MagnetometerBiasNoise;
            obj.StateCovariance = s.StateCovariance;
            obj.OtherAdditiveNoise = s.OtherAdditiveNoise;
            obj.pGyroInteg = s.pGyroInteg;
            obj.pAccelInteg = s.pAccelInteg;
            obj.pState = s.pState;
        end
        
        function orient = getOrientation(obj)
            st = getState(obj);
            orient = quaternion(st(1:4).');
        end
        
        function pos = getPosition(obj)
            st = getState(obj);
            pos = st(5);
        end

        function vel = getVelocity(obj)
            st = getState(obj);
            vel = st(6);
        end
        
        function dang = integrateGyro(obj, gyro)
        % Gyroscope integration to delta angles
            dang = obj.pGyroInteg(gyro, obj.IMUSampleRate);
        end
        
        function dvel = integrateAccel(obj, acc)
        % Accelerometer integration to delta velocity
            dvel = obj.pAccelInteg(acc, obj.IMUSampleRate);      
        end
    
        function privReset(obj)
            % Reset private and public states
            obj.setState( defaultState(obj.ReferenceFrame) );
            obj.setStateCovariance( defaultCov() );
            reset(obj.pGyroInteg);
            reset(obj.pAccelInteg);
        end
        
        function w = procNoiseCov(obj)
            % Process Noises
            w = 0.5*(1./obj.IMUSampleRate.^2).* ...
                [obj.GyroscopeNoise, obj.AccelerometerNoise];
        end
        
        function Qs = additiveProcessNoiseFcn(obj)
            % Additive process noise used to compute StateErrorCovariance in
            % predict. 

            scale = 0.5*(1./obj.IMUSampleRate.^2); 
            dAngBiasSigma = scale .* obj.GyroscopeBiasNoise; 
            dVelBiasSigma = scale .* obj.AccelerometerBiasNoise; 
            
            magEarthSigma = obj.GeomagneticVectorNoise;
            magBodySigma  = obj.MagnetometerBiasNoise;
            
            Qs = diag([obj.OtherAdditiveNoise.*ones(1,6), dAngBiasSigma, dVelBiasSigma,  magEarthSigma, magBodySigma]);
        end

        function [innov, icov] = basicCorrect(obj, z, measFcn, measNoise, measJacobianFcn)
            % Basic EKF correct 

            xk = getState(obj);
            h = measFcn(obj, xk);
            dhdx = measJacobianFcn(obj, xk);
            P = getStateCovariance(obj);
            [xest, P, innov, icov] = correctEqn(obj, xk, P, h, dhdx, z, measNoise);

            setStateCovariance(obj, P);
            setState(obj, xest);
        end

        function x = stateTransFcn(obj, x, dang, dvel, dt)
        %STATETRANSFCN new filter states based on current and IMU data
        %   Predict forward the state estimate one time sample, based on control
        %   inputs : 
        %       new delta angles (integrated gyroscope readings), and 
        %       new delta velocities (integrated accelerometer readings).

            q0 = x(1);
            q1 = x(2);
            q2 = x(3);
            q3 = x(4);    
            pnavz = x(5);
            vnavz = x(6);
            dax_b = x(7);
            day_b = x(8);
            daz_b = x(9);
            dvx_b = x(10);
            dvy_b = x(11);
            dvz_b = x(12);
            magNavX = x(13);
            magNavY = x(14);
            magNavZ = x(15);
            magX = x(16);
            magY = x(17);
            magZ = x(18);
            
            rf = obj.ReferenceFrameObject;
            grav = zeros(1,3, 'like', dvel);
            grav(rf.GravityIndex) = rf.GravitySign*rf.GravityAxisSign*gravms2();
            gnavx = grav(1); %#ok<NASGU>
            gnavy = grav(2); %#ok<NASGU>
            gnavz = grav(3);

            dvx = dvel(1);
            dvy = dvel(2);
            dvz = dvel(3);
            
            % State update equation
            % Orientation is updated below. This line updates, velocity, position,
            % sensor biases and the geomagnetic vector.
            %
            % x(1:4) - pre-allocated placeholders of the current quaternion parts.
            %
            % x(5) - position update equation. The new position is 
            %    the current position + the effect of current velocity
            %
            % x(6) - velocity update equation. The new velocity is 
            %    the current velocity + the gravity vector's effect +
            %        (current delta velocity - delta velocity sensor bias), rotated
            %        to the global frame 
            %
            % x(7:18) - the new delta angle bias, delta velocity bias, geomagnetic field vector,
            %    and magnetometer bias are the same as the current estimate.
            %
            % In all of the above, a "plus white noise" is assumed by the Extended
            % Kalman Filter formulation. So, for example, the new delta angle bias
            % is the previous delta angle bias plus white noise.
            %
           
            %WISH change the velocity equations to use rotateframe(q, dvel - dvelbias)
            x = [
                q0 % preallocate
                q1 % preallocate
                q2 % preallocate
                q3 % preallocate
                pnavz + dt*vnavz
                vnavz + dt*gnavz + (dvz - dvz_b)*(q0^2 - q1^2 - q2^2 + q3^2) - (dvx - dvx_b)*(2*q0*q2 - 2*q1*q3) + (dvy - dvy_b)*(2*q0*q1 + 2*q2*q3)
                dax_b
                day_b
                daz_b
                dvx_b
                dvy_b
                dvz_b
                magNavX
                magNavY
                magNavZ
                magX
                magY
                magZ];
            
            % Compute x(1:4) using quaternion math.
            %   Subtract the delta angle bias from the delta angle. Treat the
            %   corrected delta angle as a rotation vector. Convert the rotation
            %   vector to a quaternion and compute an updated orientation, forcing
            %   the result to be a unit quaternion with a positive angle of
            %   rotation.
            qinit = quaternion(q0,q1,q2,q3);
            x(1:4) = compact(normalize(posangle(qinit * quaternion(dang - [dax_b, day_b, daz_b], 'rotvec')))); 
            
        end

        function dfdx = stateTransJacobianFcn(obj, x, dang, dvel, dt) %#ok<INUSL>
        % STATETRANSJACOBIANFCN Jacobian of process equations
        %   Compute the Jacobian matrix dfdx of the state transition function f(x)
        %   with respect to state x.

            q0 = x(1);
            q1 = x(2);
            q2 = x(3);
            q3 = x(4);
            dax_b = x(7);
            day_b = x(8);
            daz_b = x(9);
            dvx_b = x(10);
            dvy_b = x(11);
            dvz_b = x(12);
            
            
            dax = dang(1);
            day = dang(2);
            daz = dang(3);
            
            dvx = dvel(1);
            dvy = dvel(2);
            dvz = dvel(3);
            
            % The matrix here is the Jacobian of the equations in stateTransFcn(). 
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
            %   cos(ang)^2 == 1
            % Using the Maclaurin expansion and truncating after the first term:
            %   sin(ang)^2 * ax(n) == 1/2 * ax(n)
            % So the rotation vector to quaternion approximation used in the
            % Jacobian calculation below is:
            %   q_increment = quaternion(0, ax(1)/2, ax(2)/2, ax(3)/2)
            
            
            dfdx = [...
                                                                            1,                                              dax_b/2 - dax/2,                                              day_b/2 - day/2,                                              daz_b/2 - daz/2, 0,  0,  q1/2,  q2/2,  q3/2,                 0,                   0,                           0, 0, 0, 0, 0, 0, 0
                                                              dax/2 - dax_b/2,                                                            1,                                              daz/2 - daz_b/2,                                              day_b/2 - day/2, 0,  0, -q0/2,  q3/2, -q2/2,                 0,                   0,                           0, 0, 0, 0, 0, 0, 0
                                                              day/2 - day_b/2,                                              daz_b/2 - daz/2,                                                            1,                                              dax/2 - dax_b/2, 0,  0, -q3/2, -q0/2,  q1/2,                 0,                   0,                           0, 0, 0, 0, 0, 0, 0
                                                              daz/2 - daz_b/2,                                              day/2 - day_b/2,                                              dax_b/2 - dax/2,                                                            1, 0,  0,  q2/2, -q1/2, -q0/2,                 0,                   0,                           0, 0, 0, 0, 0, 0, 0
                                                                            0,                                                            0,                                                            0,                                                            0, 1, dt,     0,     0,     0,                 0,                   0,                           0, 0, 0, 0, 0, 0, 0
                 2*q1*(dvy - dvy_b) - 2*q2*(dvx - dvx_b) + 2*q0*(dvz - dvz_b), 2*q3*(dvx - dvx_b) + 2*q0*(dvy - dvy_b) - 2*q1*(dvz - dvz_b), 2*q3*(dvy - dvy_b) - 2*q0*(dvx - dvx_b) - 2*q2*(dvz - dvz_b), 2*q1*(dvx - dvx_b) + 2*q2*(dvy - dvy_b) + 2*q3*(dvz - dvz_b), 0,  1,     0,     0,     0, 2*q0*q2 - 2*q1*q3, - 2*q0*q1 - 2*q2*q3, - q0^2 + q1^2 + q2^2 - q3^2, 0, 0, 0, 0, 0, 0
                                                                            0,                                                            0,                                                            0,                                                            0, 0,  0,     1,     0,     0,                 0,                   0,                           0, 0, 0, 0, 0, 0, 0
                                                                            0,                                                            0,                                                            0,                                                            0, 0,  0,     0,     1,     0,                 0,                   0,                           0, 0, 0, 0, 0, 0, 0
                                                                            0,                                                            0,                                                            0,                                                            0, 0,  0,     0,     0,     1,                 0,                   0,                           0, 0, 0, 0, 0, 0, 0
                                                                            0,                                                            0,                                                            0,                                                            0, 0,  0,     0,     0,     0,                 1,                   0,                           0, 0, 0, 0, 0, 0, 0
                                                                            0,                                                            0,                                                            0,                                                            0, 0,  0,     0,     0,     0,                 0,                   1,                           0, 0, 0, 0, 0, 0, 0
                                                                            0,                                                            0,                                                            0,                                                            0, 0,  0,     0,     0,     0,                 0,                   0,                           1, 0, 0, 0, 0, 0, 0
                                                                            0,                                                            0,                                                            0,                                                            0, 0,  0,     0,     0,     0,                 0,                   0,                           0, 1, 0, 0, 0, 0, 0
                                                                            0,                                                            0,                                                            0,                                                            0, 0,  0,     0,     0,     0,                 0,                   0,                           0, 0, 1, 0, 0, 0, 0
                                                                            0,                                                            0,                                                            0,                                                            0, 0,  0,     0,     0,     0,                 0,                   0,                           0, 0, 0, 1, 0, 0, 0
                                                                            0,                                                            0,                                                            0,                                                            0, 0,  0,     0,     0,     0,                 0,                   0,                           0, 0, 0, 0, 1, 0, 0
                                                                            0,                                                            0,                                                            0,                                                            0, 0,  0,     0,     0,     0,                 0,                   0,                           0, 0, 0, 0, 0, 1, 0
                                                                            0,                                                            0,                                                            0,                                                            0, 0,  0,     0,     0,     0,                 0,                   0,                           0, 0, 0, 0, 0, 0, 1];
  
            
        end

        function dwdx = processNoiseJacobianFcn(obj, x,w)%#ok<INUSL>
        %PROCESSNOISEJACOBIANFCN Compute jacobian for multiplicative process noise
        %   The process noise Jacobian dwdx for state vector x and multiplicative
        %   process noise w is L* W * (L.') where 
        %       L = jacobian of update function f with respect to drive inputs 
        %       W = covariance matrix of multiplicative process noise w.
            
            daxCov = w(1);
            dayCov = w(2);
            dazCov = w(3);
            dvxCov = w(4);
            dvyCov = w(5);
            dvzCov = w(6);
            
            
            q0 = x(1);
            q1 = x(2);
            q2 = x(3);
            q3 = x(4);
    
            
            dwdx = [ ...
                   (daxCov*q1^2)/4 + (dayCov*q2^2)/4 + (dazCov*q3^2)/4, (dayCov*q2*q3)/4 - (daxCov*q0*q1)/4 - (dazCov*q2*q3)/4, (dazCov*q1*q3)/4 - (dayCov*q0*q2)/4 - (daxCov*q1*q3)/4, (daxCov*q1*q2)/4 - (dayCov*q1*q2)/4 - (dazCov*q0*q3)/4, 0,                                                                                                  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                (dayCov*q2*q3)/4 - (daxCov*q0*q1)/4 - (dazCov*q2*q3)/4,    (daxCov*q0^2)/4 + (dazCov*q2^2)/4 + (dayCov*q3^2)/4, (daxCov*q0*q3)/4 - (dayCov*q0*q3)/4 - (dazCov*q1*q2)/4, (dazCov*q0*q2)/4 - (dayCov*q1*q3)/4 - (daxCov*q0*q2)/4, 0,                                                                                                  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                (dazCov*q1*q3)/4 - (dayCov*q0*q2)/4 - (daxCov*q1*q3)/4, (daxCov*q0*q3)/4 - (dayCov*q0*q3)/4 - (dazCov*q1*q2)/4,    (dayCov*q0^2)/4 + (dazCov*q1^2)/4 + (daxCov*q3^2)/4, (dayCov*q0*q1)/4 - (daxCov*q2*q3)/4 - (dazCov*q0*q1)/4, 0,                                                                                                  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                (daxCov*q1*q2)/4 - (dayCov*q1*q2)/4 - (dazCov*q0*q3)/4, (dazCov*q0*q2)/4 - (dayCov*q1*q3)/4 - (daxCov*q0*q2)/4, (dayCov*q0*q1)/4 - (daxCov*q2*q3)/4 - (dazCov*q0*q1)/4,    (dazCov*q0^2)/4 + (dayCov*q1^2)/4 + (daxCov*q2^2)/4, 0,                                                                                                  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                                                                     0,                                                      0,                                                      0,                                                      0, 0,                                                                                                  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                                                                     0,                                                      0,                                                      0,                                                      0, 0, dvxCov*(2*q0*q2 - 2*q1*q3)^2 + dvyCov*(2*q0*q1 + 2*q2*q3)^2 + dvzCov*(q0^2 - q1^2 - q2^2 + q3^2)^2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                                                                     0,                                                      0,                                                      0,                                                      0, 0,                                                                                                  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                                                                     0,                                                      0,                                                      0,                                                      0, 0,                                                                                                  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                                                                     0,                                                      0,                                                      0,                                                      0, 0,                                                                                                  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                                                                     0,                                                      0,                                                      0,                                                      0, 0,                                                                                                  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                                                                     0,                                                      0,                                                      0,                                                      0, 0,                                                                                                  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                                                                     0,                                                      0,                                                      0,                                                      0, 0,                                                                                                  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                                                                     0,                                                      0,                                                      0,                                                      0, 0,                                                                                                  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                                                                     0,                                                      0,                                                      0,                                                      0, 0,                                                                                                  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                                                                     0,                                                      0,                                                      0,                                                      0, 0,                                                                                                  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                                                                     0,                                                      0,                                                      0,                                                      0, 0,                                                                                                  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                                                                     0,                                                      0,                                                      0,                                                      0, 0,                                                                                                  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                                                                     0,                                                      0,                                                      0,                                                      0, 0,                                                                                                  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
 
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
            magNavX = x(13);
            magNavY = x(14);
            magNavZ = x(15);
            magBiasX = x(16);
            magBiasY = x(17);
            magBiasZ = x(18);
            
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
            magNavX = x(13);
            magNavY = x(14);
            magNavZ = x(15);
            
            dhdx = [ ...
                2*magNavY*q3 - 2*magNavZ*q2 + 2*magNavX*q0, 2*magNavZ*q3 + 2*magNavY*q2 + 2*magNavX*q1, 2*magNavY*q1 - 2*magNavZ*q0 - 2*magNavX*q2, 2*magNavZ*q1 + 2*magNavY*q0 - 2*magNavX*q3, 0, 0, 0, 0, 0, 0, 0, 0, q0^2 + q1^2 - q2^2 - q3^2,         2*q0*q3 + 2*q1*q2,         2*q1*q3 - 2*q0*q2, 1, 0, 0
                2*magNavZ*q1 + 2*magNavY*q0 - 2*magNavX*q3, 2*magNavZ*q0 - 2*magNavY*q1 + 2*magNavX*q2, 2*magNavZ*q3 + 2*magNavY*q2 + 2*magNavX*q1, 2*magNavZ*q2 - 2*magNavY*q3 - 2*magNavX*q0, 0, 0, 0, 0, 0, 0, 0, 0,         2*q1*q2 - 2*q0*q3, q0^2 - q1^2 + q2^2 - q3^2,         2*q0*q1 + 2*q2*q3, 0, 1, 0
                2*magNavZ*q0 - 2*magNavY*q1 + 2*magNavX*q2, 2*magNavX*q3 - 2*magNavY*q0 - 2*magNavZ*q1, 2*magNavY*q3 - 2*magNavZ*q2 + 2*magNavX*q0, 2*magNavZ*q3 + 2*magNavY*q2 + 2*magNavX*q1, 0, 0, 0, 0, 0, 0, 0, 0,         2*q0*q2 + 2*q1*q3,         2*q2*q3 - 2*q0*q1, q0^2 - q1^2 - q2^2 + q3^2, 0, 0, 1];
                
            
        end      

        %% Altimeter Correct Helper Functions
        function z = altMeasFcn(obj, x)%#ok<INUSL>
        %ALTMEASFCN Measurement function Halt(x) for state vector x
        %   1 measurements from altimeter
        %   posd 
            
            pd = x(5);
           
            z = pd; 
            
        end

        function dhdx = altMeasJacobianFcn(obj, ~) %#ok<INUSD>
        %ALTMEASJACOBIANFCN Compute the jacobian dHalt/dx of measurement function Halt(x)
           
            dhdx = ...
                [ 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
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
                    'Altitude', 5, ...
                    'VerticalVelocity', 6, ...
                    'DeltaAngleBias', 7:9, ...
                    'DeltaVelocityBias', 10:12, ...
                    'GeomagneticFieldVector', 13:15, ...
                    'MagnetometerBias', 16:18);

            else
                % Purely display.
                stateCellArr = {'States', 'Orientation (quaternion parts)', ...
                    'Altitude (NAV)', 'Vertical Velocity (NAV)', ...
                    'Delta Angle Bias (XYZ)' 'Delta Velocity Bias (XYZ)', ...
                    'Geomagnetic Field Vector (NAV)', 'Magnetometer Bias (XYZ)'};
                uT = [char(181) 'T'];
                unitCellArr = {'Units', '', 'm', 'm/s', 'rad', 'm/s', uT, uT};
                indexCellArr = {'Index', '1:4', '5', '6', '7:9', ...
                    '10:12', '13:15', '16:18'};
                
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
function g = gravms2()
    g = fusion.internal.UnitConversions.geeToMetersPerSecondSquared(1);
end

function p = posangle(p)
%POSANGLE Force quaternion to have a positive angle

idx = parts(p) < 0;
if any(idx(:))
    p(idx) = -p(idx);
end
end

function s = defaultState(refStr)
    rf = rfconfig(refStr);
    
    magFieldNED = defaultMagFieldNED;
    magField = magFieldNED;
    magField(rf.NorthIndex) = magFieldNED(1);
    magField(rf.EastIndex) = magFieldNED(2);
    magField(3) = -rf.ZAxisUpSign * magFieldNED(3);
    
    s = [1; zeros(11,1); magField(:); 0; 0; 0];
end

function p = defaultCov()
    p = 1e-6*eye(18);
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
