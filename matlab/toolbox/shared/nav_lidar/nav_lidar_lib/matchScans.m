function [pose, stats] = matchScans(varargin)
%matchScans Estimate pose between two laser scans
%   POSE = MATCHSCANS(CURRSCAN, REFSCAN) finds the relative pose, POSE, between
%   a reference laser scan, REFSCAN, and a current laser scan, CURRSCAN,
%   using Normal Distributions Transform (NDT). Scans are specified as
%   lidarScan objects.
%   The output pose has three elements, [x y theta], with the translational
%   offset [x y] (in meters) and the rotational offset [theta] (in
%   radians).
%
%   POSE = MATCHSCANS(CURRRANGES, CURRANGLES, REFRANGES, REFANGLES)
%   finds the relative pose between a reference scan specified through
%   REFRANGES and REFANGLES and a current scan specified through
%   CURRRANGES and CURRANGLES.
%
%   [POSE, STATS] = MATCHSCANS(___) returns additional statistics about the scan
%   matching result in STATS.
%   STATS is returned as a struct with the following fields:
%
%   Score - Numeric scalar representing the NDT score while performing scan
%      matching. The score is an estimate of likelihood that the transformed
%      current scan matches the reference scan.
%      Score is always non-negative and a larger score indicates a better
%      match.
%
%   Hessian - 3-by-3 matrix representing the Hessian of the NDT
%      cost function at the POSE solution. The Hessian can be used as an
%      indicator of the uncertainty associated with the pose estimate.
%
%
%   ___ = MATCHSCANS(___, Name, Value) provides additional options
%   specified by one or more Name,Value pair arguments. Name must appear
%   inside single quotes (''). You can specify several name-value pair
%   arguments in any order as Name1, Value1, ..., NameN, ValueN:
%
%   'SolverAlgorithm' - The optimization algorithm used to calculate the
%      pose estimate.
%      Possible values: {'trust-region', 'fminunc'}
%      Default: 'trust-region'
%
%   'InitialPose' -  A 3-element vector, [x y theta], representing the initial
%      guess for the relative pose between the two scans. [x y] is the translation
%      guess (in meters) and [theta] is the rotation guess (in radians).
%      The function converges faster if the initial pose is close to
%      the true pose.
%      Default: [0 0 0]
%
%   'CellSize' - Side length of a single cell (in meters). Each cell is a square
%      area used to discretize the space for the NDT algorithm.
%      The optimal cell size depends on the input scans and on the application.
%      Choosing a cell size that is too large often leads to less accurate matching.
%      Choosing too small of a cell size requires a lot of memory and the
%      scans must be close together before matching succeeds.
%      Default: 1
%
%   'MaxIterations' - Maximum number of iterations allowed for optimization.
%      A larger number of iterations might result in more accurate pose
%      estimates, but requires a longer execution time.
%      Default: 400
%
%   'ScoreTolerance' - Lower bound on the change in the score between
%      optimization steps. If the score changes by less than this number,
%      the iterations end. A smaller ScoreTolerance might result
%      in more accurate pose estimates, but requires a longer execution time.
%      Default: 1e-6
%
%
%   Example:
%       % Example laser scan data input
%       refRanges = 5 * ones(1, 300);
%       refAngles = linspace(-pi/2, pi/2, 300);
%       refScan = lidarScan(refRanges, refAngles);
%
%       % Generate second laser scan at an (x,y) offset of (0.5, 0.2)
%       currentScan = transformScan(refScan, [0.5, 0.2, 0]);
%
%       % Match scans and estimate pose
%       pose = matchScans(currentScan, refScan)
%
%       % Improve estimate by giving initial pose estimate
%       pose = matchScans(currentScan, refScan, 'InitialPose', [-0.4 -0.1 0])
%
%
%   See also transformScan, lidarScan.

%   Copyright 2016-2020 The MathWorks, Inc.
%
%   References:
%
%   [1] P. Biber, W. Strasser, "The normal distributions transform: A
%       new approach to laser scan matching," in Proceedings of IEEE/RSJ
%       International Conference on Intelligent Robots and Systems
%       (IROS), 2003, pp. 2743-2748

%#codegen

% Defaults for optional name-value pair inputs
    defaults = struct(...
        'InitialPose', [0 0 0], ...
        'CellSize', 1, ...
        'ScoreTolerance', 1e-6, ...
        'MaxIterations', 400, ...
        'SolverAlgorithm', 'trust-region');

    % Parse user-provided inputs
    parsedInputs = nav.algs.internal.parseMatchScansInput(defaults, varargin{:});

    % Check solver
    if strcmp(parsedInputs.SolverAlgorithm, 'fminunc')
        % This option requires Optimization Toolbox. Display an error if no
        % license available.
        if ~robotics.internal.license.isOptimToolboxLicensed
            nav.algs.internal.error('shared_robotics', 'license:NoOptimLicense', 'matchScans (with fminunc option)');
        end
    end


    % Optimize
    if strcmp(parsedInputs.SolverAlgorithm, 'fminunc')
        % Remove NaN ranges and convert to Cartesian coordinates
        referenceScan = double(nav.algs.internal.readCartesian(parsedInputs.ReferenceScan));
        currentScan = double(nav.algs.internal.readCartesian(parsedInputs.CurrentScan));

        % Create the grids of cells and calculate corresponding means and covariances
        % (using NDT algorithm)
        [xgridcoords, ygridcoords, meanq, covar, covarInv] = nav.algs.internal.buildNDT( ...
            referenceScan, parsedInputs.CellSize);

        if coder.target('MATLAB')
            solverParams = createSolverParameters(parsedInputs.ScoreTolerance, parsedInputs.MaxIterations);
            solverParams.Display = 'none';

            args.currentScan = currentScan;
            args.xgridcoords = xgridcoords;
            args.ygridcoords = ygridcoords;
            args.meanq = meanq;
            args.covar = covar;
            args.covarInv = covarInv;

            [pose, negScore, ~, ~, ~, hessian] = fminunc(...
                @(poseEstimate) nav.algs.internal.objectiveNDT( ...
                    poseEstimate, args ), ...
                parsedInputs.InitialPose, solverParams);
        else
            pose = [nan, nan, nan];
            negScore = 0;
            hessian = -eye(3);
            coder.internal.assert(strcmp(parsedInputs.SolverAlgorithm, 'fminunc'), 'nav:navalgs:scanmatch:NoCodegenSupportForFminunc');
        end
    else

        [ pose, negScore, hessian, ~, ~ ] = nav.algs.internal.matchScans(parsedInputs);

        % Output row vector
        pose = pose';
    end

    % Define output structure
    % Return positive score, since that is the definition in paper [1]. During
    % the optimization, the negative score is minimized.
    stats = struct(...
        'Score', -negScore, ...
        'Hessian', hessian);

end


function solverParams = createSolverParameters(scoreTolerance, maxIterations)
%createSolverParameters Create parameters for optimization algorithm

% Set default solver parameters
    solverParams = optimoptions('fminunc');
    solverParams.Algorithm = 'trust-region';
    solverParams.Display = 'none';

    % The objective function computes both the gradient and the Hessian
    solverParams.SpecifyObjectiveGradient = true;
    solverParams.HessianFcn = 'objective';

    solverParams.StepTolerance = 1e-6;
    solverParams.FunctionTolerance = scoreTolerance;
    solverParams.MaxIterations = maxIterations;

end
