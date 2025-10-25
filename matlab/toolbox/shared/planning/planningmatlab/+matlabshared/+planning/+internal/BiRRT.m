classdef BiRRT < nav.algs.internal.InternalAccess
%This class is for internal use only, and it maybe removed in the future.

%BIRRT Plan motion using bidirectional RRT
%   BIRRT object is a single-query planner that uses the
%   bidirectional Rapidly-Exploring Random Trees (RRT) algorithm
%   with an optional connect heuristic for increased speed.
%
%   The bidirectional RRT planner creates two trees with root nodes at the
%   specified start and goal states. To extend each tree, a random
%   configuration is generated and a step is taken from the nearest node
%   based on the MAXCONNECTIONDISTANCE property. The start and goal trees
%   alternate this extension process until both trees are connected. If the
%   connect heuristic is enabled, the extension process ignores
%   MAXCONNECTIONDISTANCE. Invalid configurations or connections that
%   collide with the environment are not added to the tree.
%
%   matlabshared.planning.internal.BiRRT(STATEVALIDATOR) creates a
%   bidirectional RRT planner from a state validator object, STATEVALIDATOR.
%
%   plannerBiRRT properties:
%       MaxConnectionDistance    - Maximum length between planned states
%       MaxIterations            - Maximum number of random states generated
%       EnableConnectHeuristic   - Directly join the start and goal trees
%
%   plannerBiRRT methods:
%       plan        - Plan motion from start to goal configuration

%   Copyright 2020-2023 The MathWorks, Inc.

