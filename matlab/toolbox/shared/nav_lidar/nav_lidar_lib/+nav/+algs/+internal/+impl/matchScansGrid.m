function [relPose, score, covariance] = matchScansGrid(currentScan, referenceScan, ...
                                                      initialPoseAvailable, initialPose, maxRange, resolution, ...
                                                      linSearchRange, angSearchRange, maxLevel, computeCov)
    %This function is for internal use only. It may be removed in the future.

    %MATCHSCANSGRID Match two lidar scans using grid-based search
    %   This function is MEX'ed for MATLAB execution.

    %   Copyright 2017-2020 The MathWorks, Inc.

    %#codegen

    matcher = nav.algs.internal.CorrelativeScanMatcher(referenceScan, maxRange, resolution, maxLevel, linSearchRange, angSearchRange);
    matcher.ComputeCovariance = computeCov;

    if initialPoseAvailable
        [relPose, score, covariance] = matcher.match(currentScan, initialPose);
    else
        [relPose, score, covariance] = matcher.match(currentScan);
    end


end
