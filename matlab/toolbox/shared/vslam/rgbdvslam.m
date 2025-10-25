classdef rgbdvslam < vision.internal.vslam.BaseVisualSLAM

% Copyright 2023-2024 The MathWorks, Inc.

%#codegen
    properties (SetAccess=private, GetAccess=public)
        DepthScaleFactor

        DepthRange
    end

    properties (Hidden, Access = protected)
        SlamObj

        Version = 2.0
    end

    methods (Access = public)
        function vslam = rgbdvslam(intrinsics, depthScaleFactor, IMUParameters, rgbdArgs, baseArgs)
            arguments
                intrinsics                
                depthScaleFactor (1,1) {mustBeNumeric,mustBePositive,mustBeNonsparse,mustBeFinite}=5000
                IMUParameters = []
                rgbdArgs.DepthRange (1, 2) {mustBeNumeric,mustBeNonnegative,mustBeNonsparse,mustBeFinite,...
                    mustBeMonotonicallyIncreasingDepth}=[0.5 5]
                baseArgs.ScaleFactor
                baseArgs.NumLevels
                baseArgs.MaxNumPoints
                baseArgs.TrackFeatureRange
                baseArgs.SkipMaxFrames
                baseArgs.LoopClosureThreshold
                baseArgs.Verbose
                baseArgs.CustomBagOfFeatures
                baseArgs.CameraToIMUTransform
                baseArgs.NumPosesThreshold
                baseArgs.AlignmentFraction
                baseArgs.ThreadLevel
                baseArgs.MaxReprojectionErrorPnP
                baseArgs.MinParallax
                baseArgs.MaxReprojectionErrorBA
                baseArgs.MaxNumIterationsBA
                baseArgs.MinPGOInterval
                baseArgs.MinNumMatches
                baseArgs.FixPoses = true
                baseArgs.InitialVelocity = [0 0 0]
                baseArgs.ScaleThreshold = 1e-3
                baseArgs.PredictionThreshold = [5e-2 5e-2]
            end

            vslamshs;

            baseArgsCell = namedargs2cell(baseArgs);
            vslam = vslam@vision.internal.vslam.BaseVisualSLAM(intrinsics, IMUParameters, baseArgsCell{:});

            % Assign inputs to vslam object properties
            vslam.DepthScaleFactor     = single(depthScaleFactor);
            vslam.DepthRange           = rgbdArgs.DepthRange;

            coder.extrinsic('matlabroot');
            coder.extrinsic('fullfile');

            if coder.target('MATLAB')
                vslam.SlamObj = vision.internal.RGBDVisualSLAM();
                vslam.SlamObj.configure(vslam.Intrinsics, ...
                    vslam.HasIMU, ...
                    vslam.IMUParameters, ...
                    vslam.GravityDirection, ...
                    vslam.ScaleFactor,...
                    vslam.NumLevels,...
                    vslam.MaxNumPoints, ...
                    vslam.TrackFeatureRange,...
                    vslam.SkipMaxFrames, ...
                    vslam.DepthScaleFactor, ...
                    vslam.DepthRange, ...
                    vslam.LoopClosureThreshold,...
                    vslam.Verbose,...
                    vslam.VocabFilePath,...
                    vslam.ThreadLevel, ...
                    vslam.CameraToIMUTransform, ...
                    vslam.NumPosesThreshold, ...
                    vslam.AlignmentFraction, ...
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
                vslam.SlamObj = vision.internal.buildable.RGBDVisualSLAMBuildable( ...
                    vslam, ...
                    [vslam.VocabFilePath char(0)]);
            end

            % In Simulation only, print log file name with a clickable link to open it
            printLogFileOnCMD(vslam);
        end

        function addFrame(vslam, colorImage, depthImage, imuGyro, imuAccel)
            arguments
                vslam 
                colorImage 
                depthImage 
                imuGyro =[]
                imuAccel=[]
            end
            nargoutchk(0, 0);

            Iu8_color = im2uint8(colorImage);
            Iu8_gray  = im2gray(Iu8_color);

            validateattributes(Iu8_gray, {'numeric'}, ...
                {'nonsparse', 'size', vslam.Intrinsics.ImageSize}, 'rgbdvslam', 'colorImage');

            validateattributes(depthImage, {'numeric'}, ...
                {'nonsparse', 'size', vslam.Intrinsics.ImageSize}, 'rgbdvslam', 'depthImage');

            if vslam.HasIMU && ~isempty(vslam.IMUParameters)
                camPoses = poses(vslam);
                numPoses = numel(camPoses);

                if nargin>3

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
                        coder.internal.warning('vision:vslam_utils:noIMUData');
                    end

                else

                    % Throw warning when IMU is unavailable
                    if numPoses > 1
                        coder.internal.warning('vision:vslam_utils:noIMUData');
                    end

                end
            else % No IMU

                if nargin>3
                    coder.internal.error('vision:vslam_utils:InvalidIMUParams');
                end

            end
			
            addFrame(vslam.SlamObj, Iu8_gray, single(depthImage), imuGyro, imuAccel);
        end
    end

    methods (Static, Hidden)
        function this = loadobj(that)
            if that.Version == 1.0
                this = rgbdvslam(that.Intrinsics, that.DepthScaleFactor,...
                    ScaleFactor          = that.ScaleFactor, ...
                    NumLevels            = that.NumLevels, ...
                    MaxNumPoints         = that.MaxNumPoints, ...
                    SkipMaxFrames        = that.SkipMaxFrames, ...
                    DepthRange           = that.DepthRange, ...
                    TrackFeatureRange    = that.TrackFeatureRange, ...
                    LoopClosureThreshold = that.LoopClosureThreshold, ...
                    Verbose              = that.Verbose,...
                    ThreadLevel          = that.ThreadLevel);
            else
                this = rgbdvslam(that.Intrinsics, that.DepthScaleFactor,...
                    that.IMUParameters, ...
                    CameraToIMUTransform = that.CameraToIMUTransform, ...
                    ScaleFactor          = that.ScaleFactor, ...
                    NumLevels            = that.NumLevels, ...
                    MaxNumPoints         = that.MaxNumPoints, ...
                    SkipMaxFrames        = that.SkipMaxFrames, ...
                    DepthRange           = that.DepthRange, ...
                    TrackFeatureRange    = that.TrackFeatureRange, ...
                    LoopClosureThreshold = that.LoopClosureThreshold, ...
                    Verbose              = that.Verbose,...
                    ThreadLevel          = that.ThreadLevel,...
                    NumPosesThreshold    = that.NumPosesThreshold, ...
					AlignmentFraction    = that.AlignmentFraction);
            end
        end
    end

    methods (Hidden)
        function that = saveobj(this)
            that = saveobj@vision.internal.vslam.BaseVisualSLAM(this);

            that.DepthScaleFactor     = this.DepthScaleFactor;
            that.DepthRange           = this.DepthRange;
        end
    end

    methods(Access=protected)
        function group = getPropertyGroups(this)
            group = getPropertyGroups@vision.internal.vslam.BaseVisualSLAM(this);
            group(1).PropertyList = [group(1).PropertyList,"DepthScaleFactor","DepthRange"];
        end
    end
end

function mustBeMonotonicallyIncreasingDepth(x)
validateattributes(x(1), {'numeric'}, {'scalar'}, mfilename, 'DepthRange(1)');
validateattributes(x(2), {'numeric'}, {'scalar', '>', x(1)},  mfilename, 'DepthRange(2)');
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
