classdef traversabilityFilter < handle
    % traversabilityFilter Compute the traversability related properties
    % such as slope, roughness and step height.

    % Copyright 2024-2025 The MathWorks, Inc.

    %#codegen

    methods(Static, Hidden)

        function [slope, roughness] = slopeAndRoughness(elevModel, xvals, yvals)
            %slopeAndRoughness Compute slope and roughness from elevation
            %model
            % INPUTS
            %   ELEVMODEL : Digital elevation model for a terrain. The
            %               first dimension of ELEVMODEL corresponds to the
            %               y-axis and second dimension corresponds to the
            %               x-axis.
            % OUTPUTS:
            %        SLOPE: Slope output corresponding to each grid cell in
            %               ELEVMODEL
            %    ROUGHNESS: Roughness output corresponding to each grid
            %               cell in ELEVMODEL.
            %
            %{
            % Example
            elevModel = peaks;
            xvals = 1:49; yvals = 21:69;
            [slope, roughness] =...
                nav.algs.internal.traversabilityFilter.slopeAndRoughness(elevModel, xvals, yvals);
            % Visualize
            subplot(121);
            surf(xvals, yvals, slope, EdgeColor='none')
            title('Slope')
            subplot(122);
            surf(xvals, yvals, roughness, EdgeColor='none')
            title('Roughness')
            %}
            arguments
                elevModel(:,:) double
                xvals (1,:) double
                yvals (1,:) double
            end

            % Get indices of all neighbors surrounding each cell
            k = 3; % 3x3 window size
            gridSize = size(elevModel);
            neighborInd = nav.algs.internal.traversabilityFilter.gridNeighborsWholeMap(gridSize, k);   

            % Other misc. variables needed for further computations
            [xgrid, ygrid] = meshgrid(xvals, yvals);
            numCells = prod(gridSize); % Total no. of grid cells in map
            numNeighbors = k^2-1; % No. of neighbors for each cell

            % Get x,y,z coordinates of all neighbors surrounding each cell
            xNeighbors = xgrid(neighborInd);
            yNeighbors = ygrid(neighborInd);
            zNeighbors = elevModel(neighborInd);
            xNeighbors = reshape(xNeighbors, numCells, numNeighbors);
            yNeighbors = reshape(yNeighbors, numCells, numNeighbors);
            zNeighbors = reshape(zNeighbors, numCells, numNeighbors);

            % Concatenate x,y,z coordinates of neighbors
            points = cat(3, xNeighbors, yNeighbors, zNeighbors); %[numCells, numNeighbors, 3]

            % Compute surface normals
            if coder.target('MATLAB')
                normals = nav.algs.internal.mex.surfaceNormals(points); % [numCells, numNeighbors, 3]
            else
                normals = nav.algs.internal.traversabilityFilter.surfaceNormals(points);
            end

            % Get the cosine of the slope, i.e., the projection of the
            % surface normal onto the z-axis. Ensure that the normal is
            % consistently oriented (positive in the +z direction). This is
            % necessary because the direction is ambiguous in the context
            % of eigenvectors i.e., if V is a valid Eigen vector for a
            % given Eigen value, lambda, then -V is also a valid Eigen
            % vector.
            cosineSlope = abs(normals(:,3));

            % Due to rounding errors, the normals can be slightly greater
            % than 1. This can lead to complex numbers while computing arc
            % cosine. So we clip the cosineSlope to 1.
            cosineSlope = min(cosineSlope, 1.0);

            % Compute slope
            slope = acos(cosineSlope);
            slope = reshape(slope, gridSize);

            % Compute roughness from surface normals and centered points.
            % Its the standard deviation of the projection of centered
            % points on to surface normal.
            if nargout == 2
                R = points - mean(points,2); % centered points [numCells, numNeighbors, 3]
                normals = reshape(normals, [numCells, 1, 3]); % [numCells, 1, 3]
                roughness = std(sum(R.*normals,3), 0, 2);
                roughness = reshape(roughness, gridSize);
            end
        end


        function sheight = stepHeight(elevModel, k)
            %stepHeight Compute step height from elevation data and step
            %height window size.
            %
            % INPUTS
            %    ELEVMODEL: Digital elevation model for a terrain, and with
            %               default Resolution of 1 cell/meter. The first
            %               dimension of ELEVMODEL corresponds to the
            %               y-axis and second dimension corresponds to
            %               the x-axis.
            %            K: Window size [k,k] of neighborhood surrounding
            %               each cell.
            % OUTPUTS:
            %      SHEIGHT: Step height corresponding to each grid cell in
            %               ELEVMODEL.
            %
            %{
            % Example
            elevModel = peaks; k = 7;
            h = nav.algs.internal.traversabilityFilter.stepHeight(elevModel, k);
            surf(h, EdgeColor='none')
            %}
            arguments
                elevModel (:,:) double
                k (1,1) double = 7 % cells
            end

            gridSize = size(elevModel);
            includecenter = true; % we need to access the center cell to compute step height
            neighborInd = nav.algs.internal.traversabilityFilter.gridNeighborsWholeMap(gridSize, k, includecenter);

            numCells = prod(gridSize);
            numNeighbors = k^2; %no. of neighbors for each cell including self center cell
            
            zNeighbors = elevModel(neighborInd);
            zNeighbors = reshape(zNeighbors, numCells, numNeighbors);

            centerCell = floor(k^2/2)+1;
            zCenterCell = zNeighbors(:,centerCell);            

            heightDiff = abs(zNeighbors-zCenterCell);
            sheight = max(heightDiff, [], 2);
            sheight = reshape(sheight, gridSize);

        end

        function normals = surfaceNormals(points)
            % surfaceNormals Compute the surface normals for the
            % neighborhood of points
            % INPUTS
            %   POINTS : Coordinates of points where we want to compute the
            %            surface normals, using the neighborhood of points.
            %            Shape: [N, M, 3]
            % OUTPUTS:
            %   NORMALS: Surface normals of shape [N, 3]. Each column
            %            corresponds to x, y, z components of surface
            %            normal.

            % We use the Principal Component Analysis (PCA) approach to
            % compute the surface normals. We compute the covariance matrix
            % of neighborhood points. The surface normal is equal to the
            % Eigen vector corresponding to the smallest Eigen value of the
            % covariance matrix.
            %
            % This approach is robust to noise and provides accurate
            % representation of local surface geometry as compared to
            % gradient methods.

            [numPoints, numNeighbors, ~] = size(points);
            normals = zeros(numPoints, 3);            
            for i=1:numPoints
                % Compute covariance
                point = points(i,:);
                point = reshape(point, [numNeighbors,3]);
                C = cov(point);

                % Ensure the covariance matrix is symmetric to avoid
                % complex Eigen vectors (edge cases)
                % C = (C + C') / 2; 

                % Get Eigen vector corresponding to smallest Eigen value      
                [V, lambda] = eig(C);
                [~, ind] = sort(diag(lambda));
                normals(i,:) = real(V(:, ind(1))); %enforce real for codegen

                % Note that V & -V are valid Eigen vectors for a given
                % Eigen value, lambda. So we cannot obtain the sign of
                % surface normal using this.
            end
        end

        function neighborInd = gridNeighborsWholeMap(gridSize, k, includecenter)
            % gridNeighborsWholeMap Get neighbor cell indices for all cells
            % in the map. The cells that fall out of the borders are
            % clipped.
            %
            % INPUTS:
            %      GRIDSIZE: Grid size of map of shape [m,n]
            %             K: Window size [k,k] of neighbor cells
            % INCLUDECENTER: if set to true the center cell will be included            
            %
            % OUTPUTS:
            %   NEIGHBORIND: Linear indices of all neighbors of each cell in the map           
            %
            %{
            % Example:
            gridSize = [10,9];  k=3;
            ind = nav.algs.internal.traversabilityFilter.gridNeighborsWholeMap(gridSize, k);
            %}

            arguments
                gridSize (1,2) double
                k (1,1) double = 3
                includecenter (1,1) logical = false
            end

            [rows, cols] = deal(gridSize(1), gridSize(2));
            [neighborRows, neighborCols] = nav.algs.internal.traversabilityFilter.gridNeighbors(k, includecenter);
            [colsGrid, rowsGrid] = meshgrid(1:cols, 1:rows); % order: x,y
            rowsGrid = rowsGrid(:);
            colsGrid = colsGrid(:);

            neighborRows = min(max(rowsGrid + neighborRows, 1), rows);
            neighborCols = min(max(colsGrid + neighborCols, 1), cols);

            neighborInd = sub2ind(gridSize, neighborRows(:), neighborCols(:));
        end

        function [rows, cols] = gridNeighbors(k, includecenter)
            % gridNeighbors Get coordinates of grid cells of window size
            % [k,k] surrounding a grid cell
            %
            % INPUTS:
            %             K: Window size [k,k] of neighbor cells
            % INCLUDECENTER: if set to true the center cell will be included
            %
            % OUTPUTS:
            % ROWS: Row indices of neighbors surrounding one grid cell
            % COLS: Col indices of neighbors surrounding one grid cell
            %
            %{
            % Example:
            k = 3;
            [neighborsRows, neighborsCols] = nav.algs.internal.traversabilityFilter.gridNeighbors(k);
            scatter(neighborsRows, neighborsCols, 'filled'); 
            grid on
            %}
            arguments(Input)
                k (1,1) double {mustBeOdd}
                includecenter logical = false;
            end

            arguments(Output)
                rows (1,:)
                cols (1,:)
            end

            % Compute neighbors
            numCells = (k-1)/2;
            neighbors = -numCells:numCells;
            [rows, cols] = meshgrid(neighbors, neighbors);

            % Convert meshgrid to vector
            rows = rows(:);
            cols = cols(:);

            if ~includecenter
                % Remove the center cell for which we are computing the neighbors
                centerCell = floor(k^2/2)+1;
                rows(centerCell) = [];
                cols(centerCell) = [];
            end
        end
    end
end

function mustBeOdd(input)
%mustBeOdd Validate if the input is odd
validateattributes(input, {'numeric'}, {'odd'})
end
