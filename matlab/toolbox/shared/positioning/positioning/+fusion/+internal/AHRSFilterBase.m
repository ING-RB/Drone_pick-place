classdef (Hidden) AHRSFilterBase < fusion.internal.IMUFusionCommon 
%AHRSFILTERBASE Base class for ahrsfilter
%
%   This class is for internal use only. It may be removed in the future.


%   Copyright 2017-2024 The MathWorks, Inc.

%#codegen

    properties 
        %MagnetometerNoise Noise variance in the magnetometer data 
        %   Specify the noise in the magnetometer data in units of uT^2.
        %   Magnetometer noise variance must be a positive scalar value.
        %   The default value for this property is 0.1 uT^2. This property is
        %   tunable. 
        MagnetometerNoise= 0.1;
        
        %MagneticDisturbanceNoise Variance for magnetic disturbance 
        %   Specify the noise in the magnetic disturbance model in units of
        %   uT^2. Magnetic disturbance is modeled as a first order Markov
        %   process. Magnetic disturbance noise variance must be a positive
        %   scalar value. The default value for this property is 0.5 uT^2.
        %   This property is tunable. 
        MagneticDisturbanceNoise = 0.5;

        %MagneticDisturbanceDecayFactor Decay factor for magnetic disturbance 
        %   Specify the decay factor in the magnetic disturbance model.
        %   Magnetic disturbance is modeled as a first order Markov process.
        %   Magnetic disturbance decay factor must be a non-negative real
        %   number less than 1. This property is tunable.
        MagneticDisturbanceDecayFactor = 0.5;

        %ExpectedMagneticFieldStrength Expected estimate of magnetic field strength
        %   Specify the expected magnetic field strength as a real positive
        %   scalar value.  The expected magnetic field strength is an
        %   estimate of the Earth's magnetic field strength at the current
        %   location in units of uT.  The default value for this property
        %   is 50 uT. This property is tunable.
        ExpectedMagneticFieldStrength = 50;
    end

    properties (Abstract)
        InitialProcessNoise
    end

    properties (Constant, Hidden) %Noise Variance for Covariance Matrix
        cMagErrVar       = 600e-3; %var in mag disturbance error estim
    end

    properties (Constant, Access = protected)
        cJammingFactor = 4; % Mag field strength >4x expected --> Jamming.
        cInclinationLimit = deg2rad(90);
    end

    properties (Access = private)
        pMagVec                  % Earth's geomagnetic vector (uT)
                                 % in global frame, East component = 0
        pInclinationLimit
    end
    
    methods
        function set.MagnetometerNoise(obj,val)
            validateattributes(val, {'numeric'}, ...
                {'real', 'nonempty', 'scalar', 'finite', 'positive', ...
                'nonsparse'}, ...
                'set.MagnetometerNoise', 'MagnetometerNoise' );
            obj.MagnetometerNoise = val;
        end

        function set.MagneticDisturbanceNoise(obj,val)
            validateattributes(val, {'numeric'}, ...
                {'real', 'nonempty', 'scalar', 'finite', 'positive', ...
                'nonsparse'}, ...
                'set.MagneticDisturbanceNoise', 'MagneticDisturbanceNoise' );
            obj.MagneticDisturbanceNoise = val;
        end

        function set.MagneticDisturbanceDecayFactor(obj,val)
            validateattributes(val, {'numeric'}, ...
                {'real', 'nonempty', 'scalar', 'finite', ...
                '<' 1, '>=', 0, ...
                'nonsparse'}, ...
                'set.MagneticDisturbanceDecayFactor', 'MagneticDisturbanceDecayFactor' );
            obj.MagneticDisturbanceDecayFactor = val;
        end

        function set.ExpectedMagneticFieldStrength(obj,val)
            validateattributes(val, {'numeric'}, ...
                {'real', 'nonempty', 'scalar', 'finite', 'positive', ...
                'nonsparse'}, ...
                'set.ExpectedMagneticFieldStrength', 'ExpectedMagneticFieldStrength' );
            obj.ExpectedMagneticFieldStrength = val;
        end

    end

    methods(Access = protected)
        function resetImpl(obj)

            ex = obj.pInputPrototype;
            obj.pOrientPost = quaternion.ones(1,1, 'like', ex); 

            % Zero out initial errors and Gyro Offset
            obj.pGyroOffset = zeros(1,3,'like', ex);
            ref = obj.pRefSys;

            obj.pMagVec = zeros(1,3,'like', ex);
            obj.pMagVec(obj.pRefSys.NorthIndex) = ref.NorthAxisSign* ...
                cast(obj.ExpectedMagneticFieldStrength, 'like',ex);

            % Initialize noise variances
            updateMeasurementErrCov(obj);

            obj.pQw = cast(obj.InitialProcessNoise, 'like', ex);

            obj.pLinAccelPost = zeros(1,3,'like', ex);
            
            obj.pFirstTime = true;

            % Cast the Inclination Limit value and store it
            obj.pInclinationLimit = cast(obj.cInclinationLimit, ...
                                            'like', ex);
        end

        function s = saveObjectImpl(obj)
            % Default implementation saves all public properties
            s = saveObjectImpl@fusion.internal.IMUFusionCommon(obj);
            if isLocked(obj)
                s.pMagVec           = obj.pMagVec;
                s.pInclinationLimit = obj.pInclinationLimit;
            end
        end        

        function s = loadObjectImpl(obj, s, wasLocked)
            % Reload states if saved version was locked 
            loadObjectImpl@fusion.internal.IMUFusionCommon(obj, s, wasLocked);

            if wasLocked 
                obj.pMagVec           = s.pMagVec;
                obj.pInclinationLimit = cast(obj.cInclinationLimit, ...
                                             'like', obj.pInputPrototype);
            end
        end        

        function validateInputsImpl(obj, accelIn, gyroIn, magIn)
            validateattributes(accelIn, {'double', 'single'}, ...
                {'real', 'nonempty', '2d', 'ncols', 3}, ...
                '', 'acceleration',1);
            r = size(accelIn,1);
            validateattributes(gyroIn, {'double', 'single'}, ...
                {'real', 'nonempty', '2d', 'ncols', 3, 'nrows', r}, ...
                '', 'angularVelocity',2);

            validateattributes(magIn, {'double', 'single'}, ... 
                {'real', 'nonempty', '2d', 'ncols', 3, 'nrows', r}, ...
                '', 'magneticField',3);

            % From validation above we know both have the same number of
            % rows. Validate compatibility with frame size.
            validateFrameSize(obj, size(accelIn));
        end

        function num = getNumInputsImpl(~)
          num = 3;
        end

        function [orientOut, av, interData] = stepImpl(obj, ...
                                                    accelIn, gyroIn, magIn)

            % Fuse the sensor readings from the accelerometer, magnetometer
            % and gyroscope.

            if isa(accelIn, 'double') && isa(gyroIn, 'double') && ...
                isa(magIn, 'double')
                cls = 'double';
            else
                cls = 'single';
            end

            % Want to have DecimationFactor-by-3-by-??? matrices so we can
            % page through the 3rd dimension on each trip through the
            % for...loop below.
            afastmat = reshape(accelIn.', 3, obj.DecimationFactor, []);
            mfastmat = reshape(magIn.', 3, obj.DecimationFactor, []);
            gfastmat = reshape(gyroIn.', 3, obj.DecimationFactor, []);

            afastmat = permute(afastmat, [2,1,3]);
            mfastmat = permute(mfastmat, [2,1,3]);
            gfastmat = permute(gfastmat, [2,1,3]);

            ref = obj.pRefSys;
            northIdx = ref.NorthIndex;
            gravIdx = ref.GravityIndex;

            numiters = size(afastmat,3);

            % Allocate output
            [av, orientOut] = allocateOutputs(obj, numiters, cls);
            if nargout > 2
                t = struct('Residual', zeros(1, 6, cls), ...
                           'ResidualCovariance', zeros(6, 6, cls));
                interData = repmat(t, numiters, 1);
            end

            % Loop through each frame. 
            for iter=1:numiters
                % Indirect Kalman filter. Track the *errors* in the
                % estimates of the 
                %   the orientation (as a 3-element rotation vector)
                %   gyroscope bias
                %   linear acceleration
                %   magnetic disturbance
                %
                % The Kalman filter tracks these errors. The actual
                % orientation, gyroscope bias and linear acceleration are
                % updated with the Kalman filter states after
                % predict & correct phases.
                %

                afast = afastmat(:,:,iter);
                gfast = gfastmat(:,:,iter);
                mfast = mfastmat(:,:,iter);

                [Rpost, angularVelocity, ...
                 obj.pFirstTime, ...
                 obj.pGyroOffset, obj.pMagVec, obj.pQw, ...
                 obj.pOrientPrior, obj.pOrientPost, ...
                 obj.pLinAccelPrior, obj.pLinAccelPost, ...
                 res, resCovar] = ...
                                stepCoreCode(obj, afast, gfast, mfast, ...
                                ref, northIdx, gravIdx, cls, ...
                                obj.pFirstTime, ...
                                obj.pGyroOffset, obj.pMagVec, obj.pQw, ...
                                obj.pOrientPost, ...
                                obj.pLinAccelPost);

                % Done with estimate updates
                av(iter,:) = angularVelocity;
                if strcmpi(obj.OrientationFormat, 'quaternion') 
                    orientOut(iter,:) = obj.pOrientPost;
                else
                    orientOut(:,:,iter) = Rpost; 
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
        function [res, resCovar] = residual(obj, accelIn, gyroIn, magIn)
            %RESIDUAL Residual and residual covariance from accelerometer,
            % gyroscope, and magnetometer sensor data
            %   [RES, RESCOVAR] = RESIDUAL(FUSE, ACCEL, GYRO, MAG) computes
            %   the residual RES and residual covariance RESCOVAR, based
            %   on the accelerometer data ACCEL, gyroscope data GYRO, and
            %   magnetometer data MAG. The inputs are:
            %       ACC  - N-by-3 array of accelerometer readings in m/s^2
            %       GYRO - N-by-3 array of gyroscope readings in rad/s
            %       MAG  - N-by-3 array of magnetometer readings in uT
            %   where N is the number of samples. The three columns of each
            %   input array represent the [X Y Z] measurements. The outputs
            %   are:
            %       RES      - M-by-6 array of residual of form
            %                  [m/s^2 m/s^2 m/s^2 uT uT uT]
            %       RESCOVAR - 6-by-6-by-M array of residual covariance
            %   M is determined by N and the DecimationFactor property.
            %
            %   Example:
            %       % Get residual from accelerometer, gyroscope and
            %       % magnetometer measurements.
            %       % Load the data
            %       ld = load('rpy_9axis.mat');
            %       accel = ld.sensorData.Acceleration;
            %       gyro = ld.sensorData.AngularVelocity;
            %       mag = ld.sensorData.MagneticField;
            %
            %       % Create the ahrsfilter object
            %       fuse = ahrsfilter('SampleRate', 100, ...
            %                         'DecimationFactor', 2);
            %
            %       % Compute the residuals
            %       [res, resCovar] = residual(fuse, accel, gyro, mag);
            %
            %   See also ahrsfilter, ahrsfilter/tune


            % call setup if step was not called before first call to
            % residual
            if ~isLocked(obj)
              if isempty(coder.target)
                obj.setup(accelIn, gyroIn, magIn);
                obj.reset();
              else
                  obj.setupAndReset(accelIn, gyroIn, magIn);
              end
            end

            % validate the inputs
            validateInputsImpl(obj, accelIn, gyroIn, magIn);

            % get the class of the data
            if isa(accelIn, 'double') && isa(gyroIn, 'double') && ...
                isa(magIn, 'double')
                cls = 'double';
            else
                cls = 'single';
            end

            % Want to have DecimationFactor-by-3-by-??? matrices so we can
            % page through the 3rd dimension on each trip through the
            % for...loop below.
            afastmat = reshape(accelIn.', 3, obj.DecimationFactor, []);
            mfastmat = reshape(magIn.', 3, obj.DecimationFactor, []);
            gfastmat = reshape(gyroIn.', 3, obj.DecimationFactor, []);

            afastmat = permute(afastmat, [2,1,3]);
            mfastmat = permute(mfastmat, [2,1,3]);
            gfastmat = permute(gfastmat, [2,1,3]);

            % get reference frame
            ref = obj.pRefSys;
            northIdx = ref.NorthIndex;
            gravIdx = ref.GravityIndex;

            % get number of samples
            numiters = size(afastmat,3);

            % Allocate output
            res = zeros(numiters, 6, cls);
            resCovar = zeros(6,6,numiters, cls);

            % Create variables for internal variables
            pFirstTimeIn     = obj.pFirstTime;
            respGyroOffset   = obj.pGyroOffset;
            respMagVec       = obj.pMagVec;
            respQw           = obj.pQw;
            respOrientPost   = obj.pOrientPost;
            respLinAccelPost = obj.pLinAccelPost;

            % Loop through each frame. 
            for iter=1:numiters
                afast = afastmat(:,:,iter);
                gfast = gfastmat(:,:,iter);
                mfast = mfastmat(:,:,iter);

                [~, ~, pFirstTimeIn, ...
                 respGyroOffset, respMagVec, respQw, ...
                 ~, respOrientPost, ~, respLinAccelPost, ...
                 res(iter,:), resCovar(:,:,iter)] = ...
                                stepCoreCode(obj, afast, gfast, mfast, ...
                                ref, northIdx, gravIdx, cls, ...
                                pFirstTimeIn, respGyroOffset, ...
                                respMagVec, respQw, respOrientPost, ...
                                respLinAccelPost);
            end
        end
    end

    methods (Access = private)
         function updateMeasurementErrCov(obj)
             accelMeasNoiseVar = obj.AccelerometerNoise + ...
                 obj.LinearAccelerationNoise + ((obj.pKalmanPeriod).^2) *...
                     (obj.GyroscopeDriftNoise  + obj.GyroscopeNoise);

             magMeasNoiseVar = obj.MagnetometerNoise + ...
                 obj.MagneticDisturbanceNoise + ((obj.pKalmanPeriod).^2) *...
                     (obj.GyroscopeDriftNoise+ obj.GyroscopeNoise);

             obj.pQv = blkdiag(accelMeasNoiseVar*eye(3, ...
                 'like', obj.pInputPrototype), magMeasNoiseVar*eye(3));

         end

         function [Rpost, angularVelocity, ...
                   pFirstTimeIn, pGyroOffsetOut, pMagVecIn, ...
                   Qw, pOrientPriorOut, pOrientPostOut, ...
                   pLinAccelPriorOut, pLinAccelPostOut, ...
                   res, resCovar] = stepCoreCode(obj, ...
                                        afast, gfast, mfast, ...
                                        ref, northIdx, gravIdx, cls, ...
                                        pFirstTimeIn, ...
                                        pGyroOffsetIn, pMagVecIn, pQwIn,...
                                        pOrientPostIn, pLinAccelPostIn)
            
                angularVelocity = computeAngularVelocity(obj, ...
                                                    gfast, pGyroOffsetIn);

                % We only need fast gyro readings. Mag and Accel can be
                % downsampled to the most recent reading.
                mag = mfast(end,:);
                accel = afast(end,:);

                pOrientPostOut = pOrientPostIn;

                if pFirstTimeIn
                    % Basic tilt corrected ecompass orientation algorithm.
                    % Do this the first time only. Need inputs, so not in
                    % setupImpl.
                    Rpost = ref.ecompass(accel, mag);
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
                %   Mag estimate of MagVec - Gyro estimate of MagVec
                
                % Gyro : Rprior is from the gyro measurements (above).
                % Gravity vector is one column of that matrix.
                gravityGyroMeas = rotmat2gravity(obj, Rprior); 

                % Accel: Decay the estimate of the linear acceleration and
                % subtract it from the accelerometer reading. 
                pLinAccelPriorOut = obj.LinearAccelerationDecayFactor * pLinAccelPostIn; 
                gravityAccelMeas = ref.GravitySign*accel + pLinAccelPriorOut; 

                gravityAccelGyroDiff = gravityAccelMeas - gravityGyroMeas;

                % Earth's mag vec (uT) from gyro updates
                magVecGyroMeas = (Rprior * pMagVecIn')';

                magVecMagGyroDiff = mag - magVecGyroMeas;

                %%%%%%%%%%%%%%%%
                % Compute the Measurement Matrix H and Kalman Gain K
                % Measurement matrix H 6-by-12
                
                h1 = obj.buildHPart(gravityGyroMeas);
                h2 = obj.buildHPart(magVecGyroMeas);
                
                h3 = -h1.*obj.pKalmanPeriod; 
                h4 = -h2.*obj.pKalmanPeriod; 
                   
                H = [h1 h3 eye(3) zeros(3); 
                    h2 h4 zeros(3) -eye(3)];

                % Calculate the Kalman Gain K
                Qv = obj.pQv;
                Qw = pQwIn;
                
                resCovar = ((H * Qw * (H.') + Qv).');

                % Kalman gain is 12-by-6
                K = Qw * (H.')  / ( resCovar);

                % Update a posteriori error using the Kalman gain
                res = [ gravityAccelGyroDiff.';magVecMagGyroDiff.' ];                
                magDistErr = (K(10:12,:) * res).';

                %%%%%%%%%%%%%%%%%%
                % Jamming Detection
                % Determine if magnetic jamming is happening
                % Power in the magnetic disturbance error:
                magDistPower = (norm(magDistErr.')).^2;
                isJamming = (magDistPower > ...
                    obj.cJammingFactor*(obj.ExpectedMagneticFieldStrength).^2);

                % If jamming is happening, don't use magnetometer
                % measurements.
                if isJamming
                    jamze = gravityAccelGyroDiff';
                    jamxe_post = K(1:9, 1:3) * jamze;
                    orientErr = jamxe_post(1:3).';
                    gyroOffsetErr = jamxe_post(4:6).';
                    linAccelErr = jamxe_post(7:9).';      
                else
                    % Normal case. No Jamming
                    xe_post = K * res;
                    % Error parts of xe_post
                    orientErr = xe_post(1:3).';
                    gyroOffsetErr = xe_post(4:6).';
                    linAccelErr = xe_post(7:9).';
                end

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
                Rpost = rotmat(pOrientPostOut, 'frame');

                % Subtract estimated errors for gyro bias and linear
                % acceleration 
                pGyroOffsetOut = pGyroOffsetIn - gyroOffsetErr;
                pLinAccelPostOut = pLinAccelPriorOut - linAccelErr; 

                % If no jamming, update the Magnetic Vector estimate 
                if ~isJamming
                    % Rotate the magnetic disturbance to the global frame
                    
                    magDistErrGlobal = ((Rpost.')*magDistErr.').';
                    mtmp = pMagVecIn - magDistErrGlobal;
                    inclination = atan2(ref.GravityAxisSign * mtmp(ref.GravityIndex), ...
                        ref.NorthAxisSign * mtmp(northIdx));

                    % Limit the inclination angle
                    if inclination < -obj.pInclinationLimit
                        inclination(:) = -obj.cInclinationLimit;
                    end
                    if inclination > obj.pInclinationLimit
                        inclination(:) = obj.cInclinationLimit;
                    end

                    % Use the inclination angle to build a pMagVec.
                    %
                    % Why is the East component of pMagVec equal to 0?
                    % Answer: The filter navigates to magnetic north, not
                    % true north. In this case there is no East component
                    % to the geomagnetic vector - it simply points north
                    % and down. If we were navigating to true north then
                    % there would be an easterly component. 
                    % When rotated by the estimated orientation this should
                    % match the magnetometer reading (or be close to it). 
                    
                    pMagVecIn = zeros(1,3,cls);
                    pMagVecIn(northIdx) = ref.NorthAxisSign*cos(inclination);
                    pMagVecIn(gravIdx) = ref.GravityAxisSign*sin(inclination);
                    pMagVecIn = obj.ExpectedMagneticFieldStrength .* pMagVecIn;
                    
                end
              
                % Calculate posterior covariance matrix
                Ppost = Qw - K * (H * Qw);
               
                % Update Qw - the process noise. Qw is a function of Ppost
                Qw = zeros(12, cls);

                Qw(getDiags(1:3)) = Ppost(getDiags(1:3)) + ((obj.pKalmanPeriod).^2)* ...
                    (Ppost(getDiags(4:6)) + (obj.GyroscopeDriftNoise + ...
                    obj.GyroscopeNoise));

                Qw(getDiags(4:6)) = Ppost(getDiags(4:6)) + ...
                    obj.GyroscopeDriftNoise;

                offDiag = -obj.pKalmanPeriod * Qw(getDiags(4:6));
                Qw([4 17 30]) = offDiag;
                Qw([37 50 63]) = offDiag;

                Qw(getDiags(7:9)) = (obj.LinearAccelerationDecayFactor.^2)* ...
                    Ppost(getDiags(7:9)) + obj.LinearAccelerationNoise;
                    

                Qw(getDiags(10:12)) = (obj.MagneticDisturbanceDecayFactor.^2)* ...
                    Ppost(getDiags(10:12)) + ...
                    obj.MagneticDisturbanceNoise;
         end
    end

    methods (Static)
        function covinit = getInitialProcCov()
        %GETINITIALPROCCOV - default initial process covariance
            covinit = zeros(12,12);
            covinit(1:3,1:3) = fusion.internal.AHRSFilterBase.cOrientErrVar*eye(3);
            covinit(4:6,4:6) = fusion.internal.AHRSFilterBase.cGyroBiasErrVar*eye(3);
            covinit(1:3,4:6) = fusion.internal.AHRSFilterBase.cOrientGyroBiasErrVar*eye(3);
            covinit(4:6,1:3) = covinit(1:3,4:6);
            covinit(7:9,7:9) = fusion.internal.AHRSFilterBase.cAccErrVar* eye(3);
            covinit(10:12,10:12) = fusion.internal.AHRSFilterBase.cMagErrVar * eye(3);
            covinit = covinit .* fusion.internal.AHRSFilterBase.getInitialProcCovMask; 
        end
        function msk = getInitialProcCovMask()
        %GETINITIALPROCCOVMASK - show possible nonzero entries in mask
            msk = false(12,12);
            msk(1:3,1:3) = true*eye(3);
            msk(4:6,4:6) = true*eye(3);
            msk(1:3,4:6) = true*eye(3);
            msk(4:6,1:3) = msk(1:3,4:6);
            msk(7:9,7:9) = true* eye(3);
            msk(10:12,10:12) = true * eye(3);
        end
    end
end


function d = getDiags(r)
% Get diagonal elements in a 12 x 12 matrix where r is the column (or row) index
sz = 12;
rm1 = r - 1;
d = rm1*(sz+1) + 1;
end