%#codegen

    properties(Access = protected)
        %StateValidatorInternal State validator for the planner
        StateValidatorInternal

        %MaxNumTreeNodesInternal Maximally allowed number of nodes in both start and goal trees
        %   This number does not count the root nodes of both trees.
        %
        %   Default: 1e4
        MaxNumTreeNodesInternal
    end

    properties(Abstract, Access={?nav.algs.internal.InternalAccess})
        %StateSamplerFcnInternal State sampler function handle  
        StateSamplerFcnInternal
    end

    properties (Abstract)

        %EnableConnectHeuristic Connect two trees if it's enabled, otherwise try regular extend
        %
        %   Default: false
        EnableConnectHeuristic

        %MaxConnectionDistance Maximum length of a motion to be added to tree
        %
        %   Default: 0.1
        MaxConnectionDistance

        %MaxIterations Max number of iterations
        %   One iteration is grow both start tree and goal tree at most once, respectively
        %
        %   Default: 1e4
        MaxIterations
    end

    properties(Abstract, Access=protected)
        %GoalRegionInternal Goal region of the planner.
        %   The planner can choose to sample goal states from the goal region
        %   and add them to the goal tree. This enables planning to a goal region
        %   instead of a single goal state.
        GoalRegionInternal
    end

    properties(Access=protected)
        %GoalRegionBiasInternal Bias towards sampling goal states from goal region
        %   The bias determines the probability with which a goal state will be
        %   sampled from the goal region. The corresponding goal state will be
        %   added to the goal tree as a root node.
        %   NOTE: The goal tree is initialized with a NaN state which acts as a
        %   dummy root node. Adding a state to this root enables the planner to
        %   reach other goal states.
        %
        %   Default: 0.0
        GoalRegionBiasInternal
    end
    
    properties(Constant, Access = {?nav.algs.internal.InternalAccess})
        ExtendFailed = -1;
        ExtendSucceeded = 1;
        GoalReached = 1;
        MaxIterationsReached = 2;
        MaxNumTreeNodesReached = 3;
    end

    properties(Access = protected)
        %LimitMaxNumTreeNodes Set true for MaxNumTreeNodesInternal as exit criteria
        %
        %   Default: false
        LimitMaxNumTreeNodes
    end
    
    methods

        function obj = BiRRT(stateValidator)
        %BiRRT Constructor

            obj.StateValidatorInternal = stateValidator;
            obj.MaxConnectionDistance = 0.1;
            obj.EnableConnectHeuristic = false;
            obj.MaxIterations = 1e4;
            obj.GoalRegionBiasInternal = 0.0;
            obj.MaxNumTreeNodesInternal = 0;
            obj.LimitMaxNumTreeNodes = false;
        end

        function [path, solInfo, treeStart, treeGoal, numIters] = plan(obj, startState, goalState)
        %plan Bi-directional RRT plan routine
        %   PATH = plan(PLANNER, STARTSTATE, GOALSTATE) tries to find
        %   a valid path between STARTSTATE and GOALSTATE. The planning
        %   is carried out based on the underlying state space and state
        %   validator of PLANNER. The output, PATH, is returned as a
        %   R-by-N matrix, where R is the number of planned configurations
        %   in the path.
        %   The planner also allows adding a goal state from a goal region,
        %   and hence plan to multiple goal states. Setting the
        %   GoalRegionBiasInternal to 0 will only uniformly sample states in
        %   the state space to which both the trees will extend toward.
        %
        %   [PATH, SOLNINFO] = plan(PLANNER, ...) also returns a struct,
        %   SOLNINFO, as a second output that gives additional details
        %   regarding the planning solution.
        %   SOLNINFO has the following fields:
        %
        %      IsPathFound  : Boolean indicating if a path was found
        %
        %      ExitFlag     : A number indicating why the planner terminated
        %                     1 - 'GoalReached'
        %                     2 - 'MaxIterationsReached'
        %                     3 - 'MaxNumTreeNodesReached'
        %
        %   [PATH, SOLNINFO, TREESTART] = plan(PLANNER, ...) also returns
        %   TREESTART as third output that has details about start
        %   search tree as a nav.algs.internal.SearchTree object. This
        %   is useful to inspect the start tree, getting number of tree
        %   nodes.
        %
        %   [PATH, SOLNINFO, TREESTART TREEGOAL] = plan(PLANNER, ...)
        %   also returns TREEGOAL as fourth output that has details
        %   about goal search tree as a nav.algs.internal.SearchTree object.
        %   This is useful to inspect the goal tree, getting number of
        %   tree nodes.
        %
        %   [PATH, SOLNINFO, TREESTART TREEGOAL, NUMITERS] = plan(PLANNER, ...)
        %   also returns number of time Bidirectional RRT algorithm ran
        %   as NUMITERS.

            path = [];
            solInfo = struct("IsPathFound", false, ...
                             "ExitFlag", obj.MaxIterationsReached);

            %Initialize the start and the goal tree, as treeA and treeB,
            %respectively
            [treeA, treeB] = createSearchTrees(obj, startState, goalState);
            treeStart = treeA;
            treeGoal = treeB;
            numIters = 0;

            %Pre-populate the random configurations
            randState = obj.StateSamplerFcnInternal(obj.MaxIterations);            

            for k = 1 : obj.MaxIterations
                numIters = k;
                %If sampling happens in a goal region, then add the sampled
                %state to the goal tree. If uniform sampling happens in the
                %state space, perform the extend and connect routine with treeA
                %and treeB to the randomly sampled state
                randomNo = rand();
                if(obj.GoalRegionBiasInternal && (k == 1 || randomNo < obj.GoalRegionBiasInternal))
                    obj.addGoalState(treeGoal, obj.sampleFromGoalRegionAndProject());
                else
                    [statusB, qNewBId, qNewAId] = ...
                        obj.extendAndConnect(treeA, treeB, randState(k, :) );

                    if(statusB == obj.ExtendSucceeded)
                        [path, solInfo] = obj.createSolutionOnSuccess(...
                            treeA, treeB, qNewAId, qNewBId);
                        break;
                    end

                    %Check max number of tree nodes reached or not once
                    %added a node to treeA or treeB
                    if obj.isMaxNumTreeNodesReached(treeA, treeB)
                        solInfo.ExitFlag = obj.MaxNumTreeNodesReached;
                        break;
                    end

                    [treeA, treeB] = obj.swap(treeA, treeB);
                end
            end
            obj.cleanUp();
        end
    end

    methods (Abstract, Access=protected)
        %sampleFromGoalRegionAndProject Template method to sample a state from the goal region
        %   The Bi-directional RRT supports planning to a goal region. During
        %   plan, the planner can choose to add a goal state from the goal
        %   region to the goal tree, or extend to uniformly sampled state in the
        %   state space
        state = sampleFromGoalRegionAndProject(obj)
    end

    methods(Access = protected)

        function cname = getClassName(~)
        %getClassName Returns the name of the class
            cname = "BiRRT";
        end

        function cleanUp(obj)
        %cleanUp
            svInternal = obj.StateValidatorInternal;
            ssInternal = svInternal.StateSpace;
            switch class(ssInternal)
              case 'stateSpaceSE2'
                ssInternal.SkipStateValidation = false;
              case 'stateSpaceDubins'
                ssInternal.SkipStateValidation = false;
              case 'stateSpaceReedsShepp'
                ssInternal.SkipStateValidation = false;
              case 'manipulatorStateSpace'
                ssInternal.SkipStateValidation = false;
            end
            if isa(svInternal, 'validatorOccupancyMap') || ...
                    isa(svInternal, 'manipulatorCollisionBodyValidator')
                svInternal.SkipStateValidation = false;
            end
        end

        function [treeA, treeB] = createSearchTrees(obj, startState, goalState)
        %createSearchTrees Create two search trees with start and goal state

            maxNumNodes = obj.MaxNumTreeNodesInternal;
            if(~obj.LimitMaxNumTreeNodes)
                maxNumNodes = obj.MaxIterations + 1;
            end
            treeA = nav.algs.internal.SearchTree(startState, maxNumNodes);
            % If planning a path to a goal state, the root of the goal tree is
            % assigned as the goal state. If we are planning a path to a goal region
            % the root of the goal tree is assigned as a NAN state.
             
            len = size(startState,2);
            if obj.GoalRegionBiasInternal
                treeB = nav.algs.internal.SearchTree(nan(size(startState)), maxNumNodes+1);
            else
                % goalState size need to be explicitly mentioned due to codegen limitation 
                treeB = nav.algs.internal.SearchTree(goalState(1:len), maxNumNodes);
            end

            extendsReversely = true;
            svInternal = obj.StateValidatorInternal;
            ssInternal = svInternal.StateSpace;
            switch class(ssInternal)
              case 'stateSpaceSE2'
                weights = [ssInternal.WeightXY,...
                           ssInternal.WeightXY,...
                           ssInternal.WeightTheta];
                topologies = [0 0 1];
                treeA.configureCommonCSMetric(topologies, weights, ~extendsReversely);
                treeB.configureCommonCSMetric(topologies, weights, extendsReversely);
                ssInternal.SkipStateValidation = true;
              case 'stateSpaceDubins'
                treeA.configureDubinsMetric(ssInternal.MinTurningRadius, ~extendsReversely);
                treeB.configureDubinsMetric(ssInternal.MinTurningRadius, extendsReversely);
                ssInternal.SkipStateValidation = true;
              case 'stateSpaceReedsShepp'
                treeA.configureReedsSheppMetric(...
                    ssInternal.MinTurningRadius,...
                    ssInternal.ReverseCost, ~extendsReversely);
                treeB.configureReedsSheppMetric(...
                    ssInternal.MinTurningRadius,...
                    ssInternal.ReverseCost, extendsReversely);
                ssInternal.SkipStateValidation = true;
              case 'manipulatorStateSpace'
                ss = ssInternal;
                treeA.setCustomizedStateSpace(ss, ~extendsReversely);
                treeB.setCustomizedStateSpace(ss, extendsReversely);
                ssInternal.SkipStateValidation = true;
              otherwise
                ss = ssInternal;
                treeA.setCustomizedStateSpace(ss, ~extendsReversely);
                treeB.setCustomizedStateSpace(ss, extendsReversely);
            end
            if isa(svInternal, 'manipulatorCollisionBodyValidator')
                svInternal.SkipStateValidation = true;
            end

            if isa(svInternal, 'validatorOccupancyMap')
                svInternal.SkipStateValidation = true;
                svInternal.configureValidatorForFastOccupancyCheck();
            end
        end
    end

    methods(Access = {?nav.algs.internal.InternalAccess})

        function [status, qNew, qId] = extend(obj, tree, x, maxConnectionDistance)
        %extend Extends the input tree towards an input state
        %   [STATUS, QNEW, QID] = EXTEND(STATEVALIDATOR, TREE, X, MAXCONNECTIONDISTANCE)
        %   extends the input TREE (from the nearest neighbor of X in the
        %   TREE) towards the input state X within the distance of
        %   MAXCONNECTIONDISTANCE.
        %
        %   The output STATUS indicates if a new node was added. A new node  
        %   is added if the motion primitive between the new state, QNEW,
        %   is within the distance MAXCONNECTIONDISTANCE from its nearest 
        %   neighbor in the tree and is free of collision. If the STATUS is
        %   ExtendFailed, QID is set to -1.

            %Find the nearest neighbor of x in the tree
            nnId = tree.nearestNeighbor(x);
            qNN = tree.getNodeState(nnId);
            

            %Assume that it is not possible to add a new node in the TREE
            qId = -1;
            status = obj.ExtendFailed;

            % Extending a root node which is NaN is a failed extend, so return
            % early from this routine
            if((nnId == 0) && obj.isNaN(qNN))
                qNew = qNN;
                return;
            end

            % Find the distance between the nearest neighbor of X in the tree
            % Two situations here:
            % A) If the tree extends outward from the root, the distance is
            %    calculated from the nearest node on the tree (qNN) to the query
            %    state x.
            % B) If the tree extends inward to the root (i.e. goal tree
            %    case), the distance is calculated from the query state x
            %    to the nearest node found in the tree (qNN).
            if tree.extendsOutward
                dist = obj.StateValidatorInternal.StateSpace.distance(qNN, x);
            else
                dist = obj.StateValidatorInternal.StateSpace.distance(x, qNN);
            end
            
            if(isinf(maxConnectionDistance) || dist < maxConnectionDistance)
                qNew = x;
            else
                if tree.extendsOutward
                    qNew = obj.StateValidatorInternal.StateSpace.interpolate(...
                        qNN, x, maxConnectionDistance/dist);
                else
                    qNew = obj.StateValidatorInternal.StateSpace.interpolate(...
                        x, qNN, 1 - (maxConnectionDistance/dist));                    
                end
                % Making sure the interpolated output is a vector during run time.                
                coder.internal.assert(isvector(qNew), 'nav:navalgs:plannerrrt:InterpRowVector');
                % For codegen, making sure newState is a compile time row vector.
                qNew = reshape(qNew, 1, []);
            end

            %check whether the motion is valid.
            if tree.extendsOutward
                if(obj.StateValidatorInternal.isMotionValid(qNN, qNew))
                    qId = tree.insertNode(qNew, nnId);
                    status = obj.ExtendSucceeded;
                end
            else
                if(obj.StateValidatorInternal.isMotionValid(qNew, qNN))
                    qId = tree.insertNode(qNew, nnId);
                    status = obj.ExtendSucceeded;
                end
            end
            
        end
    end

    methods (Static, Access = {?nav.algs.internal.InternalAccess})

        function [treeB, treeA] = swap(treeA, treeB)
        %swap Swaps the two input trees
        end

        function joinedPath = retrievePath(treeStart, qStartId, treeGoal, qGoalId)
        %retrievePath Joins the two trees at their individual nodeIDs
        %   The function creates a path comprising of the root of the
        %   treeStart as the first state in joinedPath, and that of the
        %   treeGoal as the last. Assume that qStartId, and qGoalId, are
        %   valid IDs in the trees, and that they correspond to the
        %   same configuration.

            %Find the path from the respective nodes of the start and goal
            %trees to their root. Transpose them as the output is a column
            %vector.
            startPath = (treeStart.tracebackToRoot(qStartId))';
            goalPath = (treeGoal.tracebackToRoot(qGoalId))';

            %We need the root of the start tree as the first state, hence flip
            %it.
            flippedStartPath = flip(startPath, 1);

            %Stack the paths vertically.
            joinedPath = [flippedStartPath; goalPath(2:end, :)];
        end

    end
    methods(Static, Access = {?nav.algs.internal.InternalAccess})
        function isNanState = isNaN(state)
        %isNaN
            isNanState = all(isnan(state));
        end
    end
    methods(Access = {?nav.algs.internal.InternalAccess})
        function goalAdded = addGoalState(obj, treeGoal, goalState)
        %addGoalState Adds a goal state to the goal tree
            goalAdded = false;
            % A goal state to the root node should not be a NaN
            if(~obj.isNaN(goalState))
                treeGoal.insertNode(goalState, 0);
                goalAdded = true;
            end
        end
    end

    methods(Access = {?nav.algs.internal.InternalAccess})
        function [statusB, qNewBId, qNewAId] = extendAndConnect(obj, treeA, treeB, q)
        %extendAndConnect Extends treeA towards a state "q", and tries to 
        %   connect treeB to the newly added state in treeA.

            statusB = obj.ExtendFailed;
            qNewBId = -1;
            
            %Extend treeA towards "q"
            [statusA, qNewA, qNewAId] = extend(obj, treeA, q, obj.MaxConnectionDistance);

            %If the extension was successful, then extend treeB towards
            %the newly added node in treeA
            if(statusA == obj.ExtendSucceeded)

                %Check max number of tree nodes reached or not after adding
                %a new node to treeB
                if obj.isMaxNumTreeNodesReached(treeA, treeB)
                    return;
                end

                %Try to connect two trees if the heuristic is enabled,
                %otherwise try regular extend
                if(obj.EnableConnectHeuristic)
                    [statusB, ~, qNewBId] = extend(obj, treeB, qNewA, inf);
                else
                    [~, qNewB, qNewBId] = extend(obj, treeB, qNewA, obj.MaxConnectionDistance);

                    %If the newly added node is the same as the node the
                    %tree wants to extend to and the extension towards that node
                    %is valid, then the trees can be joined
                    if(isequaln(qNewB, qNewA) && (qNewBId ~= -1))
                        statusB = obj.ExtendSucceeded;
                    end
                end
            end
        end

        function [path, solInfo] = createSolutionOnSuccess(obj, treeA, treeB, qNewAId, qNewBId)
        %createSolutionOnSuccess Creates the path and the corresponding solInfo on success
        %   A successful solution means that the trees are joined at a common
        %   configuration
            if treeA.extendsOutward
                path = obj.retrievePath(treeA, qNewAId, treeB, qNewBId);
            else
                path = obj.retrievePath(treeB, qNewBId, treeA, qNewAId);
            end
            
            % The first configuration of the backward tree is a nan
            % state if we plan a path to a goal region
            if obj.GoalRegionBiasInternal
                path(end, :) = [];
            end

            %Populate the solution info
            solInfo.IsPathFound = true;
            solInfo.ExitFlag = obj.GoalReached;
        end

        function val = isMaxNumTreeNodesReached(obj, treeA, treeB)
        %isMaxNumTreeNodesReached Returns true if the total number of
        %   nodes excluding the root nodes and the goal node equals
        %   MaxNumTreeNodesInternal.
            if obj.GoalRegionBiasInternal
                val = obj.LimitMaxNumTreeNodes && ...
                      (treeA.getNumNodes()+treeB.getNumNodes()-3 == obj.MaxNumTreeNodesInternal);
            else
                val = obj.LimitMaxNumTreeNodes && ...
                      (treeA.getNumNodes()+treeB.getNumNodes()-2 == obj.MaxNumTreeNodesInternal);
            end
        end
    end
end
