function [xgridcoords, ygridcoords, meanq, covar, covarInv] = buildNDT(laserScan, cellSize)
%This function is for internal use only. It may be removed in the future.

%buildNDT Build Normal Distributions Transform from laser scan
%   [XGRIDCOORDS, YGRIDCOORDS, MEANQ, COVAR, COVARINV] =
%   buildNDT(LASERSCAN, CELLSIZE) discretizes the laser scan points into
%   cells and approximates each cell with a Normal distribution.
%
%   Inputs:
%      LASERSCAN - N-by-2 array of 2D Cartesian points
%      CELLSIZE - Defines the side length of each cell used to build NDT.
%         Each cell is a square area used to discretize the space.
%
%   Outputs:
%      XGRIDCOORDS - 4-by-M, the discretized x coordinates of the grid of
%         cells, with each cell having a side length equal to CELLSIZE.
%         Note that M increases when CELLSIZE decreases. The second row
%         shifts the first row by CELLSIZE/2 to the right. The third row
%         shifts the first row by CELLSIZE/2 to the top. The fourth row
%         shifts the first row by CELLSIZE/2 to the right and top. The same
%         row semantics apply to YGRIDCOORDS, MEANQ, COVAR, and COVARINV.
%      YGRIDCOORDS: 4-by-P, the discretized y coordinates of the grid of
%         cells, with each cell having a side length equal to CELLSIZE.
%      MEANQ: 2-by-(M*P)-by-4, the mean of the points in cells described by
%         XGRIDCOORDS and YGRIDCOORDS.
%      COVAR: 2-by-2-by-(M*P)-by-4, the covariance of the points in cells
%      COVARINV: 2-by-2-by-(M*P)-by-4, the inverse of the covariance of
%         the points in cells.
%
%   [XGRIDCOORDS, YGRIDCOORDS, MEANQ, COVAR, COVARINV] describe the NDT
%   statistics.

%   Copyright 2016-2021 The MathWorks, Inc.
%
%   References:
%
%   [1] P. Biber, W. Strasser, "The normal distributions transform: A
%       new approach to laser scan matching," in Proceedings of IEEE/RSJ
%       International Conference on Intelligent Robots and Systems (IROS),
%       2003, pp. 2743-2748

%#codegen

% When the scan contains ONLY NaN values (no valid range readings),
% the input laserScan is empty. Explicitly
% initialize empty variables to support code generation.
    if isempty(laserScan)
        xgridcoords = zeros(4,0);
        ygridcoords = zeros(4,0);
        meanq       = zeros(2,0,4);
        covar       = zeros(2,2,0,4);
        covarInv    = zeros(2,2,0,4);
        return;
    end

    % Discretize the laser scan into cells
    [xgridcoords, ygridcoords] = preNDT(laserScan, cellSize);

    xNumCells = size(xgridcoords,2);
    yNumCells = size(ygridcoords,2);
    numCells = xNumCells*yNumCells;

    % Preallocate outputs
    meanq = zeros(2,numCells,4);
    covar = zeros(2,2,numCells,4);
    covarInv = zeros(2,2,numCells,4);

    % For each cell, compute the normal distribution that can approximately
    % describe the distribution of the points within the cell.
    for cellShiftMode = 1:4
        % Find the points in the cell
        % First find all points in the xgridcoords and ygridcoords
        % separately and then combine the result.
        [~, indx] = histc(laserScan(:,1), xgridcoords(cellShiftMode,:)); %#ok<HISTC>
        [~, indy] = histc(laserScan(:,2), ygridcoords(cellShiftMode,:)); %#ok<HISTC>
        % Create correspondence between points and cells
        ind = (indx-1)*yNumCells  + indy;
        % Sort the indices to group points belong to same cell at one
        % place. This helps to access them directly, instead of computing
        % point indices at every grid while looping.
        [sortedInd, ptInd] = sort(ind);
        % Identify the number of points at each cell
        idCounts = histc(ind, unique(ind)); %#ok<HISTC>

        endIdx = 0;
        % Loop over valid cells
        for i = 1: length(idCounts)
            gridIdx = endIdx + 1;
            endIdx = endIdx + idCounts(i);
            % If there are more than 3 points in the cell, compute the
            % statistics. Otherwise, all statistics remain zero.
            % See reference [1], section III.
            if idCounts(i) > 3
                xymemberInCell = laserScan(ptInd(gridIdx:endIdx),:);

                % Compute mean and covariance
                xymean = mean(xymemberInCell);
                xyCov = cov(xymemberInCell, 1);

                % Prevent covariance matrix from going singular (and not be
                % invertible). See reference [1], section III.
                [U,S,V] = svd(xyCov);
                if S(2,2) < 0.001 * S(1,1)
                    S(2,2) = 0.001 * S(1,1);
                    xyCov = U*S*V';
                end

                [~, posDef] = chol(xyCov);
                if posDef ~= 0
                    % If the covariance matrix is not positive definite,
                    % disregard the contributions of this cell.
                    continue;
                end

                % Store statistics
                meanq(:,sortedInd(gridIdx),cellShiftMode) = xymean;
                covar(:,:,sortedInd(gridIdx),cellShiftMode) = xyCov;
                covarInv(:,:,sortedInd(gridIdx),cellShiftMode) = inv(xyCov);
            end
        end
    end
