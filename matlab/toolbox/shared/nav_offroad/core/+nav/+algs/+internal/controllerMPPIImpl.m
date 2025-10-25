classdef controllerMPPIImpl < nav.algs.internal.InternalAccess & nav.algs.internal.NavOffroadBase
% This class is for internal use only. It may be removed in the future.

%controllerMPPIImpl implements the step method of controllerMPPI.
%
% [1] G. Williams, P. Drews, B. Goldfain, J. M. Rehg and E. A. Theodorou,
% "Aggressive driving with model predictive path integral control," 2016
% IEEE International Conference on Robotics and Automation (ICRA),
% Stockholm, Sweden, 2016.

%   Copyright 2024 The MathWorks, Inc.

%#codegen
    properties (Access=?nav.algs.internal.InternalAccess)
        % ReferencePathInternal is the path output from the global planner
        % which the controller tries to follow closely.
        ReferencePathInternal


        % A function handle to the cost function used by MPPI, which
        % evaluates the cost associated with a given trajectory.
        CostFcn

        % Cost weights related to the default cost function.
        CostWeights

        % A structure containing configurable parameter
        Parameters

        % Struct with shape & dimension of vehicle for collision checking
        VehicleCollisionInformation

        % Safety margin to maintain from obstacles.
        ObstacleSafetyMargin

        %LookAheadDistance Distance from current robot pose till where
        % controller outputs velocity commands.
        LookaheadDistance = 10

        % Stores object of trajectoryGeneratorMPPI class for trajectory generation
        TrajectoryGeneratorObj

        % RefPathIdxCloseToRobot is the index in the reference path where robot is
        % closest to.
        % Default 1
        RefPathIdxCloseToRobot = 1

        %   This value controls the selectiveness of the controller in
        %   choosing trajectories based on their computed costs. A value
        %   close to 0 makes the controller highly selective, favoring
        %   the trajectory with the lowest cost and thus focusing on the most
        %   optimal control action. Conversely, very large values reduce the
        %   influence of cost differences among trajectories, leading to a
        %   behavior where the controller essentially averages all sampled
        %   trajectories, disregarding their individual costs. Tuning this
        %   parameter allows for a strategic balance between prioritizing
        %   optimal trajectories and ensuring a smoother, more averaged
        %   control output by taking into account a wider range of possible
        %   trajectories.
        Lambda = 1000

        % Allowed tolerance from waypoints while following reference path
        WaypointTolerance = [0.3 0.3 0.1];

        % GoalTolerance define the allowed tolerance to declare vehicle
        % reached goal.
        GoalToleranceInternal

        % LookaheadTimeInternal time for path following (s)
        LookaheadTimeInternal = 4;

        % Maximum allowed forward velocity for vehicle
        MaxForwardVelocity

        % Maximum allowed reverse velocity for vehicle
        MaxReverseVelocity
    end
    properties(Access=public,Hidden)
        % Extracted poses from RefPath based on lookahead distance
        LookaheadPoses

        LookaheadEndPose

        PrevOptTrajControls
    end
    properties(Access=private)
        FilterOrder
    end

    properties(Access=private,Dependent)
        FilterWindowSize
    end

    methods
        function value = get.FilterWindowSize(obj)
        % Window Size must be integer & odd. Window length should cover
        % whole trajectory.
            if mod(obj.TrajectoryGeneratorObj.NumTrajectoryStates,2)==0
                value = obj.TrajectoryGeneratorObj.NumTrajectoryStates-1;
            else
                value = obj.TrajectoryGeneratorObj.NumTrajectoryStates;
            end
        end
    end

    methods(Access=?nav.algs.internal.InternalAccess)
        function obj = controllerMPPIImpl(refPath,nv)
        %CONTROLLERMPPIIMPL Construct an instance of this class
        %   This class implements MPPI algorithm
            arguments
                refPath
                nv.Map = binaryOccupancyMap()
                nv.VehicleModel = bicycleKinematics;
            end
            obj.ReferencePathInternal = refPath;
            obj.TrajectoryGeneratorObj = nav.algs.internal.trajectoryGeneratorMPPI(VehicleModel=nv.VehicleModel);
            obj.PrevOptTrajControls = zeros(obj.TrajectoryGeneratorObj.NumTrajectoryStates,obj.TrajectoryGeneratorObj.NumVehicleInputs);
            obj.CostWeights =  struct( 'ObstacleRepulsion', 200, 'PathAlignment', 1,'ControlSmoothing', 1, 'PathFollowing', 1);
            obj.VehicleCollisionInformation = struct('Dimension',[1 1],"Shape","Rectangle");
            obj.FilterOrder = 3;
        end
    end

    methods(Access=protected)

        function [optTrajControlsFiltered,optimalTrajectory,extraInfo] = stepImpl(obj,curpose,curVel)

        % Initialize ExtraInfo with default values. These return in
        % case the code which is supposed to change is not reached.
            extraInfo = struct('Trajectories',nan,'ControlSequences',nan,...
                               "LookaheadPoses",nan, "HasReachedGoal", false, ...
                               "ExitFlag", 0);
            exitFlags = struct("ValidTraj",0,"InvalidTraj",1,"FarFromRefPath",2);


            % Check If vehicle has reached Goal.
            goal = obj.ReferencePathInternal(end,:);
            reachedGoal = hasReachedGoal(obj, curpose, goal);
            if reachedGoal
                % controls, TimeStamps, path are already set during initialization
                optTrajControlsFiltered = zeros(obj.TrajectoryGeneratorObj.NumTrajectoryStates,...
                                                obj.TrajectoryGeneratorObj.NumVehicleInputs);
                optimalTrajectory = repmat(goal,obj.TrajectoryGeneratorObj.NumTrajectoryStates,1);
                extraInfo.HasReachedGoal = true;
                extraInfo.ExitFlag = exitFlags.ValidTraj;
                return;
            end


            %% Path Following Information Processing
            % Extract LookaheadEndPose & LookAheadPoses from Reference Path
            [lookaheadPoses,updatedIdxCloseToRobot,farFromReferencePath,~] = findLookaheadPoses(obj,curpose); % lookaheadPoses to align
            if farFromReferencePath
                % Indicates the robot is more than look ahead distance
                % from the nearest pose in the global path. The recommended
                % next action is to find a new global path and then use that
                % path in the controller for path following.
                optTrajControlsFiltered = zeros(obj.TrajectoryGeneratorObj.NumTrajectoryStates,...
                                                obj.TrajectoryGeneratorObj.NumVehicleInputs);
                optimalTrajectory = repmat(curpose,obj.TrajectoryGeneratorObj.NumTrajectoryStates,1);
                extraInfo.ExitFlag = exitFlags.FarFromRefPath;
                return;
            end
            obj.RefPathIdxCloseToRobot = updatedIdxCloseToRobot;
            obj.LookaheadEndPose = lookaheadPoses(end,:);
            obj.LookaheadPoses = lookaheadPoses;

            %% MPPI based trajectory generation
            [trajectories,controlSequences] = generate(obj.TrajectoryGeneratorObj,curpose,curVel,obj.PrevOptTrajControls);


            %% Cost Computation
            % Codegen does not allow redefinition of function handles once
            % initialized. For codegen, CostSettings.CostFcn can be defined
            % only once either through constructor or property setter. If
            % the user input is not provided the nav.algs.internal.defaultCost
            % will be used for optimization.
            if ~coder.internal.is_defined(obj.CostFcn)
                obj.CostFcn =  @nav.algs.mppi.defaultCost;
            end
            costVector = obj.CostFcn(trajectories, controlSequences, obj);

            % Check for trajectory in collision
            inCollision = obj.checkCollision(trajectories,obj.Map,obj.ObstacleSafetyMargin,obj.VehicleCollisionInformation);
            penaltyVector = zeros(size(inCollision));
            penaltyVector(inCollision) = Inf;

            %% MPPI based trajectory evaluation
            [optTrajControls,isTrajectoryValid] = nav.algs.internal.trajectoryEvaluatorMPPI(controlSequences,obj.PrevOptTrajControls,costVector,penaltyVector,obj.Lambda);


            %% MPPI based Control Commands Smoothing

            % Do smoothing only if trajectory is valid.
            if isTrajectoryValid
                if obj.FilterOrder<obj.FilterWindowSize-1
                    optTrajControlsFiltered = controlSmoothingMPPI(optTrajControls,obj.FilterOrder,obj.FilterWindowSize);
                else
                    optTrajControlsFiltered = optTrajControls;
                end
            else
                optTrajControlsFiltered = optTrajControls;
            end
            obj.PrevOptTrajControls = [optTrajControlsFiltered(2:end,:);zeros(1,obj.TrajectoryGeneratorObj.NumVehicleInputs)];

            %% Post Processing Information
            % Compute Optimal Trajectory for visualization
            optimalTrajectory = zeros(size(optTrajControlsFiltered,1),obj.TrajectoryGeneratorObj.NumVehicleStates);
            optimalTrajectory(1,:) = curpose;
            for step = 2:size(optTrajControlsFiltered,1)
                optimalTrajectory(step,:) = optimalTrajectory(step-1,:) +...
                    obj.TrajectoryGeneratorObj.VehicleModel.derivative(optimalTrajectory(step-1,:),optTrajControlsFiltered(step-1,:))'*obj.TrajectoryGeneratorObj.SampleTime;
            end

            % Verify whether the optimal trajectory is in collision, since
            % averaging controls from valid trajectories could potentially
            % yield invalid controls.
            if isTrajectoryValid
                inCollision = obj.checkCollision(optimalTrajectory,obj.Map,obj.ObstacleSafetyMargin,obj.VehicleCollisionInformation);
                isTrajectoryValid = ~inCollision(1,1);
            end

            extraInfo.Trajectories = trajectories;
            extraInfo.ControlSequences = controlSequences;
            extraInfo.LookaheadPoses = lookaheadPoses;
            if isTrajectoryValid
                extraInfo.ExitFlag = exitFlags.ValidTraj;
            else
                extraInfo.ExitFlag = exitFlags.InvalidTraj;
            end
        end
    end

    methods(Access=private)
        %% Utility

        function reachedGoal = hasReachedGoal(obj, curpose, goal)
        % When the vehicle is close to the goal, check the distance
        % from the current vehicle pose to the goal pose.
        % If it is less than threshold (GoalToleranceInternal) then goal is
        % reached and hence return with commands that lead to no action.
            angleDiff = abs(robotics.internal.wrapToPi(goal(1,3) - ...
                                                       curpose(1,3)));
            withinXTol = abs(curpose(1)-goal(1)) < obj.GoalToleranceInternal(1);
            withinYTol = abs(curpose(2)-goal(2)) < obj.GoalToleranceInternal(2);
            withinAngleTol = angleDiff < obj.GoalToleranceInternal(3);
            reachedGoal = false;
            if withinXTol && withinYTol && withinAngleTol
                reachedGoal = true;
            end
        end

        %% Reference Path

        function [lookaheadPoses,updatedIdxCloseToRobot,isFarFromReferencePath,isGoalAtLookaheadDistance] = findLookaheadPoses(obj,currentRobotPose)
        % Given reference path, current robot pose & look ahead distance, function
        % outputs the way-point at look ahead distance on reference path.

        % Initialize variables
            waypointToleranceX = obj.WaypointTolerance(1);
            waypointToleranceY = obj.WaypointTolerance(2);
            waypointToleranceAngle = obj.WaypointTolerance(3);
            lookaheadPoses = [];
            referencePath = obj.ReferencePathInternal;
            idxCloseToRobot = obj.RefPathIdxCloseToRobot;
            lookaheadDistance = obj.LookaheadDistance;



            % Extract goal details
            goalIdx = size(referencePath,1);
            goal = referencePath(end,:);

            % Boolean variables/flags to be returned
            isFarFromReferencePath = false;
            isGoalAtLookaheadDistance = false;

            % Find the closest index in reference path to current robot pose
            [updatedIdxCloseToRobot,minDist] = obj.findClosestIndexToRobot(currentRobotPose, referencePath,idxCloseToRobot,waypointToleranceX,waypointToleranceY,waypointToleranceAngle);

            if minDist > obj.LookaheadDistance
                % Indicates the robot is more than look ahead distance
                % from the nearest pose in the global path. The recommended
                % next action is to find a new global path and then use that
                % path in the controller for path following.
                isFarFromReferencePath = true;
                return;
            end

            % Check if the index close to the robot is the index of the goal position.
            if updatedIdxCloseToRobot == goalIdx
                lookaheadPoses = goal;
                isGoalAtLookaheadDistance = true;
            else
                [lookaheadPoses, isGoalAtLookaheadDistance] = findLookAheadPath(lookaheadDistance, ...
                                                                                referencePath, currentRobotPose, goalIdx, updatedIdxCloseToRobot);

            end

        end


    end

    methods(Access=private,Static)
        function inCollision = checkCollision(trajectories,map,obstacleSafetyMargin,vehicleCollisionInformation)

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

            % Return inCollision flag as false for all trajectories if no obstacles
            if isa(map, 'binaryOccupancyMap') && isempty(obstacleList)
                inCollision = false(numTraj,1);
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
            % If the map type is binaryOccupancy map use obstacle list to
            % calculate distances, else use signed distance map to get distances.
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

            % Compute collision status (inCollision flag values)
            inCollision = dist<obstacleSafetyMargin;
        end

        function [idxCloseToRobot, minDist] = findClosestIndexToRobot(currentRobotPose,referencePath,idxCloseToRobot,waypointToleranceX,waypointToleranceY,waypointToleranceAngle)
        % findClosestIndexToRobot Find the index in reference path that is closest to the
        % current robot pose.

        % compute the distance from the current robot pose to each pose
        % in the referencePath. Also, From reference path consider only
        % pose near to current robot pose till goal.
            dists = poseToPathDist(currentRobotPose, referencePath(idxCloseToRobot:end,:));
            [minDist, idx] = min(dists);
            % Since idx is only computed on referencePath from current robot
            % position, add index close to robot(idxCloseToRobot) to minimum index
            idxCloseToRobot = idx + idxCloseToRobot-1;
            angleDiff = abs(robotics.internal.wrapToPi(referencePath(idxCloseToRobot,3) - currentRobotPose(3)));
            withinXTol = abs(currentRobotPose(1)-referencePath(idxCloseToRobot,1)) < waypointToleranceX;
            withinYTol = abs(currentRobotPose(2)-referencePath(idxCloseToRobot,2)) < waypointToleranceY;
            withinAngleTol = angleDiff < waypointToleranceAngle;
            if withinXTol && withinYTol && withinAngleTol
                idxCloseToRobot = idxCloseToRobot + 1;
            end
            idxCloseToRobot = min(idxCloseToRobot,size(referencePath,1)); % upper bound on idx

        end
    end
