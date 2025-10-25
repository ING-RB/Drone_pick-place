function [relPose, score, covariance] = matchScansGridSubmap(currentScan, referenceSubmap, ...
                                                      initialPoseAvailable, ...
                                                      initialPose, linSearchRange, angSearchRange)
    %This function is for internal use only. It may be removed in the future.

    %matchScansGridSubmp Match a scan with a submap

    %   Copyright 2017-2018 The MathWorks, Inc.

    %#codegen

    if coder.target('MATLAB')
        % When running in MATLAB, use MEX file for improved performance
        [relPose, score, covariance] = nav.algs.internal.mex.matchScansGridSubmap(currentScan, referenceSubmap, ...
                                                          initialPoseAvailable, initialPose(:), linSearchRange, angSearchRange);
    else
        % When generating code, use MATLAB implementation
        [relPose, score, covariance] = nav.algs.internal.impl.matchScansGridSubmap(currentScan, referenceSubmap, ...
                                                          initialPoseAvailable, initialPose(:), linSearchRange, angSearchRange);
    end

end