end

function [xgridcoords, ygridcoords] = preNDT(laserScan, cellSize)
%preNDT Calculate cell coordinates based on laser scan
%   [XGRIDCOORDS, YGRIDCOORDS] = preNDT(LASERSCAN, CELLSIZE) calculated the
%   x (XGRIDCOORDS) and y (YGRIDCOORDS) coordinates of the cell center
%   points that are used to discretize the given laser scan.
%
%   Inputs:
%      LASERSCAN - N-by-2 array of 2D Cartesian points
%      CELLSIZE - Defines the side length of each cell used to build NDT.
%         Each cell is square
%
%   Outputs:
%      XGRIDCOORDS - 4-by-M, the discretized x coordinates using cells with
%         size equal to CELLSIZE.
%      YGRIDCOORDS: 4-by-P, the discretized y coordinates using cells with
%         size equal to CELLSIZE.

    xmin = min(laserScan(:,1));
    ymin = min(laserScan(:,2));
    xmax = max(laserScan(:,1));
    ymax = max(laserScan(:,2));

    halfCellSize = cellSize/2;

    lowerBoundX = floor(xmin/cellSize)*cellSize-cellSize;
    upperBoundX = ceil(xmax/cellSize)*cellSize+cellSize;
    lowerBoundY = floor(ymin/cellSize)*cellSize-cellSize;
    upperBoundY = ceil(ymax/cellSize)*cellSize+cellSize;

    % To minimize the effects of discretization,use four overlapping grids.
    % That is, one grid with side length cellSize of a single cell is
    % placed first, then a second one, shifted by cellSize/2 horizontally,
    % a third one, shifted by cellSize/2 vertically and a fourth one,
    % shifted by cellSize/2 horizontally and vertically.

    xgridcoords = [  lowerBoundX:cellSize:upperBoundX;...                       % Grid of cells in position 1
                     lowerBoundX+halfCellSize:cellSize:upperBoundX+halfCellSize;...  % Grid of cells in position 2 (X Right, Y Same)
                     lowerBoundX:cellSize:upperBoundX; ...                           % Grid of cells in position 3 (X Same, Y Up)
                     lowerBoundX+halfCellSize:cellSize:upperBoundX+halfCellSize];    % Grid of cells in position 4 (X Right, Y Up)

    ygridcoords = [  lowerBoundY:cellSize:upperBoundY;...                           % Grid of cells in position 1
                     lowerBoundY:cellSize:upperBoundY;...                            % Grid of cells in position 2 (X Right, Y Same)
                     lowerBoundY+halfCellSize:cellSize:upperBoundY+halfCellSize;...  % Grid of cells in position 3 (X Same, Y Up)
                     lowerBoundY+halfCellSize:cellSize:upperBoundY+halfCellSize];    % Grid of cells in position 4 (X Right, Y Up)

end
