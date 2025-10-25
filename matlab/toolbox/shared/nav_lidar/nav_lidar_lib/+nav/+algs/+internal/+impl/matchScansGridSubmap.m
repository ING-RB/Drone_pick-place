function [relPose, score, covariance] = matchScansGridSubmap(currentScan, referenceSubmap, ...
                                                      initialPoseAvailable, initialPose, linSearchRange, angSearchRange)
    %This function is for internal use only. It may be removed in the future.

    %MATCHSCANSGRIDSUBMAP Match scan with an occupancy grid map
    %   This function is MEX'ed for MATLAB execution.

    %   Copyright 2017-2020 The MathWorks, Inc.

    %#codegen

    matcher = nav.algs.internal.CorrelativeScanMatcher(referenceSubmap, 0, 0, 0, linSearchRange, angSearchRange);

    if initialPoseAvailable
        [relPose, score, covariance] = matcher.match(currentScan, initialPose);
    else
        [relPose, score, covariance] = matcher.match(currentScan);
    end


end
