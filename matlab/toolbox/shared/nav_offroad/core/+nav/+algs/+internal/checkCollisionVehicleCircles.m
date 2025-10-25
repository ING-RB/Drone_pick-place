function [isColliding, distance, varargout] = checkCollisionVehicleCircles(obstacles, poses, centers, radius, options)
% This function is for internal use only. It may be removed in the future.

%checkCollisionVehicleCircles Checks the collision status of robot poses to
%the nearest obstacles on a signed distance map or to specified obstacle
%coordinates. Also outputs the distances and witness points based on the
%nearest robot collision circle.
%
%   INPUTS:
%       OBSTACLES   : signedDistanceMap or [Mx2] obstacle array
%       POSES       : [Nx3] array of robot POSES.
%       CENTERS     : [P x 2] matrix containing the center of collision circles
%                     representing the robot where each row represents the
%                     center of each circle.
%       RADIUS      : The radius of the collision circles, given as a scalar.
%     Name-Value pairs for the function:
%       EXHAUSTIVE  : Boolean flag. If set to true, evaluates all
%                     combinations of vehicle POSES and OBSTACLES array. If
%                     set to false, evaluates one-to-one combinations(M=N).
%                     Default: true
%     OBSTACLERADIUS: Radius of circle approximating a point in the OBSTACLE
%                     array. Default: 0
%
%   OUTPUTS:
%       ISCOLLIDING : Flag indicating whether the robot POSES are in
%                     collision with OBSTACLES.
%                     [N x 1] shaped array.
%          DISTANCE : Distance from nearest collision circle of the robot
%                     POSES to the OBSTACLES. If OBSTACLES is signed
%                     distance map input, DISTANCE is +/-ve values to the
%                     nearest boundary. If OBSTACLE is an array input,
%                     DISTANCE is zero for POSES that are in collision.
%                     [N x 1] shaped array.
%     WITNESSPOINTS : One-to-one corresponding pairs of nearest robot
%                     collision circle center of robot POSES and the
%                     OBSTACLES positions. If OBSTACLE is an array input,
%                     WITNESSPOINTS are nan for POSES that are in collision.
%                     [N x 4] shaped array.
%
%  NOTE: Name-Value arguments EXHAUSTIVE and OBSTACLERADIUS are applicable
%        when OBSTACLES is specified as an array.
%{

% Examples

%.. Example 1:
% Compute nearest distance from robot to a signed distance map
  map = load("exampleMaps.mat").complexMap;
  map = binaryOccupancyMap(map);
  stateValidator = validatorOccupancyMap;
  stateValidator.Map = map;
  stateValidator.ValidationDistance = 0.01;
  planner = plannerHybridAStar(stateValidator,MinTurningRadius=2);
  start = [6 3 pi/2];
  goal = [32 32 0];
  pth = plan(planner,start,goal);
  poses = pth.States(1:2:end,:);

% Approximate robot with collision circles
  [centers, radius] = nav.algs.internal.vehicleCirclesApproximation([1,0.5], 3);

% Extract signed distance map from occupancy map
  sdfMap = nav.algs.internal.extractSignedDistanceMap(map);

% Check collisions between robot poses and the map
  [iscolliding, distance, witnessPoints] = nav.algs.internal.checkCollisionVehicleCircles(...
  sdfMap, poses, centers, radius);

% Visualize
  show(map); hold on
  h(1) = scatter(poses(:,1), poses(:,2), 'filled', DisplayName='poses');
% Plot collision circles for all poses
  for i = 1:height(poses)
  collisionCircles = nav.algs.internal.transformSE2Poses(...
  [centers,zeros(height(centers),1)], poses(i,:));
  for j = 1:height(collisionCircles)
  rectangle('Position',[collisionCircles(j,1)-radius,....
  collisionCircles(j,2)-radius,...
  2*radius, 2*radius],...
  'Curvature',[1,1], 'EdgeColor','r', 'LineWidth',2);
  scatter(collisionCircles(j,1), collisionCircles(j,2), 'filled', 'o', MarkerFaceColor='b')
  end
  end
% Plot pairs of nearest collision circles and obstacle points
  nearestCircles = witnessPoints(:,1:2);
  obst = witnessPoints(:,3:4);
  h(2) = scatter(nearestCircles(:,1), nearestCircles(:,2), 20, 'filled', 'd', DisplayName='nearest robot circles');
  h(3) = scatter(obst(:,1), obst(:,2), 'filled', DisplayName='nearest obstacles');
  quiver(nearestCircles(:,1), nearestCircles(:,2),...
  obst(:,1)-nearestCircles(:,1), obst(:,2)-nearestCircles(:,2),...
  0, Color=[0.5,0.5,0.5])
  legend(h, Location='best')
  hold off

%.. Example 2:
% Compute one-to-one corresponding distances between robot poses and
% obstacle points
  rng(200,"twister")
  num = 5;
  poses = rand(num,3)*10;
  obst = poses(:,1:2) + 1*rand(num,2);

% Compute collision circle center and radius
  [centers, radius] = nav.algs.internal.vehicleCirclesApproximation([1,0.5]);

% Compute one-to-one distances and nearest collision circle centers
  [iscolliding, distance, witnessPoints] = nav.algs.internal.checkCollisionVehicleCircles(...
  obst, poses, centers, radius);

% Visualize
  h(1) = scatter(poses(:,1), poses(:,2), 'filled', DisplayName='poses');
  hold on
% Plot collision circles for all poses
  for i = 1:height(poses)
  collisionCircles = nav.algs.internal.transformSE2Poses(...
  [centers,zeros(height(centers),1)], poses(i,:));
  for j = 1:height(collisionCircles)
  rectangle('Position',[collisionCircles(j,1)-radius,....
  collisionCircles(j,2)-radius,...
  2*radius, 2*radius],...
  'Curvature',[1,1], 'EdgeColor','r', 'LineWidth',2);
  scatter(collisionCircles(j,1), collisionCircles(j,2), 'filled', 'o', MarkerFaceColor='b')
  end
  end
% Plot pairs of nearest robot collision circle and the obstacles
  nearestCircles = witnessPoints(:,1:2);
  obstMatching = witnessPoints(:,3:4);
  h(2) = scatter(nearestCircles(:,1), nearestCircles(:,2), 20, 'filled', 'd', DisplayName='nearest circles');
  h(3) = scatter(obstMatching(:,1), obstMatching(:,2), 'filled', DisplayName='obstacles');
  quiver(nearestCircles(:,1), nearestCircles(:,2),...
  obstMatching(:,1)-nearestCircles(:,1), obstMatching(:,2)-nearestCircles(:,2),...
  0, Color=[0.5,0.5,0.5])
  legend(h, Location='best')
  axis equal


%.. Example 3:
% Compute nearest distance from robot to a map that is converted to obstacle array
  map = load("exampleMaps.mat").complexMap;
  map = binaryOccupancyMap(map);
  stateValidator = validatorOccupancyMap;
  stateValidator.Map = map;
  stateValidator.ValidationDistance = 0.01;
  planner = plannerHybridAStar(stateValidator,MinTurningRadius=2);
  start = [6 3 pi/2];
  goal = [32 32 0];
  pth = plan(planner,start,goal);
  poses = pth.States(1:2:end,:);

% Approximate robot with collision circles
  [centers, radius] = nav.algs.internal.vehicleCirclesApproximation([1,0.5], 3);

% Extract obstacle list from occupancy map
  obstacleList = nav.algs.internal.extractObstacleList(map);
  obstacleRadius = 1/(sqrt(2)*map.Resolution);

% Check collisions between robot poses and the map
  [iscolliding, distance, witnessPoints] = nav.algs.internal.checkCollisionVehicleCircles(...
  obstacleList, poses, centers, radius, Exhaustive=true, ObstacleRadius=obstacleRadius);

% Visualize
  show(map); hold on
  h(1) = scatter(poses(:,1), poses(:,2), 'filled', DisplayName='poses');
% Plot collision circles for all poses
  for i = 1:height(poses)
  collisionCircles = nav.algs.internal.transformSE2Poses(...
  [centers,zeros(height(centers),1)], poses(i,:));
  for j = 1:height(collisionCircles)
  rectangle('Position',[collisionCircles(j,1)-radius,....
  collisionCircles(j,2)-radius,...
  2*radius, 2*radius],...
  'Curvature',[1,1], 'EdgeColor','r', 'LineWidth',2);
  scatter(collisionCircles(j,1), collisionCircles(j,2), 'filled', 'o', MarkerFaceColor='b')
  end
  end
% Plot pairs of nearest collision circles and obstacle points
  nearestCircles = witnessPoints(:,1:2);
  obst = witnessPoints(:,3:4);
  h(2) = scatter(nearestCircles(:,1), nearestCircles(:,2), 20, 'filled', 'd', DisplayName='nearest robot circles');
  h(3) = scatter(obst(:,1), obst(:,2), 'filled', DisplayName='nearest obstacles');
  quiver(nearestCircles(:,1), nearestCircles(:,2),...
  obst(:,1)-nearestCircles(:,1), obst(:,2)-nearestCircles(:,2),...
  0, Color=[0.5,0.5,0.5])
  legend(h, Location='best')
  hold off
%}

