classdef monovslam < vision.internal.vslam.BaseVisualSLAM

% Copyright 2022-2024 The MathWorks, Inc.

%#codegen
    properties (Hidden, Access = protected)
        SlamObj

        Version = 2.0
    end


    methods (Access = public)

        function vslam = monovslam(intrinsics, IMUParameters, args)
            arguments
                intrinsics
                IMUParameters = []
                args.ScaleFactor
                args.NumLevels
                args.MaxNumPoints
                args.TrackFeatureRange
                args.SkipMaxFrames
                args.LoopClosureThreshold
                args.Verbose
                args.CustomBagOfFeatures
                args.CameraToIMUTransform
                args.NumPosesThreshold
                args.AlignmentFraction
                args.MaxAlignmentError
                args.ThreadLevel
                args.MaxReprojectionErrorPnP
                args.MinParallax
                args.MaxReprojectionErrorBA
                args.MaxNumIterationsBA
                args.MinPGOInterval
                args.MinNumMatches   
                args.FixPoses = true
                args.InitialVelocity = [0 0 0]
                args.ScaleThreshold = 1e-2
                args.PredictionThreshold = [1e-2 1e-2]       
            end
            
            vslamshs;

            argsCell = namedargs2cell(args);
            vslam = vslam@vision.internal.vslam.BaseVisualSLAM(intrinsics, IMUParameters, argsCell{:});

            coder.extrinsic('matlabroot');
            coder.extrinsic('fullfile');
            
            if coder.target('MATLAB')
                vslam.SlamObj = vision.internal.MonoVisualSLAM();
                vslam.SlamObj.configure(vslam.Intrinsics, ...
                    vslam.HasIMU, ...
                    vslam.IMUParameters, ...
                    vslam.GravityDirection, ...
                    vslam.ScaleFactor,...
                    vslam.NumLevels,...
                    vslam.MaxNumPoints, ...
                    vslam.TrackFeatureRange,...
                    vslam.SkipMaxFrames, ...
                    vslam.LoopClosureThreshold,...
                    vslam.Verbose, ...
                    vslam.VocabFilePath, ...
                    vslam.ThreadLevel, ...
                    vslam.CameraToIMUTransform, ...
                    vslam.NumPosesThreshold, ...
                    vslam.AlignmentFraction, ...
                    vslam.MaxAlignmentError, ...
                    vslam.MaxReprojectionErrorPnP, ...
                    vslam.MinParallaxCosine, ...
                    vslam.MaxReprojectionErrorBA, ...
                    vslam.MaxNumIterationsBA, ...
                    vslam.MinPGOInterval, ...
                    vslam.MinNumMatches, ...
                    vslam.FixPoses, ...
                    vslam.InitialVelocity, ... 
                    vslam.ScaleThreshold, ... 
                    vslam.PredictionThreshold);
            else
                vslam.SlamObj = vision.internal.buildable.MonoVisualSLAMBuildable( ...
                    vslam, ...
                    [vslam.VocabFilePath char(0)]);
            end

            % In Sumulation only, print log file name with a clickable link to open it
            printLogFileOnCMD(vslam);
        end
		
		function addFrame(vslam, I, imuGyro, imuAccel)
            arguments
                vslam
                I
                imuGyro = [];
                imuAccel = [];
            end

            nargoutchk(0, 0);
            
            % Convert image to grayscale uint8
            Iu8      = im2uint8(I);
            Iu8_gray = im2gray(Iu8);
            
            validateattributes(Iu8_gray, {'numeric','logical'}, ...
                {'nonsparse', 'size', vslam.Intrinsics.ImageSize}, mfilename, 'I');

            if vslam.HasIMU && ~isempty(vslam.IMUParameters) % Second condition necessary to avoid generating code for estimateGravityRotationAndPosescale for monovslam w/o IMU

                camPoses  = poses(vslam);
		        numPoses = length(camPoses);

                if nargin>2

                    validateattributes(imuGyro, {'numeric'}, {'nonsparse', 'nonnan', 'finite', 'real'});
                    validateattributes(imuAccel, {'numeric'}, {'nonsparse', 'nonnan', 'finite', 'real'});

                    % Gyro and accel have to be the same size
                    coder.internal.errorIf(numel(imuGyro)~=numel(imuAccel), 'vision:vslam_utils:sameSizeIMU');

                    % Empty gyro and accel are allowed, to account for
                    % cases where IMU is unavailable temporarily
                    if (~isempty(imuGyro) || ~isempty(imuAccel))
                        validateattributes(imuGyro, {'numeric'}, {'ncols', 3});
                        validateattributes(imuAccel, {'numeric'}, {'ncols', 3});
                    end

                    % Throw warning when IMU is unavailable
                    if isempty(imuGyro) && isempty(imuAccel) && numPoses > 1
                        coder.internal.warning(('vision:vslam_utils:noIMUData'));
                    end

                else

                    % Throw warning when IMU is unavailable
                    if numPoses > 1
                        coder.internal.warning(('vision:vslam_utils:noIMUData'));
                    end

                end
                
            else % No IMU

                if nargin>2
				    coder.internal.error('vision:vslam_utils:InvalidIMUParams');
                end

            end
            
            addFrame(vslam.SlamObj, Iu8_gray, imuGyro, imuAccel);
        end

    end


    methods (Static, Hidden)
        function this = loadobj(that)
            % Feature control: Load v1 if feature is OFF
            if that.Version == 1.0 || ~matlab.internal.feature("MonovslamIMU")
                that.ThreadLevel = 2;

                this = monovslam(that.Intrinsics, ...
                    ScaleFactor          = that.ScaleFactor, ...
                    NumLevels            = that.NumLevels, ...
                    MaxNumPoints         = that.MaxNumPoints, ...
                    SkipMaxFrames        = that.SkipMaxFrames, ...
                    TrackFeatureRange    = that.TrackFeatureRange, ...
                    LoopClosureThreshold = that.LoopClosureThreshold, ...
                    Verbose              = that.Verbose, ...
                    ThreadLevel          = that.ThreadLevel);
			
            elseif that.Version == 2.0
					this = monovslam(that.Intrinsics, that.IMUParameters, ...
					ScaleFactor          = that.ScaleFactor, ...
					NumLevels            = that.NumLevels, ...
					MaxNumPoints         = that.MaxNumPoints, ...
					SkipMaxFrames        = that.SkipMaxFrames, ...
					TrackFeatureRange    = that.TrackFeatureRange, ...
					LoopClosureThreshold = that.LoopClosureThreshold, ...
					Verbose              = that.Verbose, ...
					ThreadLevel          = that.ThreadLevel, ...
					CameraToIMUTransform = that.CameraToIMUTransform, ...
					NumPosesThreshold    = that.NumPosesThreshold, ...
					AlignmentFraction    = that.AlignmentFraction, ...
					MaxAlignmentError    = that.MaxAlignmentError);				
            end
        end
    end
end

function vslamshs(~)
if isempty(coder.target)
    try
        vslam.internal.shs();
    catch ME
        throwAsCaller(ME)
    end
end
end