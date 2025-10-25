function [relPose, stat, debugInfo] = matchScansLine(scanCurr, scanRef, relPoseInitial, varargin)
%matchScansLine Estimate pose between two laser scans using line features
%   RELPOSE = MATCHSCANSLINE(SCANCURR, SCANREF, RELPOSEINITIAL)
%   estimates the relative pose between SCANCURR and SCANREF based on
%   matched line features identified in each of the scans. matchScansLine
%   requires a good initial guess of the relative pose to function properly.
%   RELPOSEINITIAL is commonly given by an IMU/odometry sensor reading.
%   The underlying algorithm works best with lidar scans acquired from
%   indoor environment where straight line features are abundant in various
%   directions.
%
%   [RELPOSE, STAT] = MATCHSCANSLINE(SCANCURR, SCANREF, RELPOSEINITIAL)
%   returns additional information about the scan matching result in STAT.
%   STAT is returned as a struct with the following fields:
%
%   Covariance - 3-by-3 matrix representing the covariance of the RELPOSE
%      solution. Note that matchScansLine does not provide covariance
%      estimation between (x, y) components and theta component. The
%      covariance always follows this pattern:
%      [ cxx, cxy,   0,
%        cyx, cyy,   0,
%          0,   0, cthth]
%
%   ExitFlag - A non-zero value indicates issues in the scan matching process.
%       0 - No error
%       1 - Insufficient number of line features (< 2) are found in one or
%           both scans. The area scanned may lack hard edges.
%       2 - Insufficient number of line feature matches (< 2) are
%           identified. This may indicate the initial guess is bad or the
%           two scans look very different.
%
%   [RELPOSE, STAT, DEBUGINFO] = MATCHSCANSLINE(SCANCURR, SCANREF, RELPOSEINITIAL)
%   provides further information to help debug the line-based scan matching
%   result. DEBUGINFO is a struct with the following fields:
%      ReferenceFeatures   - line features extracted from the reference scan
%                            as an N x 2 matrix. Each line features is
%                            represented by two parameters, [rho, alpha].
%      ReferenceScanMask   - An N x SCANREF.Count binary matrix. The ith
%                            row of ReferenceScanMask indicates which scan
%                            points in SCANREF are used to estimate the ith
%                            reference line feature.
%      CurrentFeatures     - line features extracted from the current scan
%                            as an M x 2 matrix.
%      CurrentScanMask     - An M x currScan.Count binary matrix. The jth
%                            row of CurrentScanMask indicates which scan
%                            point in SCANREF are used to estimate the jth
%                            current line feature.
%      MatchHypothesis     - Best Line feature matching hypothesis. It is
%                            given as a 1 x M vector, where M is the
%                            number of line features in current scan.
%                            If MatchHypothesis(p) is equal to q, it means
%                            that pth line feature in current scan is
%                            matched to qth line feature in the reference
%                            scan. If MatchHypothesis(p) is zero, it means
%                            pth line feature in the current scan has no
%                            match.
%      MatchValue          - When two MatchHypotheses have the same number
%                            of unique non-zero entries, the one with smaller
%                            MatchValue is considered a better match
%
%
%   ___ = MATCHSCANSLINE(___, Name, Value) provides additional options
%   specified by one or more Name,Value pair arguments. Name must appear
%   inside single or double quotes ('' or ""). You can specify several
%   name-value pair arguments in any order as Name1, Value1, ...,
%   NameN, ValueN:
%
%   1) Line feature related properties:
%
%   'SmoothnessThreshold' - Threshold to detect line break points in scan
%      Smoothness is defined through the double-differenced range data,
%      assuming lidar scan angles are equally spaced. Scan points corresponding
%      to smoothness values higher than this threshold are considered break
%      points. For lidar scan data with a higher noise level, increase
%      this threshold accordingly.
%      Default: 0.1
%
%   'MinPointsPerLine' - Minimal number of scan points in each line
%      A line feature cannot be identified from a set of scan points if the
%      number of points in that set is below this threshold. When the lidar
%      scan data is noisy, setting this property too small may result in
%      low-quality line features being identified and skew the matching
%      result. On the other hand, some key line features may be missed if
%      this number is set too large.
%      Default: 10 (must be greater than 3)
%
%   'LineMergeThreshold' - Threshold on line parameters to determine merging
%      A line is defined by two parameters: 1) rho, the distance from the
%      origin to the line along a vector perpendicular to the line, and 2)
%      alpha, the angle between the x-axis and the aforementioned vector.
%      MergeTolerance is a 2-vector ([rhoTol, alphaTol]). If the absolute
%      difference between two sets of line parameters are less than this
%      threshold, they may be merged into a single line feature.
%      Default: [0.05 (m), 0.1 (rad)]
%
%   'MinCornerProminence' - Prominence lower bound for a corner to be detected
%      Prominence measures how much a local extrema stands out. Only local
%      extrema in the scan range data with prominence values higher than
%      this lower bound can be identified as a corner. Noisy lidar scan
%      needs higher corner prominence bound to filter out false corner points.
%      Note that here corners are only used to better identify line features,
%      but not considered as features themselves.
%      Default: 0.05 (m)
%
%   2) Feature association related properties:
%
%   Feature association is the process of finding matches between the
%   reference line features and the current line features. For M reference
%   line features and N current line features, there are N^(M+1) possible
%   pairings (including no matches). To reduce the complexity, a
%   branch-and-bound search algorithm is used and two types of
%   "compatibility tests" are implemented so that any matching hypotheses
%   that exceeds the test thresholds are efficiently thrown away.
%
%   'CompatibilityScale' - Scale used to adjust the compatibility test
%      thresholds for feature association. Lower scale means tighter
%      compatibility test thresholds, i.e. feature association is less
%      likely to return spurius feature pairings, but at the same time, a
%      match may not be found at all. For tuning of this property, assuming
%      sufficient line features have been extracted from each scan, it is
%      suggested to start with a CompatibilityScale close to the default
%      value. If no match is found, increase the scale accordingly. If
%      a bad match is returned, decrease the scale accordingly. The scale
%      must be a positive number.
%      Default: 0.0005
%
%
%   Example:
%      % Create a sample laser scan pair
%      refRanges = 5 * ones(1, 300);
%      refAngles = linspace(-pi/2, pi/2, 300);
%      refScan = lidarScan(refRanges, refAngles);
%      currentScan = transformScan(refScan, [0.5, 0.2, 0]);
%
%      % Estimate relative pose between the two scans with initial guess
%      relPose = matchScansLine(currentScan, refScan, [-0.4 -0.1 0])
%
%
%   References:
%
%   [1] J. Neira and J. Tardos, "Data association in stochastic mapping
%       using the joint compatibility test", IEEE transcactions on Robotics
%       and Automation, 17(6): 890 - 897, 2001
%   [2] X. Shen, E. Frazzoli, D. Rus, and M. Ang, "Fast joint compatibility
%       branch and bound for feature cloud matching", in proceedings of
%       IEEE International Conference on Intelligent Robots and Systems
%       (IROS), 2016, pp. 1757 - 1764
%
%   See also lidarScan, transformScan, matchScans, matchScansGrid.