% Copyright 2024 The MathWorks, Inc.

%#codegen


    arguments
        obstacles {mustBeA(obstacles, {'double','signedDistanceMap'})}
        poses (:,3) double
        centers (:,2) double = [0,0]
        radius (1,1) double = 0
        options.Exhaustive = false
        options.ObstacleRadius = 0
    end

    if isa(obstacles, 'signedDistanceMap')
        if radius > 0
            % When the robot is approximated by a set of collision circles
            [distance, varargout{1:nargout-2}] = distToObstacleSDF(obstacles, poses, centers, radius);
        else
            % When the robot is just a point
            [distance, varargout{1:nargout-2}] = distToObstacleSDFForPointRobot(obstacles, poses);
        end
    else

        if ~options.Exhaustive
            if radius > 0
                % When the robot is approximated by a set of collision circles
                [distance, varargout{1:nargout-2}] = distToObstacleList(obstacles, poses, centers, radius, options);
            else
                % When the robot is just a point
                [distance, varargout{1:nargout-2}] = distToObstacleListForPointRobot(obstacles, poses, options);
            end
        else
            if radius > 0
                % When the robot is approximated by a set of collision circles
                [distance, varargout{1:nargout-2}] = distToObstacleListExhaustive(obstacles, poses, centers, radius, options);
            else
                % When the robot is just a point
                [distance, varargout{1:nargout-2}] = distToObstacleListForPointRobotExhaustive(obstacles, poses, options);
            end
        end
    end

    % Compute output flag indicating if the poses are in collision with
    % obstacles
    isColliding = distance<=0;

