function bps = basispoints(arrangement, numBasisPoints, limits)
% This function is for internal use only. It may be removed in the future.

% basispoints Creates 2D and 3D basis point set.
%
%   bps =  basispoints(ARRANGEMENT, NUMBASISPOINTS, LIMITS) creates basis
%   point ARRANGEMENT with number of basis points NUMBASISPOINTS.
%   The LIMITS defines the bounds on the basis points.
%   ARRANGEMENT must be:
%   randball - basis points are arranged randomly in a 2D ball.
%   randball-3d - basis points are arranged randomly in a 3D ball.
%   rectgrid - basis points are arranged in a 2D rectangle grid.
%   rectgrid-3d - basis points are arranged in a 3D rectangle grid.
%   Default : 'randball-3d'
%
%   NUMBASISPOINTS is the number of basis points in ARRANGEMENT.
%   For ARRANGEMENT randball, randball-3d numBasisPoints is a scalar
%   representing the total number of basis points in the ball.
%   NUMBASISPOINTS must be a vector of [X Y], [X Y Z] for rectgrid,
%   rectgrid-3d ARRANGEMENT respectively. X,Y,Z is of integer type and
%   defines the number of basis points along x,y,z dimension.
%   Default: 64 for randball, randball-3d
%            [8 8] for rectgrid
%            [4 4 4] for rectgrid-3d
%
%   LIMITS is the bounds of the basis points. For ARRANGEMENT randball and
%   randball-3d, LIMITS represent the radius of the ball. For ARRANGEMENT
%   rectgrid and rectgrid-3d, LIMITS is a vector of [xMin xMax; yMin yMax],
%   [xMin xMax; yMin yMax; zMin zMax] respectively. Where xMin,xMix,yMin,
%   yMax,zMin,zMax represent the lower and upper bounds of dimensions x,y,z
%   respectively.
%   Default: 1 for randball and randball-3d
%            [-1 1;-1 1] for rectgrid
%            [-1 1;-1 1;-1 1] for rectgrid-3d
%
% Copyright 2023 The MathWorks, Inc.

%#codegen

    narginchk(0,3);

    % Assign default value for 'arrangement' when the function is called without
    % any argument
    if nargin < 1
        arrangement = 'randball-3d';
    end
    % Get the basis point arrangement as a struct.
    [arr, allArrangements] =  getArrangement();

    % validate that the 'arrangement' is an unambiguous, case-insensitive match
    % to any of options in 'arrangementOptions'.
    arrangement = validatestring(arrangement, allArrangements, 'basispoints');

    % Assign default value for 'numBasisPoints' when the user does not provide
    % 'numBasisPoints' argument
    if nargin < 2
        numBasisPoints = defaultNumBasisPoints(arrangement, arr);
    end

    % Assign default value for limits when the user does not provide limits
    % argument
    if nargin < 3
        limits = defaultLimits(arrangement, arr);
    end

    % validate the 'numBasisPoints' size and type in accordance with the
    % specified bps 'arrangement' option.
    validateNumPoints(arrangement, numBasisPoints, arr);

    % validate the 'limits' option size and type in accordance with the
    % specified bps 'arrangement' option.
    validateLimits(arrangement, limits, arr);

    % Retrieve basis point set dimension
    bpsDim = environmentDimension(arrangement, arr);

    % Find basis points
    switch arrangement
      case {arr.randball, arr.randball3d}
        bps = createRandball(numBasisPoints, bpsDim, limits);
      case {arr.rectgrid, arr.rectgrid3d}
        bps = createRectgrid(numBasisPoints, bpsDim, limits);
    end
end
function [arr, arrangements] =  getArrangement()
% getArrangement return a struct containing the valid arrangement options.
% Additionally it returns a cell array of arrangements.
    arrangements = {'randball', 'randball-3d', 'rectgrid', 'rectgrid-3d'};
    fields = {'randball', 'randball3d', 'rectgrid', 'rectgrid3d'};
    % For codegen, using a loop to create the structure. cell2struct is not
    % supported for codegen.
    for i=1:length(fields)
        arr.(fields{i}) = arrangements{i};
    end
end

function numBasisPoints = defaultNumBasisPoints(arrangement, arr)
% defaultNumBasisPoints Assign default value for 'numBasisPoints' when
% the user does not provide 'numBasisPoints' argument

    switch arrangement
      case {arr.randball, arr.randball3d}
        numBasisPoints = 64;
      case arr.rectgrid
        numBasisPoints = [8 8];
      case arr.rectgrid3d
        numBasisPoints = [4 4 4];
    end
end

function limits = defaultLimits(arrangement, arr)
% defaultLimits assign default value for 'limits' when
% the user does not provide 'limits' argument

    switch arrangement
      case {arr.randball, arr.randball3d}
        limits = 1;
      case arr.rectgrid
        limits = [-1 1;-1 1];
      case arr.rectgrid3d
        limits = [-1 1;-1 1;-1 1];
    end
