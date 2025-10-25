function [pose, stats] = matchScansGrid(varargin)
%matchScansGrid Estimate pose between two laser scans using grid-based approach
%   Laser scan pairs are converted into probability grids and the matching
%   pose between the two scans is found through correlation of the grids.
%   A branch and bound strategy is used to improve the computation
%   efficiency over large discretized search windows.
%
%   POSE = MATCHSCANSGRID(CURRSCAN, REFSCAN) finds the relative pose, POSE,
%   between a reference laser scan, REFSCAN, and the current laser scan,
%   CURRSCAN. Scans are specified as lidarScan objects. The output pose has
%   three elements, [x y theta], with the translational offset [x y]
%   (in meters) and the rotational offset [theta] (in radians).
%
%   [POSE, STATS] = MATCHSCANSGRID(___) returns additional statistics about
%   the scan matching result in STATS.
%   STATS is returned as a struct with the following fields:
%
%   Score - Numeric scalar representing the correlation score corresponding
%      to POSE. Score is always non-negative. The higher score, the better
%      match between the two scans. Scores from matching two different scan
%      pairs cannot be compared.
%   Covariance - Estimated covariance representing the confidence of the 
%      computed relative pose, which is a 3x3 matrix.
%
%   ___ = MATCHSCANSGRID(___, Name, Value) provides additional options
%   specified by one or more Name,Value pair arguments. Name must appear
%   inside single quotes (''). You can specify several name-value pair
%   arguments in any order as Name1, Value1, ..., NameN, ValueN:
%
%   'InitialPose' -  A 3-element vector, [x y theta], representing the initial
%      guess for the relative pose between the two scans. [x y] is the translation
%      guess (in meters) and [theta] is the rotation guess (in radians).
%      The function converges faster if the initial pose is close to
%      the true pose.
%      Default: [0 0 0]
%
%   'Resolution' - A positive integer representing grid cell per meter. The
%      scan matching result is accurate up to the grid cell size.
%      Default: 20 (0.05 m grid cell)
%
%   'MaxRange' - A positive number representing the maximum range of laser scan
%      Default: 8
%
%   'TranslationSearchRange' - A positive 2-vector representing the linear search
%      window in meters around a given initial translation estimate. If the
%      initial translation estimate is [x0, y0], and TranslationSearchRange is
%      set to l, then the search window is given by [x0 - l(1), x0 + l(1)]
%      and [y0 - l(2), y0 + l(2)]. This parameter is only used when an
%      initial guess is given for scan matching.
%      Default: [4 4]
%
%   'RotationSearchRange' - A positive scalar representing the angular
%      search window around a given initial angle estimate. If the initial
%      theta estimate is th0, and RotationSearchRange is set to a, then the
%      search window is given by [th0 - a, the0 + a]. This parameter is
%      only used when an initial guess is given for scan matching.
%      Default: pi/4
%
%   Example:
%      % Example laser scan data input
%      refRanges = [6*ones(1, 100), 7*ones(1,100), 4*ones(1,100)];
%      refAngles = linspace(-pi/2, pi/2, 300);
%      refScan = lidarScan(refRanges, refAngles);
%
%      % Generate the second laser scan by moving refScan 0.5 m in x
%      % direction and 0.2 m in y direction, then rotate the scan by 1.1
%      % radians, all in the refScan's coordinates
%      currentScan = transformScan(refScan, [0.5, 0.2, 1.1]);
%
%      % Match scans to get estimated relative pose
%      relPose = matchScansGrid(currentScan, refScan)
%
%      % To verify the relPose is correct, plot the refScan and the
%      % currentScan transformed by estimated relPose
%      refScan.plot
%      hold on
%      currentScanTformed = transformScan(currentScan, relPose)
%      currentScanTformed.plot
%
%      % Note the two plots should overlap (accurate up to the resolution
%      % specified for matchScansGrid function, by default, the resolution
%      % is 0.05m)
%
%   See also matchScans, transformScan, lidarScan.

%   Copyright 2017-2020 The MathWorks, Inc.
%
%   References:
%
%   [1] W. Hess, D. Kohler, H. Rapp, D. Andor, "Real-Time Loop Closure in
%       2D LIDAR SLAM", in Proceedings of IEEE International Conference on
%       Robotics and Automation (ICRA), 2016, pp. 1271 - 1278
%   [2] E. Olson, "Real-time Correlative Scan Matching", in proceedings of
%       IEEE International Conference on Robotics and Automation (ICRA),
%       2009, pp. 4387 - 4393