end


function [dist, witnessPoints] = distToObstacleSDF(map, poses, centers, radius)
%Compute distance from robot poses to obstacle SDF, where the vehicle
%geometry is represented with a set of collision circles

    numPoses = height(poses);
    numCircles = height(centers);

    % Transform the collision circle poses w.r.t input robot poses
    centers = [centers, zeros(height(centers),1)]; % [numCircles, 3]
    centersTr = centers(:,:,ones(numPoses,1));    %[numCircles, 3, numPoses]
    centersTr = nav.algs.internal.transformSE2Poses(centersTr, poses);
    centersTr = reshape(permute(centersTr, [3,1,2]),... %[numPoses, numCircles, 3]
                        [], 3);    %[numPoses*numCircles, 3]

    % Compute distance to the nearest obstacles
    dist = map.distance(centersTr(:,1:2))-radius;
    dist = reshape(dist, numPoses, numCircles);
    [~, ind] = min(dist,[],2,'linear');
    dist = dist(ind(:));

    % Get the location of nearest obstacles from the path poses
    if nargout > 1

        boundary = reshape(map.closestBoundary(squeeze(centersTr(:,1:2))),...
                           numPoses, numCircles, 2);
        obstNearest = zeros(numPoses, 2);
        obstNearest(:,1) = boundary(ind + (0 * numPoses * numCircles));
        obstNearest(:,2) = boundary(ind + (1 * numPoses * numCircles));

        centersTr = reshape(centersTr(:,1:2), numPoses, numCircles, 2);
        centersNearest = zeros(numPoses, 2);
        centersNearest(:,1) = centersTr(ind + (0 * numPoses * numCircles));
        centersNearest(:,2) = centersTr(ind + (1 * numPoses * numCircles));
        witnessPoints = [centersNearest, obstNearest];
    end

