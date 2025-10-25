function [score, gradient, hessian] = objectiveNDT(laserTrans, args)
%This function is for internal use only. It may be removed in the future.

%objectiveNDT Calculate objective function for NDT-based scan matching

%   Copyright 2016-2020 The MathWorks, Inc.

%#codegen

    laserScan = args.currentScan;
    xgridcoords = args.xgridcoords;
    ygridcoords = args.ygridcoords;
    meanq = args.meanq;
    covar = args.covar;
    covarInv = args.covarInv;

    if coder.target('MATLAB')
        % When running in MATLAB, use MEX file for improved performance
        [score, gradient, hessian] = nav.algs.internal.mex.objectiveNDT(...
            laserScan, laserTrans, xgridcoords, ygridcoords, meanq, covar, covarInv);
    else
        % When generating code, use MATLAB implementation
        [score, gradient, hessian] = nav.algs.internal.impl.objectiveNDT(...
            laserScan, laserTrans, xgridcoords, ygridcoords, meanq, covar, covarInv);
    end
end