end

function d = poseToPathDist(pos, path)
% poseToPathDist find the euclidean distance from robot
% position POS to PATH
    posXY = pos(:,1:2);
    pathXY = path(:,1:2);
    poseToPathDiff = posXY-pathXY;
    d = sqrt(sum(poseToPathDiff.*poseToPathDiff,2));
end

function [lookaheadPoses,isGoalIncluded] = findLookAheadPath(lookaheadDistance, referencePath, currentRobotPose, ...
                                                             goalIdx, idxCloseToRobot)
% findLookAheadPath find the look ahead path based on the
% lookaheadDistance.
% lookaheadPoses contains poses in the global path starting with
% pose near to the current robot position till a pose on the global
% path where the  total path length is Look ahead distance.
% isGoalIncluded if true means the last pose in lookaheadPoses is
% the goal pose.

    isGoalIncluded = false;
    allPathAhead = [currentRobotPose(1:2); referencePath(idxCloseToRobot:end,1:2)];
    distAmongPoses = diff(allPathAhead);
    furtherDists = cumsum(vecnorm(distAmongPoses,2,2));

    %Choose the first idx at which distance is equal to
    %Look-ahead-Distance or greater
    idxCloseInFurtherDist = find(furtherDists >= lookaheadDistance, 1);

    if (isempty(idxCloseInFurtherDist))
        % If the index is empty means the goal position is
        % closer than the Look-Ahead-Distance. Hence assign
        % goal index as the index close to Look-Ahead-Distance.
        % This also means the robot is gong to stop, hence
        % assign the EndVelocity as zero.
        lookaheadPoses = [currentRobotPose(:,1:3); referencePath(idxCloseToRobot:goalIdx,:)];
        isGoalIncluded = true;
    else
        % Since idxCloseInFurtherDist also contain the index closest
        % to the robot, subtract 1.
        idxCloseToLookAheadDist = idxCloseToRobot + (idxCloseInFurtherDist-1);
        lookaheadPoses = [currentRobotPose(:,1:3); referencePath(idxCloseToRobot:idxCloseToLookAheadDist(1),:)];

        if furtherDists(idxCloseInFurtherDist) ~= lookaheadDistance
            lookaheadPoses = findExactPoseAtLookaheadDistance(lookaheadDistance, lookaheadPoses, furtherDists, ...
                                                              idxCloseInFurtherDist);
        end
    end