end

function [dist, witnessPoints] = distToObstacleSDFForPointRobot(map, poses)
%Compute distance from robot poses to obstacle SDF, where the vehicle
%geometry is represented with a point

    dist = map.distance(poses(:,1:2));
    if nargout > 1
        numPoses = height(poses);
        boundary = map.closestBoundary(poses(:,1:2));
        obstNearest = reshape(boundary, numPoses, 2);
        witnessPoints = [poses(:,1:2), obstNearest];
    end
end


function [dist, witnessPoints] = distToObstacleList(obstacles, poses, centers, radius, options)
%Compute one-to-one distances between poses and obstacle list, where the
%vehicle geometry is approximated by collision circles

    arguments
        obstacles (:,2)
        poses
        centers  % [numCircles, 2]
        radius
        options
    end

    numPoses = height(poses);
    numCircles = height(centers);

    % Transform the collision circle poses w.r.t input robot poses
    centers = [centers, zeros(height(centers),1)];
    centersTr = centers(:,:,ones(numPoses,1));    % [numCircles, 3, numPoses]
    centersTr = nav.algs.internal.transformSE2Poses(centersTr, poses);

    obsXYTr = permute(...
        obstacles(:,:,ones(numCircles,1)),...    % [numPoses, 2, numCircles]
        [3,2,1]);                                % [numCircles, 2, numPoses]

    distCircles = reshape(...
        vecnormk(centersTr(:,1:2,:)-obsXYTr, 2),...
        numCircles, numPoses); % [numCircles, numPoses]
    distCircles =  distCircles-radius-options.ObstacleRadius;
    distCircles(distCircles<0) = 0; % distance set to zero for colliding poses

    % Find distances from the nearest collision circles
    [~, ind] = min(distCircles, [], 1, 'linear');
    dist = distCircles(ind);
    dist = dist(:);

    if nargout > 1
        centerx = reshape(centersTr(:,1,:),numCircles,numPoses);
        centery = reshape(centersTr(:,2,:),numCircles,numPoses);
        nearestCenters = [centerx(ind(:)), centery(ind(:))]; % [numPoses, 2]
        witnessPoints = [nearestCenters, obstacles];
    end
end

function [dist, witnessPoints] = distToObstacleListForPointRobot(obstacles, poses, options)
%Compute one-to-one distances between poses and obstacle list, where the
%vehicle geometry is approximated by a point

    arguments
        obstacles (:,2)
        poses
        options
    end

    dist = vecnormk(poses(:,1:2)-obstacles, 2)-options.ObstacleRadius;
    dist(dist<0) = 0; % distance set to zero for colliding poses
    witnessPoints = [poses(:,1:2), obstacles];
end


