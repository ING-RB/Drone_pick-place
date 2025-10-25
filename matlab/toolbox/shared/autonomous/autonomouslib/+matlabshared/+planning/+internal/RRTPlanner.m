%RRTPlanner Core 2D RRT planner
%   The RRTPlanner class hold the core algorithm for the 2D RRT* path
%   planner.

% Copyright 2017-2018 The MathWorks, Inc.
classdef RRTPlanner < handle
%#codegen

    properties (SetAccess = protected)
        %Costmap
        %   An object of type vehicleCostmap
        Costmap

        %ConnectionMechanism
        %   An object of type matlabshared.planning.internal.ConnectionMechanism, can be
        %   matlabshared.planning.internal.DubinsConnectionMechanism,
        %   matlabshared.planning.internal.ReedsSheppConnectionMechanism.
        ConnectionMechanism

        %Sampler
        %   An object of type matlabshared.planning.internal.UniformPoseSampler.
        Sampler

        %Tree
        %   An object of type matlabshared.planning.internal.RRTTree
        Tree

        %StartPose
        %   [x,y,theta] start pose (theta in radians)
        StartPose

        %GoalPose
        %   [x,y,theta] goal pose (theta in radians)
        GoalPose
    end

    properties
        %GoalTolerance
        %   Tolerance towards goal pose as [xtol, ytol, thetatol].
        GoalTolerance

        %GoalBias
        %   Probability of selecting goal pose at each iteration.
        GoalBias

        %MinIterations
        %   Minimum number of iterations of exploration.
        MinIterations

        %MaxIterations
        %   Maximum number of iterations of exploration.
        MaxIterations

        %ApproximateSearch
        %   Flag for approximate search
        ApproximateSearch
    end


    %----------------------------------------------------------------------
    % Construction
    %----------------------------------------------------------------------
    methods
        %------------------------------------------------------------------
        function this = RRTPlanner(costmap, minIterations, maxIterations, ...
                                   goalTolerance, goalBias, connMethod, connDistance, ...
                                   minTurningRadius, numSteps, approxSearch)

            % Set costmap
            validateattributes(costmap, ...
                               {'matlabshared.planning.internal.MapInterface'}, ...
                               {'nonempty'}, 'RRTPlanner');
            this.Costmap = costmap;

            matlabshared.planning.internal.validation.errorIfNotConst(maxIterations, 'MaxIterations');
            matlabshared.planning.internal.validation.errorIfNotConst(connMethod, 'ConnectionMethod');
            matlabshared.planning.internal.validation.errorIfNotConst(approxSearch, 'ApproximateSearch');

            % Instantiate pose sampler
            this.Sampler = matlabshared.planning.internal.UniformPoseSampler(...
                this.Costmap);

            % Configure connection mechanism
            connMech = matlabshared.planning.internal.createConnectionMechanism(...
                connMethod, connDistance, minTurningRadius, numSteps);
            this.ConnectionMechanism = connMech;

            % Configure neighbor searcher with connection mechanism
            neighborSearcher = matlabshared.planning.internal.createNeighborSearcher(...
                approxSearch, connMech);

            this.MinIterations      = minIterations;
            this.MaxIterations      = coder.const(maxIterations);
            this.GoalTolerance      = goalTolerance;
            this.GoalBias           = goalBias;
            this.ApproximateSearch  = approxSearch;

            % Instantiate RRTTree with neighbor searcher
            % Use maxIterations + 1, since startPose is always added to the
            % tree.
            poseDim   = 3;
            precision = 'double';
            this.Tree = matlabshared.planning.internal.RRTTree(...
                poseDim, precision, neighborSearcher, maxIterations + 1);

            this.StartPose = coder.nullcopy(zeros(1, 3, precision));
            this.GoalPose  = coder.nullcopy(zeros(1, 3, precision));
        end
    end


    %----------------------------------------------------------------------
    % Configuration
    %----------------------------------------------------------------------
    methods
        %------------------------------------------------------------------
        function updateConnectionMethod(this, cmethod)

            connMech = matlabshared.planning.internal.createConnectionMechanism(...
                cmethod, this.ConnectionMechanism.ConnectionDistance, ...
                this.ConnectionMechanism.TurningRadius, ...
                this.ConnectionMechanism.NumSteps);

            this.ConnectionMechanism = connMech;

            this.Tree.configureConnectionMechanism(this.ConnectionMechanism);
        end

        %------------------------------------------------------------------
        function updateConnectionDistance(this, cdist)

            this.ConnectionMechanism.ConnectionDistance = cdist;
        end

        %------------------------------------------------------------------
        function updateConnectionSteps(this, numSteps)

            this.ConnectionMechanism.NumSteps = numSteps;
        end

        %------------------------------------------------------------------
        function updateTurningRadius(this, radius)

            this.ConnectionMechanism.TurningRadius = radius;
        end

        %------------------------------------------------------------------
        function updateApproxSearch(this, approxSearch)

            this.ApproximateSearch = approxSearch;
            this.Tree.configureNeighborSearcher(approxSearch, this.ConnectionMechanism);
        end

        %------------------------------------------------------------------
        function updateMaxIterations(this, maxIterations)

            this.MaxIterations = maxIterations;
            this.Tree.updateBufferSize(maxIterations);
        end
    end


    %----------------------------------------------------------------------
    % Planning
    %----------------------------------------------------------------------
    methods
        %------------------------------------------------------------------
        function varargout = planPath(this, startPose, goalPose)

            % Cache properties
            this.StartPose      = startPose;
            this.GoalPose       = goalPose;

            % Reset internal tree and sampler
            reset(this.Tree);
            reset(this.Sampler);

            % Re-initialize path properties
            plannedPath    = zeros(0,3);
            pathCost       = 0;
            goalNodes      = [];
            bestGoalNode   = [];
            bestCost       = inf;

            % Set up sampling
            this.Sampler.configureCollisionChecker();

            % Seed the root of the tree.
            this.Tree.addNode(startPose);

            maxIter = this.MaxIterations;
            for n = 1 : maxIter

                % Sample collision-free pose with goal biasing
                randPose = this.sampleCollisionFreeWithGoalBiasing();

                % Find nearest neighbor in tree
                [nearestPose, nearestId] = this.Tree.nearest(randPose);

                % Interpolate towards random pose
                [newPose, inCollision] = this.interpolate(nearestPose, randPose);

                if inCollision
                    continue;
                end

                % Find near neighbors to new pose
                [nearPoses, nearIds] = this.Tree.near(newPose);

                % Add new pose to tree
                newId = this.Tree.addNode(newPose);

                % Find minimum cost path to new pose.
                this.findMinCostPath(nearPoses, nearIds, ...
                                     nearestPose, nearestId, newPose, newId);

                % Rewire tree
                this.rewireTree(nearPoses, nearIds, newPose, newId);

                if this.inGoalRegion(newPose)

                    % Add Id to goals
                    goalNodes = [goalNodes newId]; %#ok<AGROW>

                    planCost = this.Tree.costTo(newId);

                    % Update best cost
                    if planCost < bestCost
                        bestGoalNode   = newId;
                        bestCost       = planCost;
                    end

                    if this.terminateExploration(n)
                        break;
                    end
                end
            end

            if ~isempty(goalNodes)

                % Find path through tree
                [path, cost] = this.Tree.shortestPathFromRoot(bestGoalNode, ...
                                                              goalNodes);

                plannedPath = this.Tree.Nodes(path,:);
                pathCost    = cost;
            end


            varargout{1} = plannedPath;

            if nargout>1
                varargout{2} = pathCost;
            end
        end
    end

    methods (Access = protected)
        %------------------------------------------------------------------
        function pose = sampleCollisionFreeWithGoalBiasing(this)

            if this.Sampler.sampleGoalBias() > this.GoalBias
                pose = this.Sampler.sampleCollisionFree();
            else
                pose = this.GoalPose;
            end
        end

        %------------------------------------------------------------------
        function [pose,inCollision] = interpolate(this, from, towards)

        % Interpolate along connection mechanism
            posesInterp = this.ConnectionMechanism.interpolate(from, towards);

            throwError = false;
            free = checkFreePoses(this.Costmap, posesInterp, throwError);

            % If any pose is outside the map or in collision, bail out.
            pose        = posesInterp(end,:);
            inCollision = ~all(free);
        end

        %------------------------------------------------------------------
        function findMinCostPath(this, nearPoses, nearIds, nearestPose, ...
                                 nearestId, newPose, newId)
            %findMinCostPath find the minimum cost path to newPose from
            %near neighbors nearPoses, and add this edge to the tree.

            % Use local variables to improve performance
            treeLocal = this.Tree;

            minCost = treeLocal.costTo(nearestId) + ...
                      this.ConnectionMechanism.distance(nearestPose, newPose);

            minCostId = nearestId;
            numNear   = numel(nearIds);
            maxDist   = this.ConnectionMechanism.ConnectionDistance;

            distances = this.ConnectionMechanism.distance(nearPoses, newPose);

            % For each near neighbor
            for n = 1 : numNear
                nearPose = nearPoses(n,:);
                nearId   = nearIds(n);
                nearCost = treeLocal.costTo(nearId) + distances(n);

                % Note: The call to interpolate is last to be evaluated. We
                % do this to enable delayed collision-checking.

                % If cost is lower, and distance is within connection
                % distance
                if nearCost < minCost && distances(n) <= maxDist

                    [~,inCollision] = this.interpolate(nearPose, newPose);

                    % If path is collision-free and in-bounds
                    if ~inCollision
                        minCost     = nearCost;
                        minCostId   = nearId;
                    end
                end
            end

            % Add edge for minimum cost path.
            treeLocal.addEdge(minCostId, newId);
        end

        %------------------------------------------------------------------
        function rewireTree(this, nearPoses, nearIds, newPose, newId)
        %rewireTree rewire tree so that cost to nearPose is more
        %optimal after newPose was added to the tree.

        % Use local variables to improve performance
            treeLocal = this.Tree;
            cellSize  = this.Costmap.CellSize;
            thetaTol  = this.GoalTolerance(3);

            newCost = treeLocal.costTo(newId);
            numNear = numel(nearIds);
            maxDist = this.ConnectionMechanism.ConnectionDistance;

            forwardDistances = this.ConnectionMechanism.distance(nearPoses, newPose);
            reverseDistances = this.ConnectionMechanism.distance(newPose, nearPoses);

            % For each neighbor
            for n = 1 : numNear
                nearPose = nearPoses(n,:);
                nearId   = nearIds(n);
                nearCost = treeLocal.costTo(nearId);

                newNearCost = newCost + reverseDistances(n);

                if newNearCost < nearCost ...                                   % Cost is lower
                        && forwardDistances(n) <= maxDist                       % Distance is within connection distance

                    [finalPose, inCollision] = this.interpolate(newPose, nearPose);

                    reachedNearPose = ~inCollision ...
                        && norm(finalPose(1:2)-nearPose(1:2)) ...
                        <= cellSize ...
                        && abs(matlabshared.planning.internal.angleUtilities.angdiff(...
                            finalPose(3), nearPose(3))) ...
                        <= thetaTol;

                    % Collision checking already completed
                    if reachedNearPose
                        % Replace parent pose
                        treeLocal.replaceParent(nearId, newId);
                    end
                end
            end
        end

        %------------------------------------------------------------------
        function TF = inGoalRegion(this, pose)

            goalPose   = this.GoalPose;
            goalTol    = this.GoalTolerance;

            TF = abs(pose(1)-goalPose(1)) <= goalTol(1) ...             % x in goal
                 && abs(pose(2)-goalPose(2)) <= goalTol(2) ...           % && y in goal
                 && abs(matlabshared.planning.internal.angleUtilities.angdiff(...
                     pose(3),goalPose(3))) <= goalTol(3);                    % && theta in goal
        end

        %------------------------------------------------------------------
        function TF = terminateExploration(this, numIter)

            TF = numIter>= this.MinIterations;
        end
    end

    %----------------------------------------------------------------------
    % Code Generation
    %----------------------------------------------------------------------
    methods (Access = public, Static = true, Hidden = true)
        %------------------------------------------------------------------
        function props = matlabCodegenNonTunableProperties(~)

            props = {'Costmap', 'Sampler', 'Tree', 'MaxIterations'};
        end
    end
end