end

function envDim = environmentDimension(arrangement, arr)
% environmentDimension return the dimension of the basis points arrangement

    envDim = 0;
    switch arrangement
      case {arr.randball, arr.rectgrid}
        envDim = 2;
      case {arr.rectgrid3d, arr.randball3d}
        envDim = 3;
    end
end

function bps = createRandball(numBasisPoints, bpsDim, normLimit)
% createRandball creates random-ball arrangement of basis points in 2D or
% 3D ball.

% For codegen, making numBasisPoints as a compile time scalar
    numBasisPoints = numBasisPoints(1);
    % To sample uniformly in a unit d-dimensional ball
    % 1. Sample numBasisPoints from uncorrelated multivariate normal distribution
    % (dimension of normal distribution corresponds to the dimension of
    % basis points). This sampled points are called Y.
    points = randn(numBasisPoints,bpsDim);
    pointsNorm = sqrt(sum(points.^2,2));
    % 2. Normalize the sampled points Y, S = Y/||Y||.
    % S will have uniform distribution on the unit d-sphere.
    normalisedPoints = points./pointsNorm;
    % 3. To get uniform distribution in d-dimensional ball, multiply
    % S with U/d. U is points sampled uniformly from unit interval (0,1).
    % d is the dimension of basis points.The result (U/d) is
    % multiplied by normLimit to scale it to the desired ball radius.

    uniformPoints = rand(numBasisPoints,1);
    u = uniformPoints.^(1/bpsDim);
    bps = normLimit.*normalisedPoints.*u;


end

function bps = createRectgrid(numBasisPoints, bpsDim, limits)
% createRectgrid creates rectgrid and rectgrid-3d arrangement.
    basisAlongX = numBasisPoints(1);
    basisAlongY = numBasisPoints(2);

    xPoints = linspace(limits(1, 1), limits(1, 2), basisAlongX);
    yPoints = linspace(limits(2, 1), limits(2, 2), basisAlongY);

    if bpsDim == 2
        [bpsx, bpsy] = meshgrid(xPoints, yPoints);
        bpsxAll = bpsx(:);
        bpsyAll = bpsy(:);
        bps = [bpsxAll, bpsyAll];
    else

        basisAlongZ = numBasisPoints(3);
        zPoints = linspace(limits(3, 1), limits(3, 2), basisAlongZ);
        [bpsx, bpsy, bpsz] = meshgrid(xPoints, yPoints, zPoints);
        bpsxAll = bpsx(:);
        bpsyAll = bpsy(:);
        bpszAll = bpsz(:);
        bps = [bpsxAll, bpsyAll bpszAll];
    end

end

function validateNumPoints(arrangement, numBasisPoints, arr)
% validateNumPoints validates that size of numBasisPoints is valid in
% accordance with arrangement

    switch arrangement
        % Set the attribute to a scalar when the arrangement is randball
        % or randball-3d
      case {arr.randball, arr.randball3d}
        attributes = {"scalar", "integer", "positive"};
        % If the arrangement is rectgrid, set the attribute to vector of size 1x2
      case arr.rectgrid
        attributes = {"size",[1 2],"integer", "positive"};
        % If the arrangement is rectgrid-3d, set the attribute to a vector of size 1x3
      case arr.rectgrid3d
        attributes = {"size",[1 3],"integer", "positive"};
    end
    % Validate that the numBasisPoints is valid in accordance with the
    % attributes of each arrangement.
    validateattributes(numBasisPoints,"numeric",attributes, 'basispoints','numBasisPoints');
end

function validateLimits(arrangement, limits, arr)
% validateLimits validates that size of limits is valid in
% accordance with arrangement

    switch arrangement
        % Set the attribute to a scalar when the arrangement is randball
        % or randball-3d
      case {arr.randball, arr.randball3d}
        attributes = {"scalar", "real", "positive"};
        % If the arrangement is rectgrid, Set the attribute a vector of size 1x2
      case arr.rectgrid
        attributes = {"size",[2 2],"real","nonnan","finite"};
        % If the arrangement is rectgrid, Set the attribute a vector of size 1x3
      case arr.rectgrid3d
        attributes = {"size",[3 2],"real","nonnan","finite"};
    end
    % Validate that the limits is valid in accordance with the
    % attributes of each arrangement.
    validateattributes(limits,"numeric", attributes, 'basispoints', 'limits');

    if strcmp(arrangement, arr.rectgrid) || strcmp(arrangement, arr.rectgrid3d)
        % Confirm that lower bounds are smaller than or equal to upper bounds
        if any(limits(:,1) > limits(:,2))
            coder.internal.error("nav:navalgs:basispoints:UpperBoundTooSmall");
        end
    end
end