%   Copyright 2019-2020 The MathWorks, Inc.

%#codegen

    narginchk(3, inf);

    fcnName = 'matchScansLine';
    validateattributes(scanCurr, {'lidarScan'}, {'nonempty', 'scalar'}, fcnName, 'scanCurr');
    validateattributes(scanRef, {'lidarScan'}, {'nonempty', 'scalar'}, fcnName, 'scanRef');
    relPoseIni = robotics.internal.validation.validateMobilePose(relPoseInitial, fcnName, 'relPose');

    defaults = struct('CompatibilityScale', 0.0005, ...
                      'SmoothnessThreshold', 0.1, ...
                      'MinPointsPerLine', 10, ...
                      'MinCornerProminence', 0.05, ...
                      'LineMergeThreshold', [0.05, 0.1]);

    names = {'CompatibilityScale', 'SmoothnessThreshold', 'MinPointsPerLine', 'MinCornerProminence', 'LineMergeThreshold'};
    defaultValues = {defaults.CompatibilityScale, defaults.SmoothnessThreshold, ...
                     defaults.MinPointsPerLine, defaults.MinCornerProminence, ...
                     defaults.LineMergeThreshold};

    % parse name-value pairs
    parser = robotics.core.internal.NameValueParser(names, defaultValues);
    parse(parser, varargin{:});

    compScale = robotics.internal.validation.validatePositiveNumericScalar(...
        parameterValue(parser, 'CompatibilityScale'), fcnName, 'CompatibilityScale');
    doubleDiffThresh = robotics.internal.validation.validatePositiveNumericScalar(...
        parameterValue(parser, 'SmoothnessThreshold'), fcnName, 'SmoothnessThreshold');
    minNumPts = parameterValue(parser, 'MinPointsPerLine');
    validateattributes(minNumPts, {'numeric'}, {'nonempty', 'scalar', 'integer', 'real',  'nonnan', '>', ...
                        nav.algs.internal.LineFeatureFinder.MinNumPoints}, fcnName, 'MinPointsPerLine');
    minNumScanPtsPerLine = double(minNumPts);
    minCornerProminence = robotics.internal.validation.validatePositiveNumericScalar(...
        parameterValue(parser, 'MinCornerProminence'), fcnName, 'MinCornerProminence');
    mergeThreshold = parameterValue(parser, 'LineMergeThreshold');
    validateattributes( mergeThreshold, {'numeric'}, {'nonempty', 'vector', 'numel', 2, 'real', 'nonnan', 'finite', 'positive'}, ...
                        fcnName, 'LineMergeThreshold');
    mergeTolerance = double(mergeThreshold);

    % extract raw line features
    lf = nav.algs.internal.LineFeatureFinder();
    lf.DoubleDiffThreshold = doubleDiffThresh;
    lf.MinNumPointsPerSegment = minNumScanPtsPerLine;
    lf.MinCornerProminence = minCornerProminence;
    lf.MergeTolerance = mergeTolerance;

    [lineFeaturesRef_, scanSegsRef_, ] = lf.extractLineFeatures(scanRef);
    [lineFeaturesCurr_, scanSegsCurr_] = lf.extractLineFeatures(scanCurr);

    % merge line features
    [lineFeaturesRef, scanSegMasksRef] = lf.mergeLineFeatures(lineFeaturesRef_, scanSegsRef_, scanRef);
    [lineFeaturesCurr, scanSegMasksCurr] = lf.mergeLineFeatures(lineFeaturesCurr_, scanSegsCurr_, scanCurr);


    % preset covariances
    distCoef = 20;
    angCoef = 10;
    nRef = size(lineFeaturesRef,1);
    lineFeatureCompactCovariancesRef = [distCoef*ones(nRef, 1), angCoef*ones(nRef, 1)];
    nCurr = size(lineFeaturesCurr,1);
    lineFeatureCompactCovariancesCurr = [distCoef*ones(nCurr, 1), angCoef*ones(nCurr, 1)];
    relPoseIniCov = diag([1 1 1]);

    exitFlag = 0;
    if nRef < 2 || nCurr < 2
        exitFlag = 1;
    end

    val = 0;
    if exitFlag == 0 % if enough line features are found in both scans

        [matchHypothesis, val] = nav.algs.internal.DataAssociationHelpers.modifiedFastJCBB(lineFeaturesRef, ...  % Ref
                                                          lineFeatureCompactCovariancesRef, ...
                                                          scanSegMasksRef, ...
                                                          lineFeaturesCurr, ... % Curr
                                                          lineFeatureCompactCovariancesCurr, ...
                                                          scanSegMasksCurr, ...
                                                          relPoseIni, relPoseIniCov, ... % relPose
                                                          compScale);          % compatibilityScale

        if nnz(matchHypothesis) >= 2

            % assign weights for each matched line feature pairs
            matchWeights = zeros(size(matchHypothesis));
            for k = 1:numel(matchHypothesis)
                if matchHypothesis(k) > 0
                    eNumPts = nnz(scanSegMasksCurr(k,:) );
                    fNumPts = nnz(scanSegMasksRef(matchHypothesis(k),:) );
                    matchWeights(k) = eNumPts * fNumPts;
                end
            end

            % normalize weights
            matchWeights = matchWeights/sum(matchWeights);

            % estimate covariance
            [relPose, covariance] = ...
                nav.algs.internal.DataAssociationHelpers.estimateRobotMotionAPosteriori(matchHypothesis, lineFeaturesRef, ...
                                                              lineFeaturesCurr, matchWeights);
        else
            relPose = nan(1,3);
            covariance = nan(3);
            exitFlag = 2;
        end
    else
        matchHypothesis = nan;
        relPose = nan(1,3);
        covariance = nan(3);
    end

    % second output
    stat = struct(...
        'Covariance', covariance, ...
        'ExitFlag', exitFlag);

    % third output
    debugInfo = struct(...
        'ReferenceFeatures', lineFeaturesRef, ...
        'ReferenceScanMask', scanSegMasksRef, ...
        'CurrentFeatures', lineFeaturesCurr, ...
        'CurrentScanMask', scanSegMasksCurr, ...
        'MatchHypothesis', matchHypothesis, ...
        'MatchValue', val);

end
