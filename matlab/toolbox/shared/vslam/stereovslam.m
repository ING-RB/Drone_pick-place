classdef stereovslam < vision.internal.vslam.BaseVisualSLAM

% Copyright 2023-2024 The MathWorks, Inc.

%#codegen
    properties (SetAccess=private, GetAccess=public)
        Baseline

        DisparityRange

        UniquenessThreshold
    end

    properties (Hidden, Access = protected)
        SlamObj

        Version = 2.0
    end

    methods (Access = public)
        function vslam = stereovslam(input1, input2, imuParameters, stereoArgs, baseArgs)
            arguments
                input1 {mustBeNonempty,mustBeIntrinsicsOrReprojection}
                input2 {mustBeNumeric,mustBeFinite,mustBeNonsparse,mustBeReal}
                imuParameters = []
                stereoArgs.DisparityRange (1, 2) {mustBeInteger,mustBeNonsparse,mustBeFinite,mustBeMonotonicallyIncreasingDisparityRange,mustBeDivisibleBy16}=[0 48]
                stereoArgs.UniquenessThreshold (1, 1) {mustBeInteger,mustBePositive,mustBeNonsparse,mustBeFinite}=15
                baseArgs.ScaleFactor
                baseArgs.NumLevels
                baseArgs.MaxNumPoints
                baseArgs.TrackFeatureRange
                baseArgs.SkipMaxFrames
                baseArgs.LoopClosureThreshold
                baseArgs.Verbose
                baseArgs.CustomBagOfFeatures
                baseArgs.ThreadLevel
                baseArgs.MaxReprojectionErrorPnP
                baseArgs.MinParallax
                baseArgs.MaxReprojectionErrorBA
                baseArgs.MaxNumIterationsBA
                baseArgs.MinPGOInterval
                baseArgs.MinNumMatches   
                baseArgs.CameraToIMUTransform
                baseArgs.NumPosesThreshold
                baseArgs.AlignmentFraction
                baseArgs.MaxAlignmentError
                baseArgs.FixPoses = true
                baseArgs.InitialVelocity = [0 0 0]
                baseArgs.ScaleThreshold = 1e-3
                baseArgs.PredictionThreshold = [5e-2 5e-2]
            end
            
            vslamshs;

            [intrinsics, baseline] = validateRequiredInputs(input1, input2);
            mustBeSmallerThanImageWidth(stereoArgs.DisparityRange, intrinsics.ImageSize(2));

            baseArgsCell = namedargs2cell(baseArgs);
            vslam = vslam@vision.internal.vslam.BaseVisualSLAM(intrinsics, imuParameters, baseArgsCell{:});

            % Assign inputs to vslam object properties
            vslam.Baseline            = baseline;
            vslam.DisparityRange      = stereoArgs.DisparityRange;
            vslam.UniquenessThreshold = stereoArgs.UniquenessThreshold;
            vslam.MaxNumIterationsBA  = 10;

            coder.extrinsic('matlabroot');
            coder.extrinsic('fullfile');

            if coder.target('MATLAB')
                vslam.SlamObj = vision.internal.StereoVisualSLAM();
                vslam.SlamObj.configure(vslam.Intrinsics, ...
                    vslam.Baseline, ...
                    vslam.HasIMU, ...
                    vslam.IMUParameters, ...
                    vslam.GravityDirection, ...
                    vslam.CameraToIMUTransform, ...
                    vslam.ScaleFactor, ...
                    vslam.NumLevels, ...
                    vslam.MaxNumPoints, ...
                    vslam.TrackFeatureRange, ...
                    vslam.SkipMaxFrames, ...
                    vslam.DisparityRange, ...
                    vslam.UniquenessThreshold, ...
                    vslam.LoopClosureThreshold, ...
                    vslam.Verbose, ...
                    vslam.VocabFilePath, ...
                    vslam.ThreadLevel, ...
                    vslam.MaxReprojectionErrorPnP, ...
                    vslam.MinParallaxCosine, ...
                    vslam.MaxReprojectionErrorBA, ...
                    vslam.MaxNumIterationsBA, ...
                    vslam.MinPGOInterval, ...
                    vslam.MinNumMatches, ...
                    vslam.NumPosesThreshold, ...
                    vslam.AlignmentFraction, ...
                    vslam.FixPoses, ...
                    vslam.InitialVelocity, ... 
                    vslam.ScaleThreshold, ... 
                    vslam.PredictionThreshold);
            else
                vslam.SlamObj = vision.internal.buildable.StereoVisualSLAMBuildable( ...
                    vslam, ...
                    [vslam.VocabFilePath char(0)]);
            end
            
            % In Simulation only, print log file name with a clickable link to open it
            printLogFileOnCMD(vslam);
        end

        function addFrame(vslam, I1, I2, imuGyro, imuAccel, args)
            arguments
                vslam
                I1
                I2
                imuGyro = [];
                imuAccel = [];
                args.DisparityMap = [];
            end

            validateattributes(I1, {'numeric'}, ...
                {'real','nonsparse','nonempty'}, mfilename, 'I1');
            validateattributes(I2, {'numeric'}, ...
                {'real','nonsparse','nonempty'}, mfilename, 'I2');

            I1u8_color = im2uint8(I1);
            I2u8_color = im2uint8(I2);

            I1u8_gray  = im2gray(I1u8_color);
            I2u8_gray  = im2gray(I2u8_color);

            validateattributes(I1u8_gray, {'numeric'}, ...
                {'nonsparse', 'size', vslam.Intrinsics.ImageSize}, mfilename, 'I1');
            validateattributes(I2u8_gray, {'numeric'}, ...
                {'nonsparse', 'size', vslam.Intrinsics.ImageSize}, mfilename, 'I2');

            if ~isempty(args.DisparityMap)
                validateattributes(args.DisparityMap, {'single','double'}, ...
                    {'real', 'nonsparse', 'size', vslam.Intrinsics.ImageSize}, mfilename, 'Disparity');
            end

            if vslam.HasIMU && ~isempty(vslam.IMUParameters)

                camPoses = poses(vslam);
		        numPoses = length(camPoses);

                if nargin>4

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

                else

                    % Throw warning when IMU is unavailable
                    if numPoses > 1
                        coder.internal.warning('vision:vslam_utils:noIMUData');
                    end

                end
            else % No IMU

                if nargin>4 || numel(imuGyro)~=numel(imuAccel)
				    coder.internal.error('vision:vslam_utils:InvalidIMUParams');
                end

            end

            addFrame(vslam.SlamObj, I1u8_gray, I2u8_gray, imuGyro, imuAccel, single(args.DisparityMap));
        end
    end

    methods (Access = private)

        function shs(~)
            if isempty(coder.target)
                try
                    vslam.internal.shs();
                catch ME
                    throwAsCaller(ME)
                end
            end
        end
        
    end

    methods (Static, Hidden)
        function this = loadobj(that)
            if that.Version == 1.0
                this = stereovslam(that.Intrinsics, that.Baseline,...
                    ScaleFactor          = that.ScaleFactor, ...
                    NumLevels            = that.NumLevels, ...
                    MaxNumPoints         = that.MaxNumPoints, ...
                    DisparityRange       = that.DisparityRange, ...
                    UniquenessThreshold  = that.UniquenessThreshold, ...
                    SkipMaxFrames        = that.SkipMaxFrames, ...
                    TrackFeatureRange    = that.TrackFeatureRange, ...
                    LoopClosureThreshold = that.LoopClosureThreshold, ...
                    Verbose              = that.Verbose, ...
                    ThreadLevel          = that.ThreadLevel);
            else
                this = stereovslam(that.Intrinsics, that.Baseline,...
                    that.IMUParameters, ...
                    CameraToIMUTransform = that.CameraToIMUTransform, ...
                    ScaleFactor          = that.ScaleFactor, ...
                    NumLevels            = that.NumLevels, ...
                    MaxNumPoints         = that.MaxNumPoints, ...
                    DisparityRange       = that.DisparityRange, ...
                    UniquenessThreshold  = that.UniquenessThreshold, ...
                    SkipMaxFrames        = that.SkipMaxFrames, ...
                    TrackFeatureRange    = that.TrackFeatureRange, ...
                    LoopClosureThreshold = that.LoopClosureThreshold, ...
                    Verbose              = that.Verbose, ...
                    ThreadLevel          = that.ThreadLevel);
            end
        end
    end

    methods (Hidden)
        function that = saveobj(this)
            that = saveobj@vision.internal.vslam.BaseVisualSLAM(this);

            that.DisparityRange       = this.DisparityRange;
            that.UniquenessThreshold  = this.UniquenessThreshold;
        end

        function flag = isMapInitialized(vslam)
            flag = isInitialized(vslam.SlamObj);
        end

        function numPoints=getNumTrackedPoints(vslam)
            numPoints = getNumTrackedPoints(vslam.SlamObj);
        end
    end

    methods(Access=protected)
        function group = getPropertyGroups(this)
            group = getPropertyGroups@vision.internal.vslam.BaseVisualSLAM(this);
            group(1).PropertyList = [group(1).PropertyList,"Baseline","DisparityRange","UniquenessThreshold"];
        end
    end
