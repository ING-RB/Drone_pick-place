classdef (Hidden) IMUFilterBase < fusion.internal.IMUFusionCommon
%IMUFILTERBASE Base class for imufilter
%
%   This class is for internal use only. It may be removed in the future.

%   Copyright 2017-2023 The MathWorks, Inc.
    
%#codegen

    properties (Abstract)
        InitialProcessNoise
    end

    methods(Access = protected)
        function resetImpl(obj)

            ex = obj.pInputPrototype;
            obj.pOrientPost = quaternion.ones(1,1, 'like', ex); 

            % Zero out initial errors and Gyro Offset
            obj.pGyroOffset = zeros(1,3,'like', ex);
      
            % Initialize noise variances
            updateMeasurementErrCov(obj);

            obj.pQw = cast(obj.InitialProcessNoise, 'like', ex);

            obj.pLinAccelPost = zeros(1,3,'like', ex);
            
            obj.pFirstTime = true;
        end

        function validateInputsImpl(obj, accelIn, gyroIn)
            validateattributes(accelIn, {'double', 'single'}, ...
                {'real', 'nonempty', '2d', 'ncols', 3}, ...
                '', 'acceleration',1);
            r = size(accelIn,1);
            dt = class(accelIn);
            validateattributes(gyroIn, {dt}, ...
                {'real', 'nonempty', '2d', 'ncols', 3, 'nrows', r}, ...
                '', 'angularVelocity',2);

            % From validation above we know both have the same number of
            % rows. Validate compatibility with frame size.
            validateFrameSize(obj, size(accelIn));
        end

        function num = getNumInputsImpl(~)
          num = 2;
        end
        
        function [orientOut, av, interData] = stepImpl(obj, accelIn, gyroIn)

            % Fuse the sensor readings from the accelerometer
            % and gyroscope. 
            %   accelIn - Nx3 matrix of accel samples in m/s^2
            %   gyroIn - Nx3 matrix of gyro samples in rad/s
            
            if isa(accelIn, 'double') && isa(gyroIn, 'double') 
                cls = 'double';
            else
                cls = 'single';
            end

            
            % Want to have DecimationFactor-by-3-by-??? matrices so we can
            % page through the 3rd dimension on each trip through the
            % for...loop below.
            accelIn = reshape(accelIn', 3, obj.DecimationFactor, []);
            gyroIn = reshape(gyroIn', 3, obj.DecimationFactor, []);

            accelIn = permute(accelIn, [2,1,3]);
            gyroIn = permute(gyroIn, [2,1,3]);
            
            ref = obj.pRefSys;

            numiters = size(accelIn,3);

            % Allocate output
            [av, orientOut] = allocateOutputs(obj, numiters, cls);
            if nargout > 2
                t = struct('Residual', zeros(1, 3, cls), ...
                           'ResidualCovariance', zeros(3, 3, cls));
                interData = repmat(t, numiters, 1);
            end

            % Loop through each frame. 
            for iter=1:numiters
                % Indirect Kalman filter. Track the *errors* in the
                % estimates of the 
                %   the orientation (as a 3-element rotation vector)
                %   gyroscope bias
                %   linear acceleration
                %
                % The Kalman filter tracks these errors. The actual
                % orientation, gyroscope bias and linear acceleration are
                % updated with the Kalman filter states after
                % predict & correct phases.
                %

                afast = accelIn(:,:,iter);
                gfast = gyroIn(:,:,iter);

                [angularVelocity, obj.pFirstTime, ...
                 obj.pGyroOffset, obj.pQw, ...
                 obj.pOrientPrior, obj.pOrientPost, ...
                 obj.pLinAccelPrior, obj.pLinAccelPost, ...
                 res, resCovar] = stepCoreCode(obj, afast, gfast, ...
                                               ref, cls, obj.pFirstTime,...
                                               obj.pGyroOffset, obj.pQw,...
                                               obj.pOrientPost, ...
                                               obj.pLinAccelPost);
               
                % Populate output arguments
                av(iter,:) = angularVelocity;
                if strcmpi(obj.OrientationFormat, 'quaternion') 
                    orientOut(iter,:) = obj.pOrientPost;
                else
                    orientOut(:,:,iter) = rotmat(obj.pOrientPost, 'frame');
                end
                if nargout > 2
                    interData(iter).Residual = res';
                    interData(iter).ResidualCovariance = resCovar;
                end
            end

        end

        function processTunedPropertiesImpl(obj)
            processTunedPropertiesImpl@fusion.internal.IMUFusionCommon(obj);
            updateMeasurementErrCov(obj);
        end
     
    end

    methods
        function [res, resCovar] = residual(obj, accelIn, gyroIn)
            %RESIDUAL Residual and residual covariance from accelerometer
            % and gyroscope sensor data
            %   [RES, RESCOVAR] = RESIDUAL(FUSE, ACCEL, GYRO) computes the
            %   residual RES and residual covariance RESCOVAR, based on the
            %   accelerometer data ACCEL and gyroscope data GYRO. The
            %   inputs are:
            %       ACC  - N-by-3 array of accelerometer readings in m/s^2
            %       GYRO - N-by-3 array of gyroscope readings in rad/s
            %   where N is the number of samples. The three columns of each
            %   input array represent the [X Y Z] measurements. The outputs
            %   are:
            %       RES      - M-by-3 array of residual in m/s^2
            %       RESCOVAR - 3-by-3-by-M array of residual covariance
            %   M is determined by N and the DecimationFactor property.
            %
            %   Example:
            %       % Get residual from accelerometer and gyroscope
            %       % measurements.
            %       % Load the data
            %       ld = load('rpy_9axis.mat');
            %       accel = ld.sensorData.Acceleration;
            %       gyro = ld.sensorData.AngularVelocity;
            %
            %       % Create the imufilter object
            %       fuse = imufilter('SampleRate', 100, ...
            %                        'DecimationFactor', 2);
            %
            %       % Compute the residuals
            %       [res, resCovar] = residual(fuse, accel, gyro);
            %
            %   See also imufilter, imufilter/tune

            % call setup if step was not called before first call to
            % residual
            if ~isLocked(obj)
              if isempty(coder.target)
                obj.setup(accelIn, gyroIn);
                obj.reset();
              else
                  obj.setupAndReset(accelIn, gyroIn);
              end
            end

            % validate the inputs
            validateInputsImpl(obj, accelIn, gyroIn);

            % get the class of the data
            if isa(accelIn, 'double') && isa(gyroIn, 'double')
                cls = 'double';
            else
                cls = 'single';
            end

            % Want to have DecimationFactor-by-3-by-??? matrices so we can
            % page through the 3rd dimension on each trip through the
            % for...loop below.
            accelIn = reshape(accelIn', 3, obj.DecimationFactor, []);
            gyroIn = reshape(gyroIn', 3, obj.DecimationFactor, []);

            accelIn = permute(accelIn, [2,1,3]);
            gyroIn = permute(gyroIn, [2,1,3]);

            ref = obj.pRefSys;

            numiters = size(accelIn,3);

            % Allocate output
            res = zeros(numiters, 3, cls);
            resCovar = zeros(3,3,numiters, cls);

            % Create variables for internal variables
            pFirstTimeIn     = obj.pFirstTime;
            respGyroOffset   = obj.pGyroOffset;
            respQw           = obj.pQw;
            respOrientPost   = obj.pOrientPost;
            respLinAccelPost = obj.pLinAccelPost;

            % Loop through each frame.
            for iter=1:numiters
                afast = accelIn(:,:,iter);
                gfast = gyroIn(:,:,iter);

                [~, pFirstTimeIn, ...
                 respGyroOffset, respQw, ...
                 ~, respOrientPost, ...
                 ~, respLinAccelPost, ...
                 res(iter,:), resCovar(:,:,iter)] = ...
                                        stepCoreCode(obj, afast, gfast, ...
                                            ref, cls, pFirstTimeIn, ...
                                            respGyroOffset, respQw, ...
                                            respOrientPost, ...
                                            respLinAccelPost);
            end
        end
    end

    methods (Access = private)
        function updateMeasurementErrCov(obj)
            accelMeasNoiseVar = obj.AccelerometerNoise + ...
                obj.LinearAccelerationNoise + ((obj.pKalmanPeriod).^2) *...
                    (obj.GyroscopeDriftNoise + obj.GyroscopeNoise);

            obj.pQv = accelMeasNoiseVar.* ...
                      eye(3, 'like', obj.pInputPrototype);
        end

        function [angularVelocity, pFirstTimeIn, ...
                  pGyroOffsetOut, Qw, ...
                  pOrientPriorOut, pOrientPostOut, ...
                  pLinAccelPriorOut, pLinAccelPostOut, ...
                  ze, tmp] = stepCoreCode(obj, afast, gfast, ...
                                          ref, cls, pFirstTimeIn, ...
                                          pGyroOffsetIn, pQwIn, ...
                                          pOrientPostIn, pLinAccelPostIn)

            angularVelocity = computeAngularVelocity(obj, gfast, ...
                                                     pGyroOffsetIn);

            % We only need fast gyro readings. Accel can be 
            % downsampled to the most recent reading.
            accel = afast(end,:);

            pOrientPostOut = pOrientPostIn;

            if pFirstTimeIn
                % Basic tilt corrected ecompass orientation algorithm.
                % Do this the first time only. Need inputs, so not in setupImpl.

                % No magnetometer - assume device is pointing north
                m = zeros(1,3, cls);
                m(ref.NorthIndex) = 1;
                Rpost = ref.ecompass(accel, m);
                pFirstTimeIn = false;
                pOrientPostOut = quaternion(Rpost, 'rotmat', 'frame');
            end

            % Update the orientation quaternion based on the gyroscope
            % readings.
            pOrientPriorOut = predictOrientation(obj, gfast, ...
                pGyroOffsetIn, pOrientPostOut);

            % Back to Rotation matrix
            Rprior = rotmat(pOrientPriorOut, 'frame');

            %%%%%%%%%%%%%%%%
            % The Kalman filter measurement:
            %   Accel estimate of gravity - Gyro estimate of gravity

            % Gyro : Rprior is from the gyro measurements (above).
            % Gravity vector is one column of that matrix.
            gravityGyroMeas = rotmat2gravity(obj, Rprior);

            % Accel: Decay the estimate of the linear acceleration and
            % subtract it from the accelerometer reading.
            pLinAccelPriorOut = obj.LinearAccelerationDecayFactor * pLinAccelPostIn;
            gravityAccelMeas = ref.GravitySign*accel + pLinAccelPriorOut;

            gravityAccelGyroDiff = gravityAccelMeas - gravityGyroMeas;

            %%%%%%%%%%%%%%%%
            % Compute the Measurement Matrix H and Kalman Gain K
            % Measurement matrix H 3-by-9
            h1 = obj.buildHPart(gravityGyroMeas);

            h3 = -h1.*obj.pKalmanPeriod;
            H = [h1, h3, eye(3)];

            % Calculate the Kalman Gain K
            Qv = obj.pQv;
            Qw = pQwIn;

            tmp = ((H * Qw * (H.') + Qv).');
            K = Qw * (H.')  / ( tmp);

            % Update a posteriori error using the Kalman gain
            ze = gravityAccelGyroDiff.';

            xe_post = K * ze;
            % Corrected error estimates
            orientErr = xe_post(1:3).';
            gyroOffsetErr = xe_post(4:6).';
            linAccelErr = xe_post(7:9).';

            % Estimate estimates based on the Kalman filtered error
            % estimates.
            %
            % Convert orientation error into a quaternion.
            % Update a posteriori orientation
            qerr = conj(quaternion(orientErr, 'rotvec'));
            pOrientPostOut = pOrientPriorOut * qerr;

            % Force rotation angle to be positive
            if parts(pOrientPostOut) < 0
                pOrientPostOut = -pOrientPostOut;
            end

            pOrientPostOut = normalize(pOrientPostOut);

            % Subtract estimated errors for gyro bias and linear
            % acceleration
            pGyroOffsetOut = pGyroOffsetIn - gyroOffsetErr;
            pLinAccelPostOut = pLinAccelPriorOut - linAccelErr;

            % Calculate a posterior error covariance matrix
            Ppost = Qw - K * (H * Qw);

            % Update Qw - the process noise. Qw is a function of Ppost
            Qw = zeros(9, cls);

            Qw(getDiags(1:3)) = Ppost(getDiags(1:3)) + ((obj.pKalmanPeriod).^2)* ...
                (Ppost(getDiags(4:6)) + (obj.GyroscopeDriftNoise + ...
                obj.GyroscopeNoise));

            Qw(getDiags(4:6)) = Ppost(getDiags(4:6)) + ...
                obj.GyroscopeDriftNoise;

            offDiag = -obj.pKalmanPeriod * Qw(getDiags(4:6));

            Qw([4 14 24]) = offDiag;
            Qw([28 38 48]) = offDiag;

            Qw(getDiags(7:9)) = (obj.LinearAccelerationDecayFactor.^2)* ...
                Ppost(getDiags(7:9)) + obj.LinearAccelerationNoise;
        end
    end

    methods (Static, Hidden)
        function covinit = getInitialProcCov()
        %GETINITIALPROCCOV - default initial process covariance
            covinit = zeros(9,9);
            covinit(1:3,1:3) = fusion.internal.IMUFilterBase.cOrientErrVar*eye(3);
            covinit(4:6,4:6) = fusion.internal.IMUFilterBase.cGyroBiasErrVar*eye(3);
            covinit(1:3,4:6) = fusion.internal.IMUFilterBase.cOrientGyroBiasErrVar*eye(3);
            covinit(4:6,1:3) = covinit(1:3,4:6);
            covinit(7:9,7:9) = fusion.internal.IMUFilterBase.cAccErrVar* eye(3);
            covinit = covinit .* fusion.internal.IMUFilterBase.getInitialProcCovMask; 
        end
        function msk = getInitialProcCovMask()
        %GETINITIALPROCCOVMASK - show possible nonzero entries in mask
            msk = false(9,9);
            msk(1:3,1:3) = true*eye(3);
            msk(4:6,4:6) = true*eye(3);
            msk(1:3,4:6) = true*eye(3);
            msk(4:6,1:3) = msk(1:3,4:6);
            msk(7:9,7:9) = true* eye(3);
        end
    end
end

function d = getDiags(r)
%Get diagonal elements in a 9 x 9 matrix where r is the column (or row) index
sz = 9;
rm1 = r - 1;
d = rm1*(sz+1) + 1;
end