end

function lookaheadPoses = findExactPoseAtLookaheadDistance(lookaheadDistance, lookaheadPoses, furtherDists, ...
                                                           idxCloseInFurtherDist)
%findExactPoseAtLookaheadDistance Interpolate and find the exact pose
% in reference path that corresponds to look ahead distance.
    poseAfterLAD = lookaheadPoses(end,1:2);
    poseBeforeLAD = lookaheadPoses(end-1,1:2);
    % Find the unit vector connecting the pose in reference path that
    % is before and after look ahead distance
    vecJoiningPoses = poseAfterLAD - poseBeforeLAD;
    % Given a vector V connecting two points [x0 y0] and [x1 y1]
    % any point in the vector that is d distance far away from
    % [x0 y0] in the direction of the vector is [x0 y0] + d*V/norm(V)
    unitVec = vecJoiningPoses./norm(vecJoiningPoses);
    distFromPoseBeforeLAD = lookaheadDistance - furtherDists(idxCloseInFurtherDist-1);
    exactPoint = poseBeforeLAD + distFromPoseBeforeLAD.*unitVec;
    thetaAngle = atan2(unitVec(2), unitVec(1));
    % To handle reverse motion add pi to align the heading of interpolated pose with the
    % heading of the next pose
    if abs(angdiff(thetaAngle,lookaheadPoses(end,3))) > pi/2
        thetaAngle = robotics.internal.wrapToPi(thetaAngle + pi);
    end
    lookaheadPoses(end,:) = [exactPoint thetaAngle];
end

function filteredTrajectory =  controlSmoothingMPPI(trajectory,polynomialOrder,windowSize)
%controlSmoothingMPPI implements control signal smoothing from MPPI work.
%This filtering approach closely aligns with Savitzky–Golay filter.

% Input arguments
% windowSize: Must be integer & odd.
% polynomialOrder: Must be integer & order should be always <= windowSize-1

% Compute the Vandermonde matrix
    S = (-(windowSize-1)/2:(windowSize-1)/2)' .^ (0:polynomialOrder);

    % Compute QR decomposition
    [Q,~] = qr(S,0);

    % Compute the projection matrix B
    B = Q*Q';

    % Compute the transient on
    ybegin = B(end:-1:(windowSize-1)/2+2,:) * trajectory(windowSize:-1:1,:);

    % Compute the steady state output
    ycenter = filter(B((windowSize-1)./2+1,:), 1, trajectory);

    % Compute the transient off
    yend = B((windowSize-1)/2:-1:1,:) * trajectory(end:-1:end-(windowSize-1),:);

    % Concatenate
    filteredTrajectory = [ybegin; ycenter(windowSize:end,:); yend];

end