function [dist, witnessPoints] = distToObstacleListExhaustive(obstacles, poses, centers, radius, options)
%Compute closest distances by evaluating all combinations of poses and
%obstacles, where the vehicle geometry is approximated by collision circles

    arguments
        obstacles (:,2)
        poses
        centers
        radius
        options
    end

    numPoses = height(poses);
    numCircles = height(centers);
    numObst = height(obstacles);

    % Get collision circle centers for the vehicle poses
    centers = [centers, zeros(height(centers),1)];
    centersTr = centers(:,:,ones(numPoses,1));  % [numCircles x 3 x numPoses]
    centersTr = nav.algs.internal.transformSE2Poses(centersTr, poses);  % [numCircles x 3 x numPoses]
    centersTr = reshape(centersTr(:,1:2,:), 1, numCircles, 2, numPoses); % [1 x numCircles x 3 x numPoses]

    obstaclesTr = reshape(obstacles, numObst, 1, 2); % [numObst x 1 x 2]

    % Compute distances between collision circles and obstacles
    distVectors = centersTr - obstaclesTr; % [1 x numCircles x 2 x numPoses] - [numObst x 1 x 2 x 1] -> [numObst x numCircles x 2 x numPoses]
    dist = vecnormk(distVectors, 3); % [numObst x numCircles x 1 x numPoses]
    dist = reshape(dist, numObst, numCircles, numPoses); % [numObst x numCircles x numPoses]
    dist = dist - radius - options.ObstacleRadius;
    dist(dist<0) = 0; % distance set to zero for colliding poses
    [~, ind] = min(dist, [], [1,2], 'linear'); % [1 x 1 x numPoses]
    dist = dist(ind(:)); % [numPoses x 1]

    if nargout > 1
        % Optional output containing the pairs of robot poses and corresponding
        % obstacle locations
        centersTr = repmat(centersTr, [numObst, 1, 1, 1]);
        obstaclesTr = repmat(obstaclesTr, [1, numCircles, 1, numPoses]);
        centersX = reshape(centersTr(:,:,1,:), [numObst, numCircles, numPoses]);
        centersY = reshape(centersTr(:,:,2,:), [numObst, numCircles, numPoses]);
        obstaclesX = reshape(obstaclesTr(:,:,1,:), [numObst, numCircles, numPoses]);
        obstaclesY = reshape(obstaclesTr(:,:,2,:), [numObst, numCircles, numPoses]);
        witnessPoints = [centersX(ind(:)), centersY(ind(:)), obstaclesX(ind(:)), obstaclesY(ind(:))];
        inCollision = dist==0;
        witnessPoints(inCollision,:) = nan;
    end

end


function [dist, witnessPoints] = distToObstacleListForPointRobotExhaustive(obstacles, poses, options)
%Compute closest distances by evaluating all combinations of poses and
%obstacles, where the vehicle geometry is approximated by a point
    arguments
        obstacles (:,2)
        poses
        options
    end

    numPoses = height(poses);

    posesTr = reshape(transpose(poses(:,1:2)), 1, 2, numPoses); % [1 x 2 x numPoses]
    distVectors = obstacles - posesTr; % [numObstacles x 2 X 1] - [1 x 2 x numPoses] -> [numObstacles x 2 x numPoses]
    dist = vecnormk(distVectors, 2) - options.ObstacleRadius; % [numObstacles x 1 x numPoses]
    dist(dist<0) = 0; % distance set to zero for colliding poses
    [~, ind] = min(dist, [], 1, 'linear'); % [1 x 1 x numPoses]
    dist = dist(ind(:)); % [numPoses x 1]

    if nargout > 1
        % Optional output containing the pairs of robot poses and corresponding
        % obstacle locations
        obstaclesX = repmat(obstacles(:,1), [1, 1, numPoses]);
        obstaclesY = repmat(obstacles(:,2), [1, 1, numPoses]);
        witnessPoints = [poses(:,1:2), obstaclesX(ind(:)), obstaclesY(ind(:))]; %[numPoses x 4]
        inCollision = dist==0;
        witnessPoints(inCollision,:) = nan;
    end
end

function d = vecnormk(x, k)
% Alternative implementation of vecnorm(x,2,dim)

% vecnorm quite slow, next is sqrt(sum(x.^2,dim)), best found in
% experiments is sqrt(sum(x.*x,dim))
    d = sqrt(sum(x.*x, k));
end
