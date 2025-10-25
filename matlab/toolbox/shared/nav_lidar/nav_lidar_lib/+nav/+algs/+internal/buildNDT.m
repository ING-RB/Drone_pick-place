function [xgridcoords, ygridcoords, meanq, covar, covarInv] = buildNDT(laserScan, cellSize)
%This function is for internal use only. It may be removed in the future.

%buildNDT  Build Normal Distributions Transform from laser scans

%   Copyright 2016-2020 The MathWorks, Inc.

%#codegen

    if coder.target('MATLAB')
        % When running in MATLAB, use MEX file for improved performance
        [xgridcoords, ygridcoords, meanq, covar, covarInv] = nav.algs.internal.mex.buildNDT(...
            laserScan, cellSize);
    else
        % When generating code, use MATLAB implementation
        [xgridcoords, ygridcoords, meanq, covar, covarInv] = nav.algs.internal.impl.buildNDT(...
            laserScan, cellSize);
    end
end
