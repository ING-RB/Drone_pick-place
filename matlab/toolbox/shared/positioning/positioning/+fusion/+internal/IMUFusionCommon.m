classdef (Hidden) IMUFusionCommon < fusion.internal.PositioningSystemBase
%IMUFUSIONCOMMON common base class for IMUFilterBase & AHRSFilterBase
%
%   This class is for internal use only. It may be removed in the future.
%

%   Copyright 2017-2024 The MathWorks, Inc.

%#codegen

    properties (Abstract)
        DecimationFactor
        SampleRate
    end
    properties 
        %AccelerometerNoise Noise in the accelerometer signal
        %   Specify the noise in the accelerometer data in units of
        %   (m/s^2)^2.  Accelerometer noise variance must be a positive
        %   scalar value. This property is tunable. 
        AccelerometerNoise = 2e-6 * (gms2()^2);  

        %GyroscopeNoise Noise in the gyroscope signal
        %   Specify the noise in the gyroscope data in units of (rad/s)^2.
        %   Gyroscope noise variance must be a positive scalar value. The
        %   initial value 9.1385e-5 (rad/s)^2. This property is tunable.  
        GyroscopeNoise = 9.1385e-5

        %GyroscopeDriftNoise Variance for gyroscope offset drift 
        %   Specify the noise in the offset drift of the gyroscope in units
        %   of (rad/s)^2.  Gyroscope drift noise variance must be a scalar
        %   value. The initial value is 3.0462e-13 (rad/s)^2. This property
        %   is tunable.
        GyroscopeDriftNoise = 3.0462e-13

        %LinearAccelerationNoise Variance for linear acceleration noise 
        %   Linear acceleration is modeled as a lowpass filtered white
        %   noise process.  Specify the noise in the linear acceleration
        %   model in units of (m/s^2)^2.  Linear acceleration noise
        %   variance must be a positive scalar value. This property
        %   is tunable.
        LinearAccelerationNoise = 1e-4 * (gms2()^2); 

        %LinearAccelerationDecayFactor Decay factor for linear acceleration drift 
        %   Linear acceleration drift is modeled as a lowpass filtered
        %   white noise process.  Specify the decay factor in the linear
        %   acceleration model.  Linear acceleration decay factor must be a
        %   positive scalar value between 0 and 1. If linear acceleration
        %   is changing quickly, set this to a lower value. If linear
        %   acceleration changes slowly, set this to a higher value.  This
        %   property is tunable.
        LinearAccelerationDecayFactor = 0.5;
        
    end
    properties (Nontunable)

        %OrientationFormat Output orientation format
        %   Output the computed orientation as an N-by-1 quaternion or a
        %   3-by-3-by-N rotation matrix. Specify the property
        %   OrientationFormat as one of 'quaternion' or 'Rotation
        %   matrix'. The default is a quaternion. 
        OrientationFormat = 'quaternion'
    end

    properties (Constant, Hidden) % Noise Variance for Covariance Matrix

        cOrientErrVar    = deg2rad(1)*deg2rad(1)*2000e-5; % var in init orientation error estim.
        cGyroBiasErrVar  = deg2rad(1)*deg2rad(1)*250e-3; % var in init gyro bias error estim
        cOrientGyroBiasErrVar = deg2rad(1)*deg2rad(1)*0; % covar orient -gyro bias error estim
        cAccErrVar       = 10e-5 * (gms2()^2);  % var in linear accel drift error estim
    end

    properties(Constant, Hidden)
        OrientationFormatSet = matlab.system.internal.MessageCatalogSet({...
            'shared_positioning:internal:IMUFusionCommon:OrientationQuat',...
            'shared_positioning:internal:IMUFusionCommon:OrientationRotmat'});
        ReferenceFrameSet = matlab.system.StringSet( ...
            fusion.internal.frames.ReferenceFrame.getOptions);
    end
    
    properties (Nontunable, Hidden)
        ReferenceFrame = fusion.internal.frames.ReferenceFrame.getDefault;
    end

    properties (Access = protected)
        pQw                      % Covariance matrix, process noise
        pQv                      % Covariance matrix, measurement noise
        pOrientPost              % Orientation quaternion a posteriori
        pOrientPrior             % Orientation quaternion a priori
        pFirstTime  = true       % First time through the step method
        pRefSys                  % Coordinate Reference System.  
        pSensorPeriod            % sensor period
        pKalmanPeriod            % Downsampled kalman filter period
        pGyroOffset              % Estimate of gyro offset bias
        pLinAccelPrior           % A priori linear accel error estim.
        pLinAccelPost            % A posteriori linear accel error estim
        pInputPrototype          % exemplar from 1 sensor (for cast 'like')
    end

    methods
        function set.AccelerometerNoise(obj,val)
            validateattributes(val, {'numeric'}, ...
                {'real', 'nonempty', 'scalar', 'finite', 'positive', ...
                'nonsparse'}, ...
                'set.AccelerometerNoise', 'AccelerometerNoise' );
            obj.AccelerometerNoise = val;
        end

        function set.GyroscopeNoise(obj,val)
            validateattributes(val, {'numeric'}, ...
                {'real', 'nonempty', 'scalar', 'finite', 'positive', ...
                'nonsparse'}, ...
                'set.GyroscopeNoise', 'GyroscopeNoise' );
            obj.GyroscopeNoise = val;
        end

        function set.GyroscopeDriftNoise(obj,val)
            validateattributes(val, {'numeric'}, ...
                {'real', 'nonempty', 'scalar', 'finite', 'positive', ...
                'nonsparse'}, ...
                'set.GyroscopeDriftNoise', 'GyroscopeDriftNoise' );
            obj.GyroscopeDriftNoise = val;
        end

        function set.LinearAccelerationNoise(obj,val)
            validateattributes(val, {'numeric'}, ...
                {'real', 'nonempty', 'scalar', 'finite', 'positive', ...
                'nonsparse'}, ...
                'set.LinearAccelerationNoise', 'LinearAccelerationNoise' );
            obj.LinearAccelerationNoise = val;
        end

        function set.LinearAccelerationDecayFactor(obj,val)
            validateattributes(val, {'numeric'}, ...
                {'real', 'nonempty', 'scalar', 'finite', ...
                '<' 1, '>=', 0, ...
                'nonsparse'}, ...
                'set.LinearAccelerationDecayFactor', 'LinearAccelerationDecayFactor' );
            obj.LinearAccelerationDecayFactor = val;
        end


    end

    methods (Access = protected)
        function s = saveObjectImpl(obj)
            % Default implementation saves all public properties
            s = saveObjectImpl@matlab.System(obj);

            if isLocked(obj)
                s.pQw = obj.pQw;
                s.pQv = obj.pQv;
                s.pOrientPost = obj.pOrientPost;
                s.pOrientPrior = obj.pOrientPrior;
                s.pFirstTime = obj.pFirstTime;
                s.pRefSys = obj.pRefSys;
                s.pSensorPeriod = obj.pSensorPeriod;
                s.pKalmanPeriod = obj.pKalmanPeriod;
                s.pGyroOffset = obj.pGyroOffset;
                s.pLinAccelPrior = obj.pLinAccelPrior;
                s.pLinAccelPost = obj.pLinAccelPost;
                s.pInputPrototype = obj.pInputPrototype;
            end
        end        

        function s = loadObjectImpl(obj, s, wasLocked)
            % Reload states if saved version was locked 
            if wasLocked 
                obj.pQw = s.pQw;
                obj.pQv = s.pQv;
                obj.pOrientPost = s.pOrientPost;
                obj.pOrientPrior = s.pOrientPrior;
                obj.pFirstTime = s.pFirstTime;
                obj.pRefSys = s.pRefSys;
                obj.pSensorPeriod = s.pSensorPeriod;
                obj.pKalmanPeriod = s.pKalmanPeriod;
                obj.pGyroOffset = s.pGyroOffset;
                obj.pLinAccelPrior = s.pLinAccelPrior;
                obj.pLinAccelPost = s.pLinAccelPost;
                obj.pInputPrototype = s.pInputPrototype;
            end
            loadObjectImpl@matlab.System(obj, s, wasLocked);

        end        
        
        function processTunedPropertiesImpl(obj)
            setupPeriods(obj);
        end

        function setupImpl(obj, accelIn, varargin)
            if ~isempty(accelIn)
                obj.pInputPrototype = accelIn(1,:);
            else
                obj.pInputPrototype = accelIn;
            end
            setupPeriods(obj);
            ref = fusion.internal.frames.ReferenceFrame.getMathObject( ...
                obj.ReferenceFrame);
            obj.pRefSys = ref;
        end

        function setupPeriods(obj)
            obj.pSensorPeriod = cast(1./obj.SampleRate, 'like', obj.pInputPrototype);
            obj.pKalmanPeriod = obj.DecimationFactor * obj.pSensorPeriod;
        end


        function validateFrameSize(obj, x)
            % Ensure that the decimation factor divides the frame size
            nrows = x(1);
            coder.internal.assert(rem(nrows, obj.DecimationFactor) == 0, ...
                'shared_positioning:internal:IMUFusionCommon:FrameDivByDecim', ...
                'DecimationFactor');
        end

        function h = buildHPart(~, v)
        % Build a portion of the H matrix

            h = zeros(3, 'like', v);
            h(1,2) = v(3);
            h(1,3) = -v(2);
            h(2,3) = v(1);
            h = h - h.';
        end

        function g = rotmat2gravity(obj, R)
            % Extract gravity in the sensor's frame from a rotation matrix.
            % Essentially this is a column of the rotation matrix.

            gravity = fusion.internal.UnitConversions.geeToMetersPerSecondSquared(ones(1, 'like', R));
            ref = obj.pRefSys;
            g = cast(ref.GravityAxisSign, 'like', R) * R(:,ref.GravityIndex).' .* gravity;

        end

        function [av, orientOut] = allocateOutputs(obj,numiters, cls)
            av = zeros(numiters, 3, cls);
            if strcmpi(obj.OrientationFormat, 'quaternion') 
                orientOut = quaternion.zeros(numiters, 1, cls);
            else
                orientOut = zeros(3,3,numiters, cls);
            end
        end

        function av = computeAngularVelocity(obj, gfast, offset)
        % Average fast gyroscope readings and subtract bias

            % integrated gyro readings. g is in rad/sec
            
            gslow = sum(gfast,1) ./ obj.DecimationFactor;
            % Output angular velocity is the averaged gyroscope reading
            % minus the current estimate of the gyroscope bias.
            av = gslow - offset;
        end

        function qorient = predictOrientation(obj, gfast, offset, qorient) 
            % Update orientation estimate based on gyroscope 
            deltaAng = bsxfun(@minus, gfast, offset).*obj.pSensorPeriod;
            
            % Convert to quaternion and multiply to update the
            % orientation. 
            for ii=1:size(deltaAng ,1)  
                deltaq = quaternion(deltaAng (ii,:), 'rotvec');
                qorient  = qorient*deltaq;
            end
           
            % Force rotation angle to be positive
            if parts(qorient) < 0
                qorient = -qorient;
            end
        end

    end



end

function c = gms2()
    c = fusion.internal.UnitConversions.geeToMetersPerSecondSquared(1);
end