end

function mustBeMonotonicallyIncreasingDisparityRange(x)
validateattributes(x(1), {'numeric'}, {'scalar'}, mfilename, "DisparityRange(1)");
validateattributes(x(2), {'numeric'}, {'scalar', '>', x(1)},  mfilename, "DisparityRange(2)");
end

function mustBeDivisibleBy16(x)
rem = mod(x(2)-x(1), 16);
coder.internal.errorIf(rem ~= 0, "vision:vslam_utils:InvalidDisparityRange");
end

function mustBeIntrinsicsOrReprojection(input1)
if isa(input1, "cameraIntrinsics")
    validateattributes(input1,{'cameraIntrinsics'},{'scalar'},mfilename,'intrinsics',1);
else
    % Error if input 1 is not a cameraIntrinsics object or a 4-by-4 numeric
    % matrix
    coder.internal.errorIf(~isnumeric(input1) || ~ismatrix(input1) || ~all(size(input1) == 4), ...
            "vision:vslam_utils:MustBeIntrinsicsOrReprojectionMatrix");

    validateattributes(input1,{'numeric'}, ...
        {'size',[4 4],'nonsparse','finite','nonnan','real'}, ...
        mfilename, 'reprojectionMatrix',1);
end
end

function [intrinsics, baseline] = validateRequiredInputs(input1, input2)
if isa(input1, "cameraIntrinsics")
    intrinsics = input1;

    validateattributes(input2,{'numeric'},...
        {'scalar','nonsparse','finite','nonnan','nonzero'},mfilename, ...
        'baseline', 2)
    baseline = input2;
