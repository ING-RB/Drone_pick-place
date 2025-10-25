function [pose, negScore, hessian, exitFlag, iters] = matchScans(referenceScan, currentScan, initialPose, cellSize, maxIterations, scoreTolerance)
%This function is for internal use only. It may be removed in the future.

%MATCHSCANS Match two laser scans using in-house NLP solver (impl). This
%   function is MEX'ed for MATLAB execution.

%   Copyright 2016-2020 The MathWorks, Inc.

%#codegen

% Remove NaN ranges and convert to Cartesian coordinates
    referenceScanCart = nav.algs.internal.readCartesian(referenceScan);
    currentScanCart = nav.algs.internal.readCartesian(currentScan);

    % Create the grids of cells and calculate corresponding means and covariances
    % (using NDT algorithm)
    [xgridcoords, ygridcoords, meanq, covar, covarInv] = nav.algs.internal.buildNDT( ...
        referenceScanCart, cellSize);

    % Set up solver and solve
    solver = robotics.core.internal.TrustRegionIndefiniteDogLeg();
    params = solver.getSolverParams();
    params.MaxNumIteration = maxIterations;
    params.RandomRestart = false;
    params.FunctionTolerance = scoreTolerance;
    params.GradientTolerance = 1e-6;
    solver.setSolverParams(params);

    args = struct;
    args.currentScan = currentScanCart;
    args.xgridcoords = xgridcoords;
    args.ygridcoords = ygridcoords;
    args.meanq = meanq;
    args.covar = covar;
    args.covarInv = covarInv;
    solver.ExtraArgs = args;

    solver.CostFcn = @nav.algs.internal.objectiveNDT;
    [pose, solutionInfo] = solver.solve(initialPose);
    negScore = solutionInfo.Error;

    [~, ~, hessian] = nav.algs.internal.objectiveNDT(pose, args);
    exitFlag = solutionInfo.ExitFlag;
    iters = solutionInfo.Iterations;

end
