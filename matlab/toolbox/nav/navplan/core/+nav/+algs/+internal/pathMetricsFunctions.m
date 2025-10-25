classdef pathMetricsFunctions < nav.algs.internal.InternalAccess
     %This Class is for internal use only. It may be removed in the future.
     %This is a helper class that includes the Clearance and Smoothness functions for Pathmetrics

     %   Copyright 2019-2022 The MathWorks, Inc.

    methods(Static)
        function [minDist,obstacles] = clearance(points, map)
           
            %CLEARANCE Compute the minimum distance between the query points and
            %   obstacles. The min distance is precise upto sqrt(2) times grid map cell
            %   size.
            %
            %   [MINDIST,OBSTACLES] = clearance(POINTS, MAP) returns minimum
            %   distances MINDIST, coordinates at minimum distances of the states from the obstacles OBSTACLES
            %   MINDIST is 1-by-N vector, and 
            %   OBSTACLES is a matrix of size N-by-2 ([x y]) for 2D and N-by-3 ([x y z]) for 3D where is N number of POINTS.
            %   POINTS is a matrix of size N-by-2 ([x y]) for 2D and N-by-3 ([x y z]) for 3D and
            %   MAP is either binaryOccupancyMap, occupancyMap or occupancyMap3D.

            

            minDist = inf(1,size(points,1));
            outType = uint32(1);

            if isa(map, "occupancyMap3D")

                %Get the limits of the occupancyMap3D
                mapLimits = currentMapDimensions(map);

                %Get the limits of the path states
                pathLimits = [min(points(:,1:3),[],1); max(points(:,1:3),[],1)]';

                %Calculate the overall limits based on the map and states limits so as to include all the states and path
                overallLimits = [min(mapLimits(:,1),pathLimits(:,1)),max(mapLimits(:,2),pathLimits(:,2))];

                %Get Occupancy Matrix of the MAP based on the overallLimts
                %If the occupancyMatrix is large and takes size more than allowed in MATLAB, 
                % over riding the message to give a more meaningful error message
                try
                    matrix = occupancyMatrix(map, overallLimits);
                catch ME
                    if strcmp(ME.identifier,'MATLAB:array:SizeLimitExceeded')
                        coder.internal.error('nav:navalgs:pathMetrics:TooLargeMap');
                    else
                        throw(ME)
                    end
                end

                %Convert Matrix from tribool to logical
                matrix(matrix == -1) = 0;
                matrix = logical(matrix);

                %Find the nearest obstacle and Clearance
                [ObsCellDistance, obstCellIndices] = ...
                    imageslib.internal.bwdistComputeEDTFT(matrix, outType);

                obstacles = nan(size(points,1),3);
                % Return distances inf if environment is free.
                % ObsCellDistance will be inf for all the points if the map is empty
                if isinf(ObsCellDistance(1,1))
                    return;
                end

                gridCells = map.world2grid(points,overallLimits);
                gridCellLinearInd = sub2ind(size(obstCellIndices), gridCells(:,1), gridCells(:,2), gridCells(:,3));

                % Find nearest occupied grid cell index for gridCells(k)
                [I, J, K] = ind2sub(size(obstCellIndices), obstCellIndices(gridCellLinearInd));

                % Convert the occupied grid into world point.
                obstacles = map.grid2world([I,J,K],overallLimits);
                xyzPts = map.grid2world( gridCells,overallLimits);

                %Find the distance between obstacle points and states.
                dis = obstacles - xyzPts;

            else
                if isa(map, "binaryOccupancyMap")
                    matrix = map.occupancyMatrix;
                else
                    matrix = occupancyMatrix(map, 'ternary');
                    matrix(matrix == -1) = 0;
                    matrix = logical(matrix);
                end

                %Find the minimum distance for each grid cells and closest grid
                %cells indices. Size of ObsCellDistance and
                %obstCellIndices are equal to size(matrix).
                [ObsCellDistance, obstCellIndices] = ...
                    imageslib.internal.bwdistComputeEDTFT(matrix, outType);

                obstacles = nan(size(points,1),2);

                % Return distances inf if environment is free.
                if isinf(ObsCellDistance(1,1))
                    return;
                end

                % Convert poses into grid cells.
                gridCells = world2grid(map, points(:,1:2));

                gridCellLinearInd = sub2ind(map.GridSize, gridCells(:,1), gridCells(:,2));

                % Find nearest occupied grid cell index for gridCells(k)
                [I, J] = ind2sub(size(obstCellIndices), obstCellIndices(gridCellLinearInd));

                % Convert the occupied grid into world point.
                obstacles = grid2world(map,[I,J]);

                xyPts = grid2world(map,world2grid(map,points(:,1:2)));
                dis = obstacles - xyPts;
            end
            minDist = sqrt(sum(dis.*dis,2))';
        end


        function smoothVals = smoothness(points, distanceFcn)
          
            %SMOOTHNESS Evaluate smoothness for given set of wayposes/waypoints.
            %
            %   SMOOTHVALS = smoothness(POINTS, DISTANCEFCN) evaluates the smoothness
            %   of each 3 consecutive points POINTS using distance function handle
            %   DISTANCEFCN. This returns 1x(N-2) vector (double) where N is the number
            %   of POINTS (wayposes/waypoints). The closer the value is to 0, the
            %   smoother the path. Detailed formula follows. The idea is to look at the
            %   triangles formed by consecutive path segments and compute the angle
            %   between those segments using Pythagoras theorem. Then, the outside
            %   angle for the computed angle is normalized by the path segments and
            %   contributes to the path smoothness. For a straight line path, the
            %   smoothness will be 0.

            %
            %   References:
            %
            %   [1] http://ompl.kavrakilab.org/classompl_1_1geometric_1_1PathGeometric.html.

            % Smoothness
            smoothVals = zeros(1, size(points,1)-2);

            if size(points,1) > 2
                a = distanceFcn(points(1,:), points(2,:));
                for i = 3:size(points,1)
                    % view the path as a sequence of segments, and look at the triangles it forms:
                    %
                    % use Pythagoras generalized theorem to find the cos of the angle between segments a and b
                    b = distanceFcn(points(i-1,:), points(i,:));
                    c = distanceFcn(points(i-2,:), points(i,:));

                    acosValue = (a * a + b * b - c * c) / (2.0 * a * b);

                    if (acosValue > -1.0 && acosValue < 1.0)
                        % the smoothness is actually the outside angle of the one we compute
                        angle = pi - acos(acosValue);

                        % and we normalize by the length of the segments
                        k = 2.0 * angle / (a + b);
                        smoothVals(i-2) = k * k;
                    end
                    a = b;
                end
            end
        end
    end
end

