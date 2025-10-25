function bps = basispoints(arrangement, encodingSize, center, arrangementSize)
% This function is for internal use only. It may be removed in the future.

% basispoints Creates 2D and 3D basis point set.
%
%   bps =  basispoints(ARRANGEMENT, encodingSize, CENTER, arrangementSize)
%   creates basis point ARRANGEMENT with number of basis points in encodingSize.
%   The CENTER define the center of the basis point set arrangement.
%   The arrangementSize defines the bounds on the basis points.
%
%   ARRANGEMENT must be:
%   uniform-ball - basis points are sampled uniformly in a 2D ball.
%   uniform-ball-3d - basis points are sampled uniformly in a 3D ball.
%   rectangular-grid - basis points are sampled in a 2D rectangle grid.
%   rectangular-grid-3d - basis points are sampled in a 3D rectangle grid.
%   Default : 'uniform-ball-3d'
%
%   encodingSize is the number of basis points in a specific ARRANGEMENT.
%   For ARRANGEMENT uniform-ball, uniformball-3d encodingSize is a scalar
%   representing the total number of basis points in the ball.
%   encodingSize must be a vector of [x y], [x y z] for rectangular-grid,
%   rectangular-grid-3d ARRANGEMENT respectively. x,y,z is of integer type and
%   defines the number of basis points along x,y,z dimension.
%   Default: 64 for uniform-ball, uniform-ball-3d
%            [8 8] for rectangular-grid
%            [4 4 4] for rectangular-grid-3d
%
%   CENTER is the center of the basis point set arrangement. For 2D
%   arrangements, CENTER is a vector of [x y]. x,y defines the location of
%   the [x,y] coordinate of the point. For 3D arrangements CENTER is a
%   vector of [x y z]. x,y,z denotes the [x,y,z] coordinates of the point.
%
%   arrangementSize is the bounds of the basis points. For ARRANGEMENT
%   uniform-ball and uniform-ball-3d, arrangementSize denote the radius of
%   the ball. For ARRANGEMENT rectangular-grid and rectangular-grid-3d
%   arrangementSize denote the dimensions of the rectangle as [length width]
%   [length width height] respectively.
%   Default: 1 for uniform-ball and uniform-ball-3d
%            [2 2] for rectangular-grid
%            [2 2 2] for rectangular-grid-3d
%
% Copyright 2023 The MathWorks, Inc.

%#codegen

% Get the basis point arrangement as a struct.
    arr =  getArrangement();

    % Retrieve basis point set dimension
    bpsDim = environmentDimension(arrangement, arr);

    bps = zeros(0,3);
    % Find basis points
    switch arrangement
      case {arr.uniformball, arr.uniformball3d}
        bps = createRandomUniformBall(encodingSize, bpsDim, center, arrangementSize);
      case {arr.rectgrid, arr.rectgrid3d}
        bps = createRectangularGrid(encodingSize, bpsDim, center, arrangementSize);
    end
end
function [arr, arrangements] =  getArrangement()
% getArrangement return a struct containing the valid arrangement options.
% Additionally it returns a cell array of arrangements.
    arrangements = {'uniform-ball', 'uniform-ball-3d', 'rectangular-grid', 'rectangular-grid-3d'};
    fields = {'uniformball', 'uniformball3d', 'rectgrid', 'rectgrid3d'};
    % For codegen, using a loop to create the structure. cell2struct is not
    % supported for codegen.
    for i=1:length(fields)
        arr.(fields{i}) = arrangements{i};
    end
end

function envDim = environmentDimension(arrangement, arr)
% environmentDimension return the dimension of the basis points arrangement

    envDim = 0;
    switch arrangement
      case {arr.uniformball, arr.rectgrid}
        envDim = 2;
      case {arr.rectgrid3d, arr.uniformball3d}
        envDim = 3;
    end
end

function bps = createRandomUniformBall(numBasisPoints, bpsDim, center, arrangementSize)
% createRandomUniformBall creates uniform-ball, uniform-ball-3d arrangement
% of basis points.

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
    bpsAtOrigin = arrangementSize.*normalisedPoints.*u;
    bps = center + bpsAtOrigin;
end

function bps = createRectangularGrid(encodingSize, bpsDim, center, arrangementSize)
% createRectangularGrid creates rectangular-grid and rectangular-grid-3d arrangement.

    lowerLimits = center - (arrangementSize./2);
    upperLimits = center + (arrangementSize./2);
    limits = [lowerLimits' upperLimits'];
    basisAlongX = encodingSize(1);
    basisAlongY = encodingSize(2);

    xPoints = linspace(limits(1, 1), limits(1, 2), basisAlongX);
    yPoints = linspace(limits(2, 1), limits(2, 2), basisAlongY);

    if bpsDim == 2
        [bpsx, bpsy] = meshgrid(xPoints, yPoints);
        bpsxAll = bpsx(:);
        bpsyAll = bpsy(:);
        bps = [bpsxAll, bpsyAll];
    else

        basisAlongZ = encodingSize(3);
        zPoints = linspace(limits(3, 1), limits(3, 2), basisAlongZ);
        [bpsx, bpsy, bpsz] = meshgrid(xPoints, yPoints, zPoints);

        bps = [bpsx(:), bpsy(:) bpsz(:)];
    end
end