else
    % Validate inputs to cameraIntrinsics constructor
    focalLength = [input1(3,4); input1(3,4)];
    validateattributes(focalLength, {'double', 'single'}, ...
        {'real', 'nonsparse', 'finite', 'positive'}, ...
        mfilename, 'reprojectionMatrix(3,4)');

    validateattributes(input1(1:2,4), {'double', 'single'},...
        {'real', 'nonsparse', 'finite', '<', 0}, ...
        mfilename,'reprojectionMatrix(1:2,4)');
    principalPoint = -[input1(1:2,4)];

    validateattributes(input2, {'double', 'single'},...
        {'real', 'nonsparse','numel', 2, 'integer', 'positive'}, ...
        mfilename, 'imageSize',2);

    if min(input2) < 63
        coder.internal.error('vision:detectORBFeatures:invalidImageSize');
    end

    % Create cameraIntrinsics
    intrinsics = cameraIntrinsics(focalLength, principalPoint, input2);

    % Validate and compute baseline
    validateattributes(input1(4,3),{'double', 'single'},{'nonzero'},...
        mfilename, 'reprojectionMatrix(4,3)');
    baseline = 1/input1(4,3);
end
end

function mustBeSmallerThanImageWidth(disparityRange, imageWidth)
coder.internal.errorIf(any(abs(disparityRange) >= imageWidth), "vision:vslam_utils:MustBeSmallerThanImageWidth", imageWidth);
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
