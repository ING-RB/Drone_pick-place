classdef ObstacleEdgesTEB < matlabshared.autonomous.map.internal.InternalAccess
    % This class is for internal use only. It may be removed in the future.

    % Obstacle distance computation utility based on inflation circles

    %{
    % Example
    %
    % Setup a map and compute Hybrid A* path for a given start and goal
    map = load("exampleMaps.mat").complexMap;
    map = binaryOccupancyMap(map);
    stateValidator = validatorOccupancyMap;
    stateValidator.Map = map;
    stateValidator.ValidationDistance = 0.01;
    planner = plannerHybridAStar(stateValidator,MinTurningRadius=2);
    start = [6 3 pi/2];
    goal = [32 32 0];
    pth = plan(planner,start,goal);
    poses = pth.States;

    % Get SDF from the input map
    sdfMap = nav.algs.internal.extractSignedDistanceMap(map);

    % Approximate the robot with collision circles
    robotDimensions = [1,0.5];
    [centers, radius] = nav.algs.internal.vehicleCirclesApproximation(robotDimensions);

    % Define inclusion and cutoff distances
    inclusionDist = 5;
    cutoffDist = 30;

    % Setup obstacle edge computation object
    obstEdgesTEB = nav.algs.internal.ObstacleEdgesTEB(sdfMap,...
                ObstacleInclusionDistance=inclusionDist,...
                ObstacleCutOffDistance=cutoffDist,...
                RobotCollisionCenters=centers,...
                RobotCollisionRadius=radius);

    % Get obstacle edges for input poses
    [obstPos, obstEdges, obstTypes] = obstEdgesTEB.computeEdges(poses);

    % Select a random pose and get its obstacle edges
    ind = randsample(obstEdges(:,1),1);
    k = obstEdges(:,1)==ind;
    poseNodes = poses(obstEdges(k,1),:);
    obstNodes = obstPos(obstEdges(k,2),:);

    % Visualize obstacles from a randomly sampled pose
    types = obstTypes(k);
    show(map); hold on;
    scatter(poses(:,1), poses(:,2), DisplayName='All Poses')
    scatter(poseNodes(:,1), poseNodes(:,2), 'filled', DisplayName='Selected Pose');
    scatter(obstNodes(types==1,1), obstNodes(types==1,2), 'filled', DisplayName='Inclusion Obst');
    scatter(obstNodes(types==2,1), obstNodes(types==2,2), 'filled', DisplayName='Left Obst');
    scatter(obstNodes(types==3,1), obstNodes(types==3,2), 'filled', DisplayName='Right Obst');
    plot(poses(1,1), poses(1,2), plannerLineSpec.start{:})
    plot(poses(end,1), poses(end,2), plannerLineSpec.goal{:})
    quiver(poses(:,1),poses(:,2),cos(poses(:,3)),sin(poses(:,3)),0.1);
    legend    
    %}

    %   Copyright 2024 The MathWorks, Inc.

    %#codegen

    properties(SetAccess=private)
        %SDFMap signedDistanceMap containing the original obstacle information
        SDFMap

        %LookupSDFMap Create a separate SDF map for quick obstacle lookup
        LookupSDFMap

        %CutoffDistance Obstacle cutoff distance
        ObstacleCutOffDistance

        %ObstacleInclusionDistance Obstacle inclusion distance
        ObstacleInclusionDistance

        %RobotCollisionCenters Center of the collision circles that are
        %used to approximate the robot
        RobotCollisionCenters

        %RobotCollisionRadius Radius of collision circles that are used to
        %approximate the robot
        RobotCollisionRadius
    end

    methods
        function obj = ObstacleEdgesTEB(map, params)
            arguments
                map (1,1) signedDistanceMap
                params.ObstacleInclusionDistance (1,1) double = 1
                params.ObstacleCutOffDistance (1,1) double = 5
                params.RobotCollisionCenters (:,2) double = [0,0]
                params.RobotCollisionRadius (1,1) double = 0
            end

            % Update properties
            obj.SDFMap = map;
            obj.RobotCollisionCenters = params.RobotCollisionCenters;
            obj.RobotCollisionRadius = params.RobotCollisionRadius;
            obj.ObstacleInclusionDistance = params.ObstacleInclusionDistance;
            obj.ObstacleCutOffDistance = params.ObstacleCutOffDistance;

            % Max end-to-end length of robot collision circles
            lenRobotInflationCircles = 2*obj.RobotCollisionRadius + ...
                obj.RobotCollisionCenters(end,1) - obj.RobotCollisionCenters(1,1);

            % Max search radius for looking up the obstacles
            searchRadius = obj.ObstacleCutOffDistance + lenRobotInflationCircles;            
            searchRadiusMax = hypot(diff(obj.SDFMap.XWorldLimits), diff(obj.SDFMap.YWorldLimits));
            searchRadius = min(searchRadius, searchRadiusMax); % limit search radius to size of map

            % Separate SDF map for obstacle lookup. This local SDF has one
            % fixed pseudo-obstacle at the center which indicates the robot
            % location. We look up the distances to surrounding actual
            % obstacles by querying their distances to the robot at the
            % center.
            numCells = ceil(2 * searchRadius * obj.SDFMap.Resolution) + 1;
            if mod(numCells,2) == 0                 
                numCells = numCells + 1; % odd number of cells for robot to be exactly at center
            end
            occupancyValues = zeros(numCells);
            centerCell = floor(numCells/2)+1;
            occupancyValues(centerCell, centerCell) = 1;
            obj.LookupSDFMap = signedDistanceMap(occupancyValues, obj.SDFMap.Resolution);
        end

        function [obstDist, obstPos] = findAllObstacles(obj, pose)
            %findAllObstacles Find all obstacles near a given robot pose
            %based on a cut off distance
            %
            %   INPUTS:
            %       OBJ
            %       POSE    : Robot pose vector of shape [1,3] representing
            %                 [x,y,theta] coordinates
            %   OUTPUTS:
            %       OBSDIST : Distance to all the obstacles from the robot
            %                 at a given pose with in cutoff distance. 
            %                 Positive values indicate that there is some 
            %                 gap between robot and obstacles. Negative 
            %                 values indicate that robot is in collision 
            %                 with the obstacles.
            %       OBSXY   : Locations of all obstacles near the vehicle
            %                 pose

            arguments
                obj
                pose (1,3) double
            end

            % Get robot location in the grid frame of original SDFMap
            poseGrid = obj.SDFMap.world2gridImpl(pose(1:2));

            % Get obstacle cells in the grid frame of LookupSDFMap
            lookupMapTopLeftCorner = poseGrid - (floor(obj.LookupSDFMap.GridSize(1)/2)+1);
            occMat = obj.SDFMap.getMapData(lookupMapTopLeftCorner, obj.LookupSDFMap.GridSize, 'grid');
            [obsGridI_, obsGridJ_] = find(occMat);

            % No occupied cells with in the search radius of robot
            if isempty(obsGridI_)
                obstDist = zeros(0,1);
                obstPos = zeros(0,2);
                return
            end

            % Get obstacle locations in the world frame of the original SDFMap
            obsGridIJ = [obsGridI_, obsGridJ_] + lookupMapTopLeftCorner -1;
            obstPos = obj.SDFMap.grid2worldImpl(obsGridIJ);

            % Get obstacle locations in LookupSDFMap coordinates
            obstPos_ = obj.LookupSDFMap.grid2worldImpl([obsGridI_, obsGridJ_]);

            % Transform the inflation circle centers w.r.t robot pose
            if obj.RobotCollisionRadius > 0
                % When robot is a set of collision circles
                centers = [obj.RobotCollisionCenters, zeros(height(obj.RobotCollisionCenters),1)];
                circleCentersTr = nav.algs.internal.transformSE2Poses(centers, pose);
            else
                % When robot is a point
                circleCentersTr = pose;
            end

            % For robot represented by collision circles, we shift the
            % origin of the lookup map such that the center of each
            % collision circle is at the center and then compute the
            % distance. Finally we consider the distance that corresponds
            % to the closest collision circle
          
            % Get obstacle distances from the nearest inflation circle
            % center of the robot
            obstDist = inf(height(obstPos_),1);
            for i = 1:height(obj.RobotCollisionCenters)

                % Shift origin to align center of map with center of inflation circle
                obj.LookupSDFMap.GridLocationInWorld = circleCentersTr(i,1:2)-pose(1:2)-...
                    (1/obj.LookupSDFMap.Resolution)*[-1 1];

                %Lookup the distance for the specified obstacle location
                d = obj.LookupSDFMap.distance(obstPos_)-obj.RobotCollisionRadius;
                obstDist = min(obstDist, d);
            end

            obj.LookupSDFMap.GridLocationInWorld = [0,0]; % reset origin
        end


        function [obstPos, obstEdges, obstTypes] = computeEdges(obj, poses)
            %computeEdges
            %   INPUTS:
            %       POSES     : [N x 2] array containing the poses of the
            %                   robot for an input path
            %   OUTPUTS:
            %       OBSTPOS   : [M x 2] array containing the positions of
            %                   obstacles surrounding the robot.
            %       OBSTEDGES : [P x 2] array with first column containing
            %                   the ID of POSES input, and, second column
            %                   containing the ID of OBSTPOS output that
            %                   form the obstacle edges
            %       OBSTYPES  : [P x 1] array indicating the type of
            %                   obstacle. 1 means obstacle is within
            %                   inclusion distance. 2, 3 means nearest left 
            %                   and right obstacle beyond inclusion
            %                   distance.
            arguments
                obj
                poses (:,3) double
            end

            dist = inf(height(poses),1);

            % Find distance to nearest obstacles
            [~, dist(2:end-1)] = nav.algs.internal.checkCollisionVehicleCircles(obj.SDFMap,...
                poses(2:end-1,:),...
                obj.RobotCollisionCenters(:,1:2), obj.RobotCollisionRadius);

            % Considered poses for which to compute neighboring obstacles
            % - Don't include start & goal poses for which we assigned inf distances
            % - Don't include poses for which there is no neighbor with in cutoff distance
            poseInd = find(~isinf(dist) & ~isnan(dist) & dist <= obj.ObstacleCutOffDistance);

            % Create buffer size for max possible obstacle edges
            nBuffer = height(poses)*prod(obj.LookupSDFMap.GridSize);            

            % Store obstacle positions in a buffer
            obstPosBuffer = zeros(nBuffer, 2);

            % Store the info about obstacle edges - [poseId, obstacleId]
            obstEdgesBuffer = zeros(nBuffer, 2);

            % Store the info about the type of obstacles. 
            % 1: within inclusion distance, 
            % 2: left side obstacle beyond inclusion distance
            % 3: right side obstacle beyond inclusion distance            
            obstTypeBuffer = zeros(nBuffer,1);

            obsCounter = 0;

            % Get obstacle edges for the considered poses
            for i = 1:length(poseInd)

                % Get all obstacles within cut off distance
                pose = poses(poseInd(i),:);                
                [obstDist, obstPosCurrent] = obj.findAllObstacles(pose);

                if isempty(obstDist)
                    continue
                end

                % Obstacles within inclusion distance
                withinInclusionDist = obstDist <= obj.ObstacleInclusionDistance;
                nInclusion = nnz(withinInclusionDist);
                if nInclusion > 0
                    ind = obsCounter+1:obsCounter+nInclusion;
                    obstPosBuffer(ind, :) = obstPosCurrent(withinInclusionDist,:);
                    obstEdgesBuffer(ind, 1) = poseInd(i); % path poses ind
                    obstEdgesBuffer(ind, 2) = ind; % obstacle ind
                    obstTypeBuffer(ind) = 1; % give identifier to obstacle
                    obsCounter = obsCounter + nInclusion;
                end

                % Store closest left and right obstacles beyond inclusion
                % distance
                beyondInclusionDistance = ~withinInclusionDist;
                if nnz(beyondInclusionDistance) > 0                
                    obstPosBeyond = obstPosCurrent(beyondInclusionDistance,:);
                    obsDistBeyond = obstDist(beyondInclusionDistance);

                    % Vector from current pose to next pose
                    poseNext = poses(poseInd(i)+1,:);
                    dirPath = poseNext(1:2) - pose(1:2);

                    % Vector from current pose to the obstacle 
                    dirPath2Obs = obstPosBeyond - pose(1:2);

                    % Dot product of above two vectors to know the direction
                    dotProd = dirPath(1).*dirPath2Obs(:,2) - dirPath(2).*dirPath2Obs(:,1);

                    % Get indices of left and right side obstacles
                    rightSideIndicator = dotProd <= 0; % 1 means right side, 0 means left side
                    leftSideInd = find(~rightSideIndicator);
                    rightSideInd = find(rightSideIndicator);

                    % Process closest obstacle on the left side
                    if ~isempty(leftSideInd)
                        obsCounter = obsCounter+1;
                        [~,j] = min(obsDistBeyond(leftSideInd));
                        obstPosBuffer(obsCounter,:) = obstPosBeyond(leftSideInd(j),:);
                        obstEdgesBuffer(obsCounter, 1) = poseInd(i); % pose ind
                        obstEdgesBuffer(obsCounter, 2) = obsCounter; %obstacle ind
                        obstTypeBuffer(obsCounter) = 2; % obstacle type (left)
                    end

                    % Process closest obstacle on the right side
                    if ~isempty(rightSideInd)
                        obsCounter = obsCounter+1;
                        [~,j] = min(obsDistBeyond(rightSideInd));
                        obstPosBuffer(obsCounter,:) = obstPosBeyond(rightSideInd(j),:);
                        obstEdgesBuffer(obsCounter, 1) = poseInd(i); % pose ind
                        obstEdgesBuffer(obsCounter, 2) = obsCounter; %obstacle ind
                        obstTypeBuffer(obsCounter) = 3; % obstacle type (right)
                    end
                end

            end

            % Extract outputs from the buffer
            obstPos = obstPosBuffer(1:obsCounter, :);
            obstEdges = obstEdgesBuffer(1:obsCounter, :);
            obstTypes = obstTypeBuffer(1:obsCounter, :);
        end
    end
end
