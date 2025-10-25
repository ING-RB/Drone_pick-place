classdef controllerTEBImpl < handle & nav.algs.internal.InternalAccess
% This class is for internal use only. It may be removed in the future.

%controllerTEBImpl implements the step method of controllerTEB.
%
% [1] C. Rosmann, F. Hoffmann and T. Bertram: Kinodynamic Trajectory
% Optimization and Control for Car-Like Robots, IEEE/RSJ International
% Conference on Intelligent Robots and Systems (IROS), Vancouver, BC,
% Canada, Sept. 2017.

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

    properties(Access={?nav.algs.internal.InternalAccess,?nav.internal.validation.validateTEBParams})
        % GoalTolerance define the allowed tolerance to declare robot
        % reached goal. The first element represent the
        % allowed tolerance for distance between current robot pose and
        % goal pose. The second element represent the tolerance for difference in angle.
        GoalToleranceInternal = [0.1 0.1 0.1]; % In [meters meters radian]

        % ReferencePathInternal is the path output from the global planner
        % which the controller tries to follow closely.
        ReferencePathInternal

        % IdxCloseToRobot is the index in the reference path where robot is
        % closest to.
        % Default 1
        IdxCloseToRobot = 1

        %LookAheadDistance Distance from current robot pose till where
        % controller outputs velocity commands.
        LookAheadDistance

        % TEBParams is the parameter to be supplied to
        % TimedElasticBandCarGraph.
        TEBParams

        %SDFMap Signed distance map of the environment
        SDFMap

        % Radius of circle circumscribing cell in Map.
        CellHalfDiagLen        
    end

    properties(Access=protected)

        % For operations on path, e.g. interpolation to find first collision
        % violation
        StateSpace
    end

    properties(Access={?nav.algs.internal.InternalAccess,?nav.internal.validation.validateTEBParams})
        RobotCollisionCenters

        RobotCollisionRadius
    end

    methods
        function set.LookAheadDistance(obj, lad)
        %setter for LookAheadDistance property
            obj.LookAheadDistance = lad;
            setMaxPathStates(obj);
        end
    end

    methods(Hidden)

        function setMaxPathStates(obj)
        %setMaxPathStates set the default MaxPathStates value.
            options = obj.TEBParams;
            % The product of MaxVelocity and ReferenceDeltaTime gives the
            % maximum possible distance between two states in the optimized
            % path output. By dividing the max distance from LookAheadDistance
            % gives the least possible states. This is multiplied by 1.5 to
            % set a possible default maximum value for states.
            maxPathStates = 1.5*obj.LookAheadDistance/(options.MaxVelocity * options.ReferenceDeltaTime);
            obj.TEBParams.MaxPathStates = round(maxPathStates);
        end

        function obj = controllerTEBImpl(referencePath)
            % controllerTEBImpl constructor
            
            %Reference path is a matrix of mx3
            obj.ReferencePathInternal = referencePath;

            % Configure default parameter values for TEB
            options = nav.algs.internal.controllerTEBImpl.defaultParams();

            % Parameters for optimizeTEB represented as a struct.
            obj.TEBParams = options;
            % Default Look ahead distance = default Max linear velocity * Default look ahead time
            obj.LookAheadDistance = 4; % In meters

            obj.StateSpace = stateSpaceSE2;
            obj.StateSpace.StateBounds = [-inf inf; -inf inf; -pi pi];
            obj.StateSpace.SkipStateValidation = true;
        end

        function [velcmds, path, timestamps, extraInfo] = stepImplInternal(obj, currentRobotPose, sdfMap)
        % stepImpl compute velocity commands and optimal trajectory for subsequent time steps.

        % Initialize ExtraInfo with default values. These return in
        % case the code which is supposed to change is not reached.
            extraInfo = struct("HasReachedGoal", false, "TrajectoryCost", NaN, ...
                               "FarFromReferencePath", false, "PoseObstacleDist", [], "SolutionValid", false);

            % keeping the EndVelocity as NaN makes optimizePath skip the cost functions
            % that forces the robot to stop.
            obj.TEBParams.EndVelocity = NaN;
            velcmds = [0 0];
            path = currentRobotPose;
            timestamps = 0;

            referencePath = obj.ReferencePathInternal;
            goalIdx = size(referencePath,1);
            goal = referencePath(end,:);

            % When the robot is close to the goal, check the distance
            % from the current robot pose to the goal pose.
            % If it is less than threshold (GoalToleranceInternal) then goal is
            % reached and hence return with commands that lead to no action.
            angleDiff = abs(robotics.internal.wrapToPi(goal(1,3) - ...
                                                       currentRobotPose(1,3)));
            withinXTol = abs(currentRobotPose(1)-goal(1)) < obj.GoalToleranceInternal(1);
            withinYTol = abs(currentRobotPose(2)-goal(2)) < obj.GoalToleranceInternal(2);
            withinAngleTol = angleDiff < obj.GoalToleranceInternal(3);
            if withinXTol && withinYTol && withinAngleTol
                % velcmds, TimeStamps, path are already set during initialization
                extraInfo.HasReachedGoal = true;
                extraInfo.SolutionValid = true;
                return;
            end

            % Find the closest index in reference path to current robot
            % pose
            [idxCloseToRobot,minDist] = findClosestIndexToRobot(obj, currentRobotPose, referencePath);

            if minDist > obj.LookAheadDistance
                % Indicates the robot is more than look ahead distance
                % from the nearest pose in the global path. The recommended
                % next action is to find a new global path and then use that
                % path in the controller for path following.
                extraInfo.FarFromReferencePath = true;
                return;
            end

            % Check if the index close to the robot is the index of the
            % goal position.
            if idxCloseToRobot == goalIdx
                % If the robot is close to the goal position, it will be
                % going to stop and set the EndVelocity as zero.
                obj.TEBParams.EndVelocity = 0;
                obj.TEBParams.EndAngularVelocity = 0;
                % To call optimizeTEB we need 3 states as input, so have
                % the states as start, average(start,goal), and goal.
                middlePose = averagePose(currentRobotPose, goal);
                lookaheadPoses = [currentRobotPose; middlePose; goal];
            else
                [lookaheadPoses, isGoalIncluded] = findLookAheadPath(obj, ...
                                                                     referencePath, currentRobotPose, goalIdx, idxCloseToRobot);
                if isGoalIncluded
                    obj.TEBParams.EndVelocity = 0;
                end
            end
            numLookAheadPoints = size(lookaheadPoses,1);
            if numLookAheadPoints == 2
                % If the number of points is two, we linearly interpolate the path to
                % find another pose in the middle.
                middlePose = averagePose(lookaheadPoses(1,:), lookaheadPoses(2,:));
                lookaheadPoses = [lookaheadPoses(1,:); middlePose; lookaheadPoses(2,:)];
            end

            % call optimizeTEB and find an optimal path
            [velcmds, path, timestamps, ei] = stepImplTEB(obj, lookaheadPoses, ...
                                                          goal, sdfMap);

            extraInfo.TrajectoryCost = ei.Cost;
            extraInfo.PoseObstacleDist = ei.PoseObstacleDist;
            extraInfo.SolutionValid = ei.SolutionValid;
        end

        function updateCellHalfDiagLen(obj,mapResolution)
            if nargin == 1
                %Default map resolution is 1.
                obj.CellHalfDiagLen = 1/sqrt(2);
            else
                obj.CellHalfDiagLen = 1/(sqrt(2)*mapResolution);
            end
        end
    end

    methods(Access=?nav.algs.internal.InternalAccess)

        function extraInfo = processStepImplOutputs(...
            obj, curpath, velcmds, tstamps, extraInfoStepImpl, sdfMap)
        % 0. Preparation of violation detection
        % Last feasible index for all the violations supported as of
        % now. Index is the flag value.
        % 1 - collision
        % 2 - unsafe trajectory
        % 3 - Min turning radius violation
        % 4 - Neg deltaT
        % 5 - Reference path is farther than look ahead distance
            lastFeasibleIndices = inf(1,5);
            deltaT = diff(tstamps);

            % 1. Collision violation (obstacle jump)
            % Calculate the last index which doesn't go over obstacles.
            interval = obj.CellHalfDiagLen/sqrt(2); % Half of cell length
            for itr = 1:(height(curpath)-1)
                intermediatePoses = interpolate(obj.StateSpace, ...
                    curpath(itr,:), curpath(itr+1,:), ...
                    [0:interval:1 1]);
                colliding = nav.algs.internal.checkCollisionVehicleCircles(...
                    sdfMap, intermediatePoses,...
                    obj.RobotCollisionCenters, obj.RobotCollisionRadius);
                if any(colliding, "all")
                    lastFeasibleIndices(1) = itr;
                    break;
                end
            end
            

            % 2. Safe Trajectory violation
            pod = extraInfoStepImpl.PoseObstacleDist;
            if ~isempty(pod)
                unsafePoses = pod(:,3) < ...
                    (0.9*obj.TEBParams.ObstacleSafetyMargin)+obj.CellHalfDiagLen;
                % Row of First distance found to be violation
                violationRow = find(unsafePoses,1);
                if ~isempty(violationRow)
                    % First column in pod is the pose Id of the pose
                    % which violates safety margin. Subtract 1 to get the
                    % pose not in violation, that is last feasible pose.
                    lastFeasibleIndices(2) = pod(violationRow,1)-1;
                end
            end

            % 3. Sharp turn
            turnRadius = abs(velcmds(:,1)./velcmds(:,2));
            sharpTurn = turnRadius < 0.9*obj.TEBParams.MinTurningRadius;
            lfi = find(sharpTurn, 1);
            if ~isempty(lfi)
                lastFeasibleIndices(3) = lfi;
            end

            % 4. Negative DeltaT
            negDeltaT = deltaT < 0;
            lfi = find(negDeltaT, 1);
            if ~isempty(lfi)
                lastFeasibleIndices(4) = lfi; % first occurrence of negative deltaT
            end

            % 5. Far From Reference Path
            if extraInfoStepImpl.FarFromReferencePath
                % In this case there is no trajectory, hence only current
                % state is valid and it would trigger the no action
                % response.
                lastFeasibleIndices(5) = 1;
            end

            % end. Get the minimum index, that will correspond to first
            % violation.
            [lastFeasibleIdx, exitFlag] = min(lastFeasibleIndices);

            % Find the distance of all the poses from first pose along the optimized path
            % diff(X,1,1) ensures difference is always computed between consecutive poses.
            distFromStart = [0; cumsum(vecnorm(diff(curpath(:,1:2),1,1), 2, 2))];

            if extraInfoStepImpl.SolutionValid && lastFeasibleIdx >= height(tstamps)
                exitFlag = 0;
                lastFeasibleIdx = height(tstamps);
                % Rest of the outputs stay the same
            end

            extraInfo = struct(...
                "LastFeasibleIdx", lastFeasibleIdx, ...
                "DistanceFromStartPose", distFromStart, ...
                "HasReachedGoal", extraInfoStepImpl.HasReachedGoal, ...
                "TrajectoryCost", extraInfoStepImpl.TrajectoryCost, ...
                "ExitFlag", exitFlag);  
        end
    end

    methods(Access=private)

        function [idxCloseToRobot, minDist] = findClosestIndexToRobot(obj, ...
                                                                      currentRobotPose, referencePath)
        % findClosestIndexToRobot Find the index in reference path that is closest to the
        % current robot pose.

            idxCloseToRobot = obj.IdxCloseToRobot;

            % compute the distance from the current robot pose to each pose
            % in the referencePath. Also, From reference path consider only
            % pose near to current robot pose till goal.
            dists = poseToPathDist(currentRobotPose, referencePath(idxCloseToRobot:end,:));
            [minDist, idx] = min(dists);
            % Since idx is only computed on referencePath from current robot
            % position, add index close to robot(idxCloseToRobot) to minimum index
            obj.IdxCloseToRobot = idx;
            idxCloseToRobot = idx + idxCloseToRobot-1;
        end

        function [lookaheadPoses,isGoalIncluded] = findLookAheadPath(obj, referencePath, currentRobotPose, ...
                                                                     goalIdx, idxCloseToRobot)
        % findLookAheadPath find the look ahead path based on the
        % LookAheadDistance.
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
            idxCloseInFurtherDist = find(furtherDists >= obj.LookAheadDistance, 1);

            if (isempty(idxCloseInFurtherDist))
                % If the index is empty means the goal position is
                % closer than the Look-Ahead-Distance. Hence assign
                % goal index as the index close to Look-Ahead-Distance.
                % This also means the robot is gong to stop, hence
                % assign the EndVelocity as zero.
                lookaheadPoses = [currentRobotPose; referencePath(idxCloseToRobot:goalIdx,:)];
                isGoalIncluded = true;
            else
                % Since idxCloseInFurtherDist also contain the index closest
                % to the robot, subtract 1.
                idxCloseToLookAheadDist = idxCloseToRobot + (idxCloseInFurtherDist-1);
                lookaheadPoses = [currentRobotPose; referencePath(idxCloseToRobot:idxCloseToLookAheadDist(1),:)];

                if furtherDists(idxCloseInFurtherDist) ~= obj.LookAheadDistance
                    lookaheadPoses = findExactPoseAtLookAheadDistance(obj, lookaheadPoses, furtherDists, ...
                                                                      idxCloseInFurtherDist);
                end
            end
        end

        function lookaheadPoses = findExactPoseAtLookAheadDistance(obj, lookaheadPoses, furtherDists, ...
                                                                   idxCloseInFurtherDist)
        %findExactPoseAtLookAheadDistance Interpolate and find the exact pose
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
            distFromPoseBeforeLAD = obj.LookAheadDistance - furtherDists(idxCloseInFurtherDist-1);

            exactPoint = poseBeforeLAD + distFromPoseBeforeLAD.*unitVec;
            thetaAngle = atan2(unitVec(2), unitVec(1));
            % To handle reverse motion add pi to align the heading of interpolated pose with the
            % heading of the next pose
            if abs(angdiff(thetaAngle,lookaheadPoses(end,3))) > pi/2
                thetaAngle = robotics.internal.wrapToPi(thetaAngle + pi);
            end
            lookaheadPoses(end,:) = [exactPoint thetaAngle];
        end

        function [velcmds, path, timestamps, extraInfo] = stepImplTEB(obj, lookaheadPoints, ...
                                                                      goal, sdfMap)
        %stepImplTEB optimize the path using Timed Elastic Band.
        % It find a path avoiding the obstacles defined in obstaclelist and
        % adhering to soft constraints based on the parameters defined in Params

        % optimizeTEB takes an SE2 path as input and optimizes
        % it to reduce travel time while trying it's best to adhere to
        % other defined soft constraints.

            if coder.target("MATLAB")
                if ~isempty(sdfMap)
                    sdfMap = sdfMap.toStruct();
                else
                    sdfMap = [];
                end
                [optimizedPath, kinematicInfo, solnInfo] = ...
                    nav.algs.internal.mex.optimizeTEB(lookaheadPoints, ...
                                                      sdfMap, obj.TEBParams);
            else
                [optimizedPath, kinematicInfo, solnInfo] = ...
                    nav.algs.internal.impl.optimizeTEB(lookaheadPoints, ...
                                                       sdfMap, obj.TEBParams);
            end

            % Pass all the fields coming from TEB, add another field below
            extraInfo = solnInfo;

            % Check solution validity
            deltaT = diff(kinematicInfo.TimeStamps);
            soltionValid = all(deltaT>=0); % Could have more conditions

            % Add another field to info being passed to the caller
            extraInfo.SolutionValid = soltionValid;

            % Process Optimization output to get the velocity commands
            % Extract the linear and angular velocity.
            [vel, omega] = computeVelocity(obj, optimizedPath(1:end-1, :), ...
                                           optimizedPath(2:end, :), deltaT);
            % Saturate the linear and angular velocity to the maximum value
            % defined in options if it exceeds the maximum.
            [vel, omega, dt] = boundVelocity(obj, vel, omega, deltaT);

            if all(lookaheadPoints(end,:) == goal)
                % If Goal is less than lookahead distance far from robot then it should plan to
                % stop at the goal, hence appending 0 as velocity and omega for goal pose as the
                % last index
                vel = [vel; 0];
                omega = [omega; 0];
            else
                vel = [vel; vel(end)];
                omega = [omega; omega(end)];
            end

            % Assign the return values
            velcmds = [vel, omega];
            timestamps =  [0; cumsum(dt)];
            path = optimizedPath;

        end

        function [vxout, omegaout] = computeVelocity(obj, pose1, pose2, dt) %#ok<INUSD>
        %computeVelocity Extract the velocity from consecutive poses and a time
        % difference (including strafing velocity for holonomic robots)
        % The velocity is extracted using finite differences.
        % The direction of the translational velocity is also determined.
        %
        %Inputs:
        %   pose1       Pose at time k
        %   pose2       Consecutive pose at time k+1
        %   dt          Actual time difference between k and k+1 (must be >0 !!!)
        %
        %Outputs:
        %   vxout       Translational velocity
        %   omegaout    Rotational velocity
        %

            endidx = height(pose1);
            valididx = true(endidx,1);
            vxout = zeros(endidx,1);
            omegaout = zeros(endidx,1);
            negdt = any(dt <= 0);
            if negdt
                endidx = find(dt<=0,1);
                endidx = endidx(1); % This is done for codegen
                valididx(endidx+1:end) = 0;
            end
            % dk = [xk+1-xk;yk+1-yk], dk represented as deltaPose
            deltaPose = pose2(valididx, 1:2) - pose1(valididx, 1:2);

            % qk = [cosBetak; sinBetak]
            qk = [cos(pose1(valididx, 3)), sin(pose1(valididx, 3))];
            %translational velocity
            % gamma = sign(dot(qk,dk)), gamma represented as dir
            dir     = dot(deltaPose, qk, 2); % row wise dot product

            %vxout = (||dk||_2/deltaTk)*gamma(sk,sk+1) --- [1]
            %||dk||_2 represent l2-norm
            vxout(valididx) = sign(dir).*vecnorm(deltaPose, 2, 2)./dt(valididx);

            % Rotational Velocity
            % deltaBetak = betak+1 - betak
            orientDiff = wrapToPi(pose2(valididx, 3)-pose1(valididx, 3));
            % omegaout = deltaBetak/deltaT --- [1]
            omegaout(valididx) = orientDiff./dt(valididx);

        end

        function [vxout, omegaout, dt] = boundVelocity(obj, vel, omega, dt)
        % boundVelocity limit the linear and angular velocity to
        % MaxVelocity and MaxAngularVelocity.

        % Limit translational velocity for forward driving

            maxForwardLinVel = obj.TEBParams.MaxVelocity;
            if isnan(obj.TEBParams.MaxReverseVelocity)
                maxReverseLinVel = -maxForwardLinVel;
            else
                maxReverseLinVel = -obj.TEBParams.MaxReverseVelocity;
            end
            posVelIdx = vel(:,1) >= 0;

            ratioVel = ones(height(vel),1);
            posRatio = maxForwardLinVel./vel(posVelIdx,1);
            ratioVel(posVelIdx) = min(posRatio,1);
            negRatio = maxReverseLinVel./vel(~posVelIdx,1);
            ratioVel(~posVelIdx) = min(negRatio,1);

            % Limit angular velocity
            absOmega = abs(omega);
            ratioOmega = obj.TEBParams.MaxAngularVelocity ./ absOmega;
            ratioOmega = min(ratioOmega, 1);

            ratio = min(ratioVel, ratioOmega);
            vxout = vel.*ratio;
            omegaout = omega.*ratio;
            dt = dt./ratio;
        end


    end

    methods(Hidden, Static, Access=?nav.algs.internal.InternalAccess)
        function params = defaultParams()
        %DEFAULTPARAMS Creates the structure and sets the values to default for controllerTEB

        % TEB.
            params = nav.algs.internal.createTEBDefaultParams();

            % We will now change the values to what controllerTEB considers default.
            params.MaxPathStates = 200;
            params.ReferenceDeltaTime = .3;

            params.MaxVelocity = 0.8;
            params.MaxReverseVelocity = NaN;
            params.MaxAngularVelocity = 1.6;
            params.MaxAcceleration = 2.4;
            params.MaxAngularAcceleration = 4.8;
            params.MinTurningRadius = 0;

            params.RobotDimension = [1 .67];
            params.RobotType = 1;
            params.RobotFixedTransform = [0,0,0];

            % Parameters for solvers
            params.NumIteration = 2;
            params.MaxSolverIteration = 10;

            % Parameters for weights for cost function
            params.WeightTime = 10;
            params.WeightSmoothness = 1000;
            params.WeightForwardDrive = 10;
            params.WeightVelocity = 10;
            params.WeightAngularVelocity = 10;
            params.WeightAcceleration = 10;
            params.WeightAngularAcceleration = 10;
            params.WeightObstacles = 50;
            params.WeightMinTurningRadius = 100;

            % Parameters for obstacle
            params.ObstacleSafetyMargin = .5;
            params.ObstacleCutOffDistance = 5 * params.ObstacleSafetyMargin;
            params.ObstacleInclusionDistance = 1.5 * params.ObstacleSafetyMargin;

            % With this it will behave like optimizePath
            params.StartVelocity = 0;
            params.StartAngularVelocity = 0;
            params.EndVelocity = 0;
            params.EndAngularVelocity = 0;

        end
    end
end

function avgPose = averagePose(pose1, pose2)
%averagePose is a helper function to average two SE(2) poses.
%   Pose1 and Pose2 should be row vectors of length 3.
    avgPose = zeros(1, 3);
    avgPose(1:2) = (pose1(1:2) + pose2(1:2)) / 2;
    avgPose(3) = averageAngle(pose1(3), pose2(3));
end

function avgAngle = averageAngle(theta1, theta2)
%averageAngle is a helper function to compute average of two
%angles(orientation)

% Similar to what g2o does.
    x = cos(theta1) + cos(theta2);
    y = sin(theta1) + sin(theta2);

    avgAngle = atan2(y, x);

end

function d = poseToPathDist(pos, path)
% poseToPathDist find the euclidean distance from robot
% position POS to PATH
    posXY = pos(:,1:2);
    pathXY = path(:,1:2);

    numPoses = size(path,1);
    posMod = repmat(posXY,numPoses,1);
    d = vecnorm(posMod-pathXY,2,2);
end