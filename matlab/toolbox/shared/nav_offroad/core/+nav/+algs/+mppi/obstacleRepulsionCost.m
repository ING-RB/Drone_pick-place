function cost = obstacleRepulsionCost(trajectories,map,vehicleCollisionInformation)
%obstacleRepulsionCost Computes the repulsion cost for trajectories.
%
%   cost = nav.algs.mppi.obstacleRepulsionCost(trajectories, map,
%   vehicleCollisionInformation) uses a map to determine the distance of
%   each trajectory point from the nearest obstacle, and computes a
%   repulsion cost based on these distances.
%
%   Inputs:
%       trajectories                - A 3D array (NumStates x NumVehicleStates
%                                     x NumTrajectories) of generated
%                                     trajectories where NumStates is the
%                                     number of states along the trajectory
%                                     and each slice along the third
%                                     dimension corresponds to a single
%                                     trajectory.
%       map                         - A map object representing the
%                                     environment. Supported map types:
%                                     binaryOccupancyMap, occupancyMap and
%                                     signedDistanceMap.
%       vehicleCollisionInformation - struct with collision related
%                                     information about the vehicle, such
%                                     as dimensions and shape. Supported
%                                     shapes are point & rectangle.
%
%   Outputs:
%       cost                        - A column vector (NumTrajectories x 1)
%                                     where each element represents the
%                                     calculated repulsion cost for the
%                                     corresponding trajectory.
%
%   The obstacle repulsion cost for each trajectory is computed using an
%   exponential function of the minimum distance from any point in the
%   trajectory to the nearest obstacle. The repulsion cost increases as the
%   trajectory points get closer to obstacles.
%
%   Example:
%       % Define a signed distance field map of the environment
%       sdfMap = signedDistanceMap(mapmatrix);
%       % Define the obstacle safety margin
%       vehicleCollisionInformation = struct("Shape","Rectangle","Dimension",[1 1]),
%       % Compute repulsion cost and collision status for a set of trajectories
%       cost = nav.algs.mppi.obstacleRepulsionCost(trajectories, sdfMap, vehicleCollisionInformation);
%
%   See also controllerMPPI, pathAlignmentCost, controlSmoothingCost.

% Copyright 2024 The MathWorks, Inc.

%#codegen

    arguments
        trajectories double {isValidMatrixDimensions(trajectories)}
        map {mustBeA(map, {'occupancyMap', 'binaryOccupancyMap', 'signedDistanceMap'})}
        vehicleCollisionInformation (1,1) struct
    end

    numStates = size(trajectories,1); % number of states in each trajectory
    numVehicleStates = size(trajectories,2); % number of vehicle states
    numTraj = size(trajectories,3); % number of trajectories

    % Get obstacle list or signed distance map depending on the map type
    % binaryOccupancyMap will be used by Navigation & Robotics toolbox users,
    % so we convert it to obstacle coordinate list. Other map types are
    % converted in signedDistanceMap.
    if isa(map, 'binaryOccupancyMap')
        obstacleList = nav.algs.internal.extractObstacleList(map);
    elseif isa(map, 'occupancyMap')
        sdfMap = nav.algs.internal.extractSignedDistanceMap(map);
    else
        sdfMap = map;
    end

    % Return zero cost if no obstacles
    if isa(map, 'binaryOccupancyMap') && isempty(obstacleList)
        cost = zeros(numTraj,1);
        return
    end

    % Vehicle approximation with collision circles
    numCircles = 3; % Number of circles with which we approximate the vehicle
    [centers, radius] = nav.algs.internal.vehicleCirclesApproximation(vehicleCollisionInformation.Dimension, numCircles);

    % Obstacle grid cell approximation with circle
    cellLength = 1/map.Resolution;
    obstRadius = cellLength/sqrt(2);

    % Compute distance from vehicle collision circles to the obstacles.
    trajectories = reshape(permute(trajectories,[1,3,2]), [], numVehicleStates);
    if isa(map,'binaryOccupancyMap')
        [~, dist] = nav.algs.internal.checkCollisionVehicleCircles(obstacleList, trajectories(:,1:3), centers, radius,...
                                                                   Exhaustive=true, ObstacleRadius=obstRadius);
    else
        [~, dist] = nav.algs.internal.checkCollisionVehicleCircles(sdfMap, trajectories(:,1:3), centers, radius);
    end

    % Compute distance to nearest obstacle from each trajectory
    dist = reshape(dist, [numStates, numTraj]);
    dist = min(dist,[],1);
    dist = dist(:);

    % Compute cost and collision status
    cost = exp(-dist);
end

function isValidMatrixDimensions(matrix)

% Check the number of dimensions
    numDims = ndims(matrix);

    % Validate the number of dimensions
    coder.internal.errorIf(numDims~=3,'shared_nav_offroad:controllermppi:InvalidTrajectoriesDimension');
end