%#codegen

    currentScan = robotics.internal.validation.validateLidarScan(varargin{1}, 'matchScansGrid', 'currScan');
    referenceScan = robotics.internal.validation.validateLidarScan(varargin{2}, 'matchScansGrid', 'refScan');

    coder.internal.errorIf( (currentScan.Count > lidarScan.MaxCount || referenceScan.Count > lidarScan.MaxCount), ...
                            'nav:navalgs:scanmatch:TooManyScanRays', lidarScan.MaxCount);

    defaults = struct('InitialPose', [], ...
                      'Resolution', 20, ...
                      'MaxRange', 8, ...
                      'TranslationSearchRange', [4 4], ...
                      'RotationSearchRange', pi/4);

    names = {'InitialPose', 'Resolution', 'MaxRange', 'TranslationSearchRange', 'RotationSearchRange'};
    defaultValues = {defaults.InitialPose, defaults.Resolution, defaults.MaxRange, defaults.TranslationSearchRange, defaults.RotationSearchRange};

    % parse name-value pairs
    parser = robotics.core.internal.NameValueParser(names, defaultValues);
    parse(parser, varargin{3:end});

    initialPose = parameterValue(parser, 'InitialPose');
    maxRange = parameterValue(parser, 'MaxRange');
    resolution = parameterValue(parser, 'Resolution');
    trSearchRange = parameterValue(parser, 'TranslationSearchRange');
    rotSearchRange = parameterValue(parser, 'RotationSearchRange');

    maxRange = robotics.internal.validation.validatePositiveNumericScalar(maxRange, 'matchScansGrid', 'MaxRange');
    resolution = robotics.internal.validation.validatePositiveIntegerScalar(resolution, 'matchScansGrid', 'Resolution');

    validateattributes(trSearchRange, {'numeric'}, {'nonempty', 'real', ...
                        'nonnan', 'finite', 'vector', 'positive', 'numel', 2}, 'matchScansGrid', 'TranslationSearchRange');
    trSearchRange = double(trSearchRange(:)');

    rotSearchRange = robotics.internal.validation.validatePositiveNumericScalar(rotSearchRange, 'matchScansGrid', 'RotationSearchRange');
    maxLevel = 5;

    trSearchRange = min(trSearchRange, maxRange);
    rotSearchRange = min(rotSearchRange, pi);

    if isempty(initialPose)
        initialPoseAvailable = 0;
        initialPose = zeros(3,1);
    else
        initialPose = robotics.internal.validation.validateMobilePose(initialPose, 'matchScansGrid', 'InitialPose');
        % Available initial pose is only considered when it's within
        % [-2*maxRange,-2*maxRange] and [2*maxRange, 2*maxRange] XY Limits.
        % Beyond these limits the overlap between reference and current
        % scan becomes very low. Low overlap is not expected to result in
        % good scan allignment. 
        if any((initialPose(1:2)> 2*maxRange) | ((initialPose(1:2)< -2*maxRange)))
            initialPoseAvailable = 0;
        else
            initialPoseAvailable = 1;
        end
    end

    % either scan must have at least one valid data point
    currentScanTemp = currentScan.removeInvalidData('RangeLimits', [1/resolution, maxRange]);
    referenceScanTemp = referenceScan.removeInvalidData('RangeLimits', [1/resolution, maxRange]);
    if currentScanTemp.Count * referenceScanTemp.Count == 0
        pose = [0 0 0];
        stats = createStatsStruct(0, zeros(3));
        return
    end

    computeCov = false;
    if nargout > 1
        computeCov = true; % only computing the covariance if requested at output
    end
    [pose, score, covariance] = nav.algs.internal.matchScansGrid(currentScan, referenceScan, ...
                                                     initialPoseAvailable, initialPose, maxRange, resolution,...
                                                     trSearchRange, rotSearchRange, maxLevel, computeCov);

    if nargout > 1
        stats = createStatsStruct(score, covariance);
    end
end

function stats = createStatsStruct(score, cov)
    stats = struct(...
        'Score', score, ...
        'Covariance', cov);
end
