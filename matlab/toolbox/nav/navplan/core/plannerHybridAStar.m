classdef plannerHybridAStar < nav.algs.internal.InternalAccess & ...
        matlabshared.autonomous.map.internal.InternalAccess&...
        matlabshared.tracking.internal.CustomDisplay
%

%   Copyright 2019-2024 The MathWorks, Inc.

%#codegen

    properties

        StateValidator;

        MinTurningRadius (1,1) {mustBeNumeric, mustBeFinite, mustBeReal, mustBePositive} = 1

        MotionPrimitiveLength (1,1) {mustBeNumeric, mustBeFinite, mustBeReal, mustBePositive} = 1

        NumMotionPrimitives (1,1) {mustBeNumeric, mustBeFinite, mustBeInteger, mustBeGreaterThanOrEqual(NumMotionPrimitives, 3), mustBeOdd(NumMotionPrimitives)} = 5;

        ForwardCost(1,1) {mustBeNumeric, mustBeFinite, mustBeReal, mustBeGreaterThanOrEqual(ForwardCost, 1)} = 1;

        ReverseCost(1,1) {mustBeNumeric, mustBeFinite, mustBeReal, mustBeGreaterThanOrEqual(ReverseCost, 1)} = 3;

        DirectionSwitchingCost(1,1) {mustBeNumeric, mustBeFinite, mustBeReal, mustBeNonnegative} = 0;

        AnalyticExpansionInterval(1,1) {mustBeNumeric, mustBeFinite, mustBeInteger, mustBePositive} = 5;

        InterpolationDistance(1,1) {mustBeNumeric, mustBeFinite, mustBeReal, mustBePositive} = 1.0;

    end

    % Custom cost functions
    properties(SetAccess=private)

        TransitionCostFcn

        AnalyticalExpansionCostFcn
    end

    % Properties related to input map and information related to it
    properties (Access = private)

        %Map Common variable to store all kind of supported maps
        Map;

        %Dimensions To store the dimensions of the input map
        Dimensions = zeros(1,2);

        %CellSize Square side length of each cell in world units
        CellSize;

        %CustomTransitionCostFlag Indicates whether or not custom
        % transition functions have been provided
        CustomTransitionCostFlag = 0;

        %CustomAECostFlag Indicates whether or not custom analytical
        % expansion functions have been provided.
        CustomAECostFlag = 0;

        %IsValidationDistanceInf Flag that is set to true if the state
        %validator's ValidationDistance is inf
        IsValidationDistanceInf = false

    end

    %Properties to implement DMA=OFF codegen
    properties (Access = private)

        %MaxSize to store Maximum possible size of arrays
        %   value is  Map.GridSize(1)*Map.GridSize(2)*NumMotionPrimitives;
        MaxSize;
    end

    % Properties related to nodes and their expansion in continuous space
    properties (Access = private)

        %VisitedCells To keep check on the cells which are been
        %traversed by the tree in forward and reverse motions.
        %
        %Its a struct with fields ForwardDir and ReverseDir and each of
        %these are logical arrays of shape [Map.GridSize(1), Map.GridSize(2)]
        VisitedCells

        %Heuristic2DObj Store DPGrid object that is used for computing
        %obstacle heuristic
        Heuristic2DObj;

        %Cost2D Store 2D path cost matrix for a given goal
        % =eps is the cost at goal
        % =inf is the cost at obstacle locations
        % =0 means the cost is not yet computed
        % >0 means the cost is already computed        
        Cost2D 

        %PathFound To store the state of the path completion
        PathFound;
    end

    % Properties related to analytic expansion
    properties (Access = private)

        %ExpansionPoint Point from where path is being expanded analytically
        ExpansionPoint;

        %AnalyticPathLength Length of the analytically expanded path
        AnalyticPathLength;

        %AnalyticPathSegments Length of each segment of the path
        AnalyticPathSegments;

        %AnalyticPathTypes Type of the expanded path
        AnalyticPathTypes;

        %ExpansionPointInd Index of the first analytical expansion point on
        %the final interpolated path
        ExpansionPointInd
    end

    % Properties related to show function
    properties (Access = private)

        %StartPose Start pose provided by user
        StartPose = nan(1,3);

        %GoalPose Goal pose provided by user
        GoalPose = nan(1,3);

        %NodeMap Node map data structure. Used during plotting the path and
        %motion primitives. Stored only when running in MATLAB (not during
        %code generation)
        NodeMap

        %PathNodeIdLast Stores the last id of the output path computed by
        %the A* search. This value is stored only when running in MATLAB
        %(not during code generation)
        PathNodeIdLast

        %NodeMapIdLast Stores the id of the last node stored in the nodeMap
        %data structure. This is a scalar value stored only for MATLAB
        %target for plotting purposes. This value is stored only when
        %running in MATLAB (not during code generation)
        NodeMapIdLast

    end


    %% Public methods
    methods

        function obj = plannerHybridAStar(validator, options)
            arguments
                validator
                options.MinTurningRadius
                options.MotionPrimitiveLength
                options.NumMotionPrimitives
                options.ForwardCost
                options.ReverseCost
                options.DirectionSwitchingCost
                options.AnalyticExpansionInterval
                options.InterpolationDistance
                options.TransitionCostFcn
                options.AnalyticalExpansionCostFcn
            end

            obj.StateValidator = validator;

            % Assigning values to the class properties
            obj.updateProperties(options);

            %Assign the MaxSize of arrays in case of DMA = OFF codegen
            obj.MaxSize = obj.Map.GridSize(1)*obj.Map.GridSize(2)*obj.NumMotionPrimitives;
        end

        function [pathObj, dirVals, solnInfo] = plan(obj, start, goal, options)
            arguments
                obj
                start (1,:) {validateStartGoal(obj,start,'start')}
                goal (1,:) {validateStartGoal(obj,goal,'goal')}
                options.SearchMode {validatestring(options.SearchMode, {'greedy', 'exhaustive'}, 'plan', 'SearchMode')}= 'greedy'
            end

            if coder.target('MATLAB')
                % To make sure that property is reset after plan method ended
                cleaner = onCleanup(@() obj.cleanUp);
            end

            if ~nav.algs.internal.staticMemoryAllocation()
                %Re Assign the MaxSize of arrays in case variable sizing is enabled
                obj.MaxSize = obj.Map.GridSize(1)*obj.Map.GridSize(2)*obj.NumMotionPrimitives;
            end

            % Storing start and goal positions after validation
            obj.StartPose = start;
            obj.GoalPose = goal;

            % Fetching map data
            getMapData(obj);

            % To reduce the calls for isStateValid method
            if isa(obj.StateValidator, 'validatorOccupancyMap')
                obj.StateValidator.SkipStateValidation = true;
                obj.StateValidator.configureValidatorForFastOccupancyCheck();
            end

            % Variable to check the path completion
            obj.PathFound = false;

            % Variable to track the node expansion per cell
            obj.VisitedCells = struct('ForwardDir', false(obj.Map.GridSize),...
                                      'ReverseDir', false(obj.Map.GridSize));

            if start == goal

                % set path as the start pose in case start/goal poses are the same
                pathStates = start;

                % set  direction as 1 in direction in case start/goal poses are the same
                dirVals = 1;

                solnInfo = struct('IsPathFound', true, 'NumNodes', 0, ...
                                  'NumIterations', 0, 'ExitFlag', 1);

            else
                % Hybrid A* algorithm
                [pathStates, dirVals, solnInfo] = obj.hybridAStarImpl(options.SearchMode);
            end

            % Output navPath object
            if nav.algs.internal.staticMemoryAllocation()
                if isempty(pathStates)
                    pathStates = zeros(0,3);
                end
                pathObj = navPath(obj.StateValidator.StateSpace, pathStates, obj.MaxSize);
            else
                if ~isempty(pathStates)
                    pathObj = navPath(obj.StateValidator.StateSpace, pathStates);
                else
                    pathObj = navPath(obj.StateValidator.StateSpace);
                end
            end

            if coder.target('MATLAB') && ~solnInfo.IsPathFound
                disp(message('nav:navalgs:hybridastar:NoPath').getString);
            end
        end

        function ax = show(obj, options)
            arguments
                obj
                options.Parent = []
                options.Tree {validatestring(options.Tree, {'on', 'off'})} = 'On'
                options.Positions {validatestring(options.Positions, {'Start', 'Goal', 'Both', 'None'})} = 'Both'
                options.Path {validatestring(options.Path, {'on', 'off'})} = 'On'
                options.HeadingLength {mustBeNumeric, mustBeNonnegative, mustBeScalarOrEmpty, mustBeNonempty, mustBeFinite} = ...
                    0.4*obj.InterpolationDistance
            end

            coder.internal.errorIf(~coder.target('MATLAB'), 'nav:navalgs:hybridastar:NoCodegenSupportForShow', 'show');

            % Validate the Parent handle
            if ~isempty(options.Parent)
                robotics.internal.validation.validateAxesUIAxesHandle(options.Parent);
            else
                options.Parent = newplot;
            end

            % Visualize environment map
            if isa(obj.StateValidator.Map, 'vehicleCostmap')
                plot(obj.StateValidator.Map, 'Parent', options.Parent, 'Inflation', 'on');
                legend(options.Parent, 'off');
            else
                obj.StateValidator.Map.show('world', 'Parent', options.Parent);
            end
            title(options.Parent, message('nav:navalgs:hybridastar:FigureTitle').getString);
            hold(options.Parent, 'on');

            if obj.PathFound
                stepSize = 0.05;

                % Get path states discretized by the above stepSize
                % (different from InterpolationDistance property)
                [pathStates, dirvals] = obj.postPlanningLoop(obj.NodeMap, obj.PathNodeIdLast, stepSize);

                % Show expansion tree
                if strcmpi(options.Tree, 'on')
                    obj.showExpansionTree(options.Parent, pathStates, dirvals, stepSize);
                end

                % Show final path
                if strcmpi(options.Path, 'on')
                    obj.showPath(options.Parent, pathStates, dirvals);
                end

                % Visualize heading
                if options.HeadingLength > 0
                    % Get path states for plotting the heading length which
                    % are discretized by InterpolationDistance
                    pathStates = obj.postPlanningLoop(obj.NodeMap, obj.PathNodeIdLast, obj.InterpolationDistance);
                    obj.showHeading(options.Parent, pathStates, options.HeadingLength);
                end
            end

            % Show start and goal poses
            showStartGoalPoses(obj, options.Parent, options.Positions);
            hold(options.Parent, 'off');

            % Returning axis handle
            if nargout > 0
                ax = options.Parent;
            end
        end

        function cpObj = copy(obj)
            if isempty(obj) && coder.target('MATLAB')

                cpObj = plannerHybridAStar.empty;
                return;

            end

            % Construct a new object
            cpObj = plannerHybridAStar(obj.StateValidator);

            % Copy all public properties
            cpObj.MinTurningRadius = obj.MinTurningRadius;
            cpObj.MotionPrimitiveLength = obj.MotionPrimitiveLength;
            cpObj.NumMotionPrimitives = obj.NumMotionPrimitives;
            cpObj.ForwardCost = obj.ForwardCost;
            cpObj.ReverseCost = obj.ReverseCost;
            cpObj.DirectionSwitchingCost = obj.DirectionSwitchingCost;
            cpObj.AnalyticExpansionInterval = obj.AnalyticExpansionInterval;
            cpObj.InterpolationDistance = obj.InterpolationDistance;
        end

        function set.StateValidator(obj, validator)
        %set.StateValidator Setter for property StateValidator

        % Validate StateValidator input, all other types are currently not allowed
            validateattributes(validator, {'validatorOccupancyMap', 'validatorVehicleCostmap'}, {}, 'plannerHybridAStar', 'StateValidator');

            if isa(validator,'validatorVehicleCostmap')

                % Validate validatorVehicleCostmap input
                nav.internal.validation.validateValidatorVehicleCostmap(validator, "plannerHybridAStar", 'StateValidator');

            else

                % Validate validatorOccupancyMap input
                nav.internal.validation.validateValidatorOccupancyMap(validator, "plannerHybridAStar", 'StateValidator');

            end

            % Validate stateSpace property of StateValidator input
            coder.internal.errorIf(~ strcmp(validator.StateSpace.Name, 'SE2'), 'nav:navalgs:hybridastar:StateSpaceError');

            obj.StateValidator = validator;
            obj.getMapData();
            obj.resetShowVariables();
        end

        function set.MinTurningRadius(obj, radius)
        %set.MinTurningRadius Setter for property Minimum Turning Radius

            validateMinimumTurningRadius(obj, radius);
            obj.MinTurningRadius = radius;

        end

        function set.MotionPrimitiveLength(obj, length)
        %set.MotionPrimitiveLength Setter for property length of motion
        %   primitive length

            validateMotionPrimitiveLength(obj, length);
            obj.MotionPrimitiveLength = length;

        end

        function set.TransitionCostFcn(obj,tFcn)
        %set.TransitionCostFcn Setter for transition cost function

            validateattributes(tFcn, {'function_handle'}, {'scalar'}, 'plannerHybridAStar', 'TransitionCostFcn');

            validateTransitionCostFcn(obj, tFcn);

            obj.TransitionCostFcn = tFcn;
        end

        function set.AnalyticalExpansionCostFcn(obj,aeFcn)
        %set.AnalyticalExpansionCostFcn Setter for analytical expansion cost function

            validateattributes(aeFcn, {'function_handle'}, {'scalar'}, 'plannerHybridAStar', 'AnalyticalExpansionCostFcn');

            validateAECostFcn(obj,aeFcn);

            obj.AnalyticalExpansionCostFcn = aeFcn;
        end

    end


    %% Hybrid A* algorithm supporting methods
    methods(Access=private)

        function [pathStates, dirVals, solnInfo] = hybridAStarImpl(obj, searchMode)
        % hybridAStarImpl Hybrid A* algorithm
        % Inputs:
        %   SEARCHMODE: 'greedy' or 'exhaustive'
        % Outputs:
        %   PATHSTATES: Output path states interpolated by
        %               InterpolationDistance.
        %   DIRVALS   : Directions of each state in PATHSTATES. +1 means
        %               forward, -1 means reverse direction.
        % SOLUTIONINFO: Output solution information containing information
        %               whether the path is found, number of nodes, iterations,
        %               exit flag etc.

        % Assigning zero column vector to direction values and path
        % states
            dirVals = zeros(0, 1);
            pathStates = zeros(0,3);

            % Creating object for computing 2D obstacle heuristic
            occMat = obj.Map.checkOccupancyImpl([1,1], obj.Map.GridSize, 'grid');
            if isa(obj.Map, 'occupancyMap')
                occMat(occMat==-1)=1; % consider invalid cells to be free
            end            
            obj.Heuristic2DObj = nav.algs.internal.DPGrid(logical(occMat), obj.Map.Resolution);
            goal = obj.Map.world2gridImpl(obj.GoalPose(1:2));
            obj.Heuristic2DObj.setGoal([goal(1), goal(2)]);

            % Initialize Cost2D matrix
            obj.Cost2D = zeros(obj.Map.GridSize);
            obj.Cost2D(occMat==1) = inf; % cost from occupied cells to goal
            obj.Cost2D(goal(1), goal(2)) = eps; % cost at goal

            % The nodes in priority queue have the following format:
            % [fScore, gScore, hScore, x, y, theta, direction], where
            % fScore is the total score and the priority value. gScore
            % represents the cost from the initial pose, and hScore is the
            % heuristic cost to the goal pose. x, y, theta are the pose of
            % the current node. Direction is 1 for forward motion and -1
            % for reverse motion.
            openSet = nav.algs.internal.PriorityQueue(7, 1);

            % The nodes in the node map have the following format: [x, y,
            % theta,  validPrimitiveInd], where [x,y,theta] refers to
            % vehicle pose and, validPrimitiveInd refers the index of a
            % motion primitive in a predefined set that forms an edge from
            % parent node to the current node
            if nav.algs.internal.staticMemoryAllocation()
                nodeMap = nav.algs.internal.NodeMap(4,obj.MaxSize);
            else
                nodeMap = nav.algs.internal.NodeMap(4);
            end

            gScore = 0;
            hScore = max([obj.get2DHeuristic(obj.StartPose(1:2)),...
                          obj.get3DHeuristic(obj.StartPose, obj.GoalPose)]);

            % Condition when path from start to goal is not possible
            if hScore == inf
                solnInfo = struct('IsPathFound', false, ...
                                  'NumNodes', 0, 'NumIterations', 0, 'ExitFlag', 2);
                return
            end

            fScore = gScore + hScore;
            directionAtStart = 0;
            initNode = [fScore, gScore, hScore, obj.StartPose, directionAtStart];

            openSet.push(initNode);
            nodeMapId = nodeMap.insertNode([obj.StartPose 0], 0);

            coder.internal.assert(obj.NumMotionPrimitives<=obj.MaxSize,...
                                  'nav:navalgs:hybridastar:AssertionFailedLessThan',...
                                  'NumMotionPrimitives','Map.GridSize(1) * Map.GridSize(1) * NumMotionPrimitives');

            if isinf(obj.StateValidator.ValidationDistance)
                % This will be reset back to inf onCleanup
                obj.StateValidator.ValidationDistance = obj.CellSize;
            end

            % Step size for motion primitives and analytical paths
            stepSize = obj.StateValidator.ValidationDistance;

            % Get curvatures and directions samples
            [curvatures, directions] = obj.getCurvaturesAndDirections();

            % Number of poses on each motion primitive
            numPointsMotionPrimitive = floor(obj.MotionPrimitiveLength/stepSize) + 2;

            coder.internal.assert(numPointsMotionPrimitive<=obj.MaxSize,...
                                  'nav:navalgs:hybridastar:AssertionFailedLessThan',...
                                  'numPointsMotionPrimitive','Map.GridSize(1) * Map.GridSize(1) * NumMotionPrimitives');

            % Precompute the motion primitives assuming vehicle pose to be
            % at the origin (0,0,0). The motion primitives are interpolated
            % based on numPointsMotionPrimitive.
            %
            % motionPrimitives: [2*NumMotionPrimitives*numPointsMotionPrimitive, 3]
            % motionPrimitivesLookup: [numPointsMotionPrimitive, 2*NumMotionPrimitives]
            [motionPrimitives, motionPrimitivesLookup] = nav.algs.internal.circularMotionPrimitives(...
                curvatures, directions,...
                obj.MotionPrimitiveLength, numPointsMotionPrimitive);

            % Variables to store number of iterations and nodes
            numIterations = 0;
            numNodes = 0;

            % Create reedsSheppConnection object for specified
            % MinTurningRadius and cost weights
            rsPathObj = reedsSheppConnection("MinTurningRadius",obj.MinTurningRadius,...
                                             "ForwardCost",obj.ForwardCost,"ReverseCost",obj.ReverseCost);

            % Get the end poses of the motion primitives
            endPoseInd = motionPrimitivesLookup(end,:);
            mprimEndPoses = motionPrimitives(endPoseInd, :);

            % Main loop of Hybrid A* Loop will be finished when Hybrid A*
            % finds the path or when there will be no space left to be
            % explored by Hybrid A*
            while ~openSet.isEmpty()

                % Getting the current node and moving it from open list to
                % close list of Hybrid A*
                [currentNode, currentNodeId] = openSet.top();
                currentNodePose = currentNode(4:6);
                openSet.pop();
                numIterations = numIterations + 1;

                if strcmpi(searchMode,'exhaustive')
                    % With this mode, current node will only be added into
                    % closed list after it is moved out of open list for
                    % expansion. Therefore, more nodes will be added into
                    % open list and it will more likely for the planner to
                    % find a more optimal solution. However, planning time
                    % may increase due to more nodes being checked

                    currentNodeGridIndices = obj.Map.world2gridImpl(currentNode(4:5));
                    direction = currentNode(7);

                    % For exhaustive search mode, the algorithm will close
                    % the current cell
                    obj.closeCell(direction, currentNodeGridIndices);
                end

                % Condition if path can be expanded analytically from the
                % node being pushed to closedSet as that is the node
                % available having the lowest cost
                if rem(numIterations, obj.AnalyticExpansionInterval) == 0

                    % Checking if the analytic expansion from new node and
                    % goal is obstacle free
                    result = checkAnalyticExpansion(obj, currentNodePose, obj.GoalPose, stepSize, rsPathObj);

                    if result
                        % Post planning loop
                        [pathStates, dirVals] = obj.postPlanningLoop(nodeMap, currentNodeId, obj.InterpolationDistance);

                        % Using continue in order to properly exit the code
                        % and generate proper response message
                        obj.PathFound = true;
                        if coder.target('MATLAB')
                            obj.NodeMap = nodeMap;
                            obj.PathNodeIdLast = currentNodeId;
                            obj.NodeMapIdLast = nodeMapId;
                        end
                        break;
                    end

                end

                % Compute the end poses of the motion primitives that are
                % the candidates for new nodes in the graph
                newNodesPoses = nav.algs.internal.transformSE2Poses(mprimEndPoses, currentNodePose);

                % Get valid motion primitives to be evaluated
                [validPrimitives, newNodesPosesGridIndices] = obj.isPrimitiveValid(currentNodePose, newNodesPoses,...
                                                                                   motionPrimitives, motionPrimitivesLookup, numPointsMotionPrimitive, directions);

                numValidPrimitives = nnz(validPrimitives);

                % Skip to next iteration if all the motion primitives are
                % invalid or in closed set
                if numValidPrimitives == 0
                    continue
                end

                % Store data when motion primitives are valid
                coder.internal.assert(numValidPrimitives<=obj.MaxSize, ...
                                      'nav:navalgs:hybridastar:AssertionFailedLessThan', ...
                                      'NumValidPrimitives','Map.GridSize(1) * Map.GridSize(1) * NumMotionPrimitives');

                newNodesPoses = newNodesPoses(validPrimitives,:);
                validPrimitiveInd = find(validPrimitives);
                curvatures_ = curvatures(validPrimitives)';
                directions_ = directions(validPrimitives)';

                % Calculating cost of the nodes if they are valid
                [fScore, gScore, hScore] = calculateCost(obj, newNodesPoses, currentNode,...
                                                         curvatures_, directions_);

                % Set Inf cost nodes to be invalid
                validPrimitivesCost = fScore~=inf;
                validPrimitiveInd = validPrimitiveInd(validPrimitivesCost);
                numValidPrimitives = length(validPrimitiveInd);

                % Update openSet and nodeMap with new nodes
                newNodes = [fScore(validPrimitivesCost),...
                            gScore(validPrimitivesCost),...
                            hScore(validPrimitivesCost), ...
                            newNodesPoses(validPrimitivesCost,:),...
                            directions_(validPrimitivesCost)];
                for ii = 1:numValidPrimitives
                    openSet.push(newNodes(ii,:));
                    nodeMapId = nodeMap.insertNode(...
                        [currentNodePose, validPrimitiveInd(ii)], currentNodeId);
                end

                % Adding valid nodes
                numNodes = numNodes + numValidPrimitives;

                if strcmpi(searchMode,'greedy')
                    % With greedy mode, Nodes from the map which are
                    % explored by motion primitives will be added into
                    % closed list. Therefore, open list will be
                    % relatively small. Then planner will be able to
                    % find a solution quickly.

                    % Closing the cells from the map which are explored
                    % by motion primitives
                    obj.closeCell(directions_(validPrimitivesCost), newNodesPosesGridIndices);
                end

            end

            % Solution info output
            if obj.PathFound
                solnInfo = struct('IsPathFound', obj.PathFound, ...
                                  'NumNodes', numNodes, 'NumIterations', numIterations, 'ExitFlag', 1);
            else
                solnInfo = struct('IsPathFound', obj.PathFound, ...
                                  'NumNodes', numNodes, 'NumIterations', numIterations, 'ExitFlag', 3);
            end

        end

        function [pathStates, dirVals, pathData] = postPlanningLoop(obj, nodeMap, pathNodeIdLast, interpDistance)
        %postPlanningLoop Extract the output path data after the
        %planning is finished.
        % Inputs:
        %   NODEMAP       : Node map data structure to which the explored nodes
        %                   are added
        %  PATHNODEIDLAST : ID of the last state of the output path that is
        %                   stored in NODEMAP
        %  INTERPDISTANCE : Distance interval for interpolating the output
        %                   path
        %
        % Outputs:
        %   PATHSTATES: Interpolated output path states of shape [N, 3]
        %               corresponding to the INTERPOLATIONDISTANCE.
        %   DIRVALS   : Directions for each of the state in PATHSTATES
        %   PATHDATA  : Terminal points of the motion primitives along the
        %               output path.

        % Tracking the path from the node available with
        % lowest cost to the starting node
        % currentNode(1) is the node ID for the node available
        % having lowest cost
            pathData = nodeMap.traceBack(pathNodeIdLast);
            pathData = flipud(pathData);
            pathData(1,:) = [];

            % Generating the points and directions according to
            % the interpolation distance provided by the user
            [pathStates, dirVals] = obj.getInterpolatedPath(pathData, interpDistance);
            coder.internal.assert(all(size(pathStates)<=[obj.MaxSize 3]), ...
                                  'nav:navalgs:hybridastar:AssertionFailedLessThan', ...
                                  'Number of states in final path','Map.GridSize(1) * Map.GridSize(1) * NumMotionPrimitives');
            coder.internal.assert(all(size(dirVals)<=[obj.MaxSize 1]), ...
                                  'nav:navalgs:hybridastar:AssertionFailedLessThan', ...
                                  'Number of direction in final path','Map.GridSize(1) * Map.GridSize(1) * NumMotionPrimitives');
        end

        function [validPrimitives, endNodeInd] = isPrimitiveValid(obj, currentNodePose, newNodesPoses,...
                                                                  motionPrimitives, motionPrimitivesLookup, numPointsMotionPrimitive, directions)
        %isPrimitiveValid To check whether a given motion primitives
        % lie inside the map and collision free
        %

        % Check validity of end poses on the motion primitives
            endNodeInd = obj.Map.world2gridImpl(newNodesPoses(:,1:2));
            validEndNode = obj.checkNodeValidity(endNodeInd, directions); % We consider the closed nodes as invalid
            validPrimitives = false(2*obj.NumMotionPrimitives, 1);

            if any(validEndNode)
                numValidEndNode = sum(validEndNode);

                % Check validity of all the motion primitive with valid end
                % nodes (we skip the first state as it is the same as
                % currentNodePose which is already valid)
                lookupInd = motionPrimitivesLookup(2:end,validEndNode);
                motionPrimPoints =  nav.algs.internal.transformSE2Poses(...
                    motionPrimitives(lookupInd(:),:), currentNodePose);
                isValid = obj.StateValidator.isStateValid(motionPrimPoints);

                if nav.algs.internal.staticMemoryAllocation()
                    %Check validity of all points of each motion primitives
                    k = 1;
                    validPrimitivesIter = find(validEndNode==true);
                    for i = 1:numValidEndNode
                        validPrimitives(validPrimitivesIter(i)) = all(isValid(k:k+numPointsMotionPrimitive-2));
                        k = k + numPointsMotionPrimitive - 1;
                    end
                else
                    isValid = reshape(isValid, [numPointsMotionPrimitive-1, numValidEndNode]);
                    validPrimitives(validEndNode) = all(isValid, 1);
                end
            end

            % List of valid end nodes
            endNodeInd = endNodeInd(validPrimitives,:);
        end

        function nodeValidity = checkNodeValidity(obj, nodesGrid, directions)
        %checkNodeValidity To check whether the node is valid or not.

        % Getting indices for the grid cells where motion
        % primitives are ending up

            nodeValidity = true(size(nodesGrid, 1),1);

            % Making out of bounds nodes invalid
            inBounds = nodesGrid(:,1)>=1 & nodesGrid(:,2)>=1 & ...
                nodesGrid(:,1)<=obj.Dimensions(1) &...
                nodesGrid(:,2)<=obj.Dimensions(2);
            nodeValidity(~inBounds) = false;
            inBoundsInd = find(inBounds);

            % Make visited nodes invalid
            nodeInd = (nodesGrid(inBounds,2)-1) * obj.Dimensions(1) + nodesGrid(inBounds,1);
            dirvals = directions(inBounds)';
            dir = dirvals==1;
            nodeValidity(inBoundsInd(dir)) = ~obj.VisitedCells.ForwardDir(nodeInd(dir));
            nodeValidity(inBoundsInd(~dir)) = ~obj.VisitedCells.ReverseDir(nodeInd(~dir));
        end

        function closeCell(obj, direction, index)
        %closeCell To add the node to the closed set

            ind = sub2ind(obj.Dimensions, index(:,1), index(:,2));

            cond = direction==1;

            % Update cells visited in forward direction
            obj.VisitedCells.ForwardDir(ind(cond)) = true;

            % Update cells visited in reverse direction
            obj.VisitedCells.ReverseDir(ind(~cond)) = true;
        end

        function cost = get3DHeuristic(obj, start, goal)
        %get3DHeuristic To get the h3d+ heuristic value

            [~, pathLength, ~] = matlabshared.planning.internal.ReedsSheppBuiltins.autonomousReedsSheppSegments( ...
                start, goal, obj.MinTurningRadius, obj.ForwardCost, obj.ReverseCost, ...
                'optimal', {});
            pathLength = sum(abs(pathLength));
            cost = squeeze(pathLength);

        end

        function cost = get2DHeuristic(obj, pos)
        %get2DHeuristic Compute 2D Heuristic cost using DPGrid object        
            gridPos = obj.Map.world2gridImpl(pos(:,1:2));            
            cost = inf(height(pos), 1);            
            for i=1:height(gridPos)
                row = gridPos(i,1);
                col = gridPos(i,2);
                currentCost = obj.Cost2D(row,col);
                if ~isinf(currentCost) &&... % Cell is not occupied
                        currentCost==0.0 % Cost is not yet computed
                    cost(i) = obj.Heuristic2DObj.getPathCost(gridPos(i,:));
                    obj.Cost2D(row, col) = cost(i);
                else
                    cost(i) = obj.Cost2D(row, col);
                end
            end
        end

        function [fScore, gScore, hScore] = calculateCost(obj, newNodeData, currentNode, curvature, direction)
        %calculateCost To calculate f and g cost of node under operation

            gScore = obj.calculateGScore(currentNode(2), curvature, direction, currentNode);

            % Considering the maximum of both the heuristic
            hScore = max(([obj.get2DHeuristic(newNodeData) obj.get3DHeuristic(newNodeData, obj.GoalPose)]), [], 2);

            fScore = gScore + hScore;
        end

        function result = checkAnalyticExpansion(obj, initialPose, finalPose, stepSize, rsPathObj)
        %checkAnalyticExpansion To check if the analytically expanded curve is collision free

        % Storing the expansion point
            obj.ExpansionPoint = initialPose;

            if obj.CustomAECostFlag == 0

                % Getting the length of the expansion
                [~, obj.AnalyticPathSegments, obj.AnalyticPathTypes] = matlabshared.planning.internal.ReedsSheppBuiltins.autonomousReedsSheppSegments( ...
                    initialPose(1:3), finalPose(1:3), obj.MinTurningRadius, ...
                    obj.ForwardCost, obj.ReverseCost, ...
                    'optimal', {});
                obj.AnalyticPathLength = sum(abs(obj.AnalyticPathSegments));

            else
                rsPathSegObjs = connect(rsPathObj, initialPose(1:3),finalPose(1:3), 'PathSegments', 'all');

                cost = inf;
                minCostIdx = 1;
                for i = 1:numel(rsPathSegObjs)
                    if isnan(rsPathSegObjs{i}.Length)
                        continue;
                    end

                    costTemp = obj.AnalyticalExpansionCostFcn(rsPathSegObjs{i});

                    if costTemp < cost
                        cost = costTemp;
                        minCostIdx = i;
                    end
                end

                obj.AnalyticPathSegments = rsPathSegObjs{minCostIdx}.MotionLengths'.*rsPathSegObjs{minCostIdx}.MotionDirections';
                obj.AnalyticPathLength   = rsPathSegObjs{minCostIdx}.Length;

                %Map motion types left, right, straight and no action to 0,
                %1, 2 and 3 respectively.
                obj.AnalyticPathTypes                                                       = zeros(numel(obj.AnalyticPathSegments),1);
                obj.AnalyticPathTypes(strcmp(rsPathSegObjs{minCostIdx}.MotionTypes, 'R'))   = 1;
                obj.AnalyticPathTypes(strcmp(rsPathSegObjs{minCostIdx}.MotionTypes, 'S'))   = 2;
                obj.AnalyticPathTypes(strcmp(rsPathSegObjs{minCostIdx}.MotionTypes, 'N'))   = 3;
            end

            sz = obj.AnalyticPathLength/stepSize;
            if ~isinf(obj.StateValidator.ValidationDistance)
                coder.internal.assert(sz<=obj.MaxSize/0.001, ...
                                      'nav:navalgs:hybridastar:AssertionFailedLessThan', ...
                                      'AnalyticPathLength/StateValidator.validationDistance','Map.GridSize(1) * Map.GridSize(1) * NumMotionPrimitives* 1000');
            else
                coder.internal.assert(sz<=obj.MaxSize, ...
                                      'nav:navalgs:hybridastar:AssertionFailedLessThan', ...
                                      'AnalyticPathLength/StateValidator.validationDistance','Map.GridSize(1) * Map.GridSize(1) * NumMotionPrimitives');
            end
            samples = linspace(stepSize, obj.AnalyticPathLength, sz);
            segmentDirections = ones(numel(obj.AnalyticPathSegments), 1);
            segmentDirections(obj.AnalyticPathSegments < 0) = -1;
            expansionPoints = matlabshared.planning.internal.ReedsSheppBuiltins.autonomousReedsSheppInterpolateSegments( ...
                initialPose, finalPose, samples, obj.MinTurningRadius, ...
                abs(obj.AnalyticPathSegments'), int32(segmentDirections'), ...
                uint32(obj.AnalyticPathTypes'));

            % If start and goal poses are same
            if isempty(expansionPoints)
                result = true;
                return;

            end

            % Validating the analytically expanded curve
            if nav.algs.internal.staticMemoryAllocation()
                result = true;
                for i=1:size(expansionPoints,1)
                    % Validating the analytically expanded curve
                    result = result && all(obj.StateValidator.isStateValid(expansionPoints(i,:)));
                end
            else
                result = all(obj.StateValidator.isStateValid(expansionPoints));
            end

        end

        function [path, dir] = getInterpolatedPath(obj, pathData, interpDistance)
        %getInterpolatedPath Generating the points and direction values
        %   according to the interpolation distance provided by the user

        % Getting the length of the part of the path which includes only motion
        % primitives( other than Reeds-Shepp path)
            primitivePathLength = obj.MotionPrimitiveLength * size(pathData,1);
            ninterp = floor(primitivePathLength /  interpDistance);
            coder.internal.assert(ninterp<=obj.MaxSize/ interpDistance, ...
                                  'nav:navalgs:hybridastar:AssertionFailedLessThan', ...
                                  'primitivePathLength/InterpolationDistance', ...
                                  'Map.GridSize(1) * Map.GridSize(1) * NumMotionPrimitives / InterpolationDistance');
            states = zeros(ninterp, 3);
            dirs = zeros(ninterp, 1);

            [curvatures, directions] = obj.getCurvaturesAndDirections();

            % Interpolate the motion primitives for the specified
            % interpolation distance
            interpLengths = (1:ninterp)*interpDistance;
            primitiveIndex = fix(interpLengths/obj.MotionPrimitiveLength)+1;
            lengthOnPrimitive = rem(interpLengths, obj.MotionPrimitiveLength);
            j = 1;
            for i = 1:height(pathData)
                mprimId = pathData(i,4);
                dist = lengthOnPrimitive(primitiveIndex==i);
                ndist = length(dist);
                if ndist == 0
                    continue
                end
                if dist == 0
                    states(j,:) = pathData(i,1:3);
                    j = j + 1;
                    continue
                end
                [~,~,motionPrim] = nav.algs.internal.circularMotionPrimitives(...
                    curvatures(mprimId), directions(mprimId), dist(end), dist, true);
                motionPrim = nav.algs.internal.transformSE2Poses(motionPrim, pathData(i,1:3));
                states(j:j+ndist-1,:) = motionPrim;
                dirs(j:j+ndist-1,:) = directions(mprimId);
                j = j+ndist;
            end

            % Remove last pose that is on the last motion primitive
            i = interpLengths>=primitivePathLength;
            states(i,:) = [];
            dirs(i) = [];
            obj.ExpansionPointInd = height(states)+1;

            % Generating poses for analytically expanded path
            numElements = obj.AnalyticPathLength/ interpDistance;
            coder.internal.assert(numElements<=obj.MaxSize, ...
                                  'nav:navalgs:hybridastar:AssertionFailedLessThan', ...
                                  'Number of States in interpolated Path', ...
                                  'Map.GridSize(1) * Map.GridSize(1) * NumMotionPrimitives');
            samples = linspace( interpDistance, obj.AnalyticPathLength, numElements);

            if size(samples,2) ~= 0

                % Calculating distance at which direction switching happens on
                % analytically expanded path and adding it to samples if
                % not present
                getSwitchingMotion = diff(sign(nonzeros(obj.AnalyticPathSegments)));
                switchingDistance = cumsum(abs(obj.AnalyticPathSegments));
                directionSwitchingDistance = switchingDistance(getSwitchingMotion == 2 | getSwitchingMotion == -2);
                samples = unique([samples, directionSwitchingDistance']);

            end

            segmentDirections = ones(numel(obj.AnalyticPathSegments), 1);
            segmentDirections(obj.AnalyticPathSegments < 0) = -1;

            if nav.algs.internal.staticMemoryAllocation()
                samples = [0, samples];
                numSamples = size(samples,2);
                expansionPoints = zeros(numSamples,3);
                expansionDirs = ones(numSamples,1);

                for k = 1:numSamples
                    [expansionPoints(k,:), expansionDirs(k,:)] = ...
                        matlabshared.planning.internal.ReedsSheppBuiltins.autonomousReedsSheppInterpolateSegments( ...
                        obj.ExpansionPoint, obj.GoalPose, samples(k), ...
                        obj.MinTurningRadius, abs(obj.AnalyticPathSegments'), ...
                        int32(segmentDirections'), uint32(obj.AnalyticPathTypes'));
                end
            else
                [expansionPoints, expansionDirs] = ...
                    matlabshared.planning.internal.ReedsSheppBuiltins.autonomousReedsSheppInterpolateSegments( ...
                    obj.ExpansionPoint, obj.GoalPose, [0, samples], ...
                    obj.MinTurningRadius, abs(obj.AnalyticPathSegments'), ...
                    int32(segmentDirections'), uint32(obj.AnalyticPathTypes'));
            end

            % Merging the direction values and poses to be returned to the
            % navPath object
            if ~isequal(obj.StartPose, obj.ExpansionPoint)
                path = [obj.StartPose; states; expansionPoints];
                dir = [directions(pathData(1,end)); dirs; expansionDirs];
            else
                path = expansionPoints;
                dir = expansionDirs;
            end

            coder.internal.assert(size(dir,1)<=obj.MaxSize,['' ...
                                                            'nav:navalgs:hybridastar:AssertionFailedLessThan'],'Number of States in Final Path', ...
                                  'Map.GridSize(1) * Map.GridSize(1) * NumMotionPrimitives');
            coder.internal.assert(size(path,1)<=obj.MaxSize,'nav:navalgs:hybridastar:AssertionFailedLessThan', ...
                                  'Number of Directions in Final Path', ...
                                  'Map.GridSize(1) * Map.GridSize(1) * NumMotionPrimitives');
        end

        function cleanUp(obj)
        %cleanUp To clean up after plan
            if isa(obj.StateValidator, 'validatorOccupancyMap')
                obj.StateValidator.SkipStateValidation = false;
            end
            if obj.IsValidationDistanceInf
                obj.StateValidator.ValidationDistance = inf;
            end
        end

        function getMapData(obj)
        %getMapData Getting the resolution and dimensions from all types
        %   of supported maps

            if isa(obj.StateValidator, 'validatorOccupancyMap')
                % Storing all the supported map internally
                obj.Map = obj.StateValidator.Map;

            else
                % Converting vehicleCostmap to occupancyMap

                % Extract map resolution
                resolution = 1/obj.StateValidator.Map.CellSize;

                % Create occupancyMap
                obj.Map = occupancyMap(obj.StateValidator.Map.Costmap, resolution);

                % Set properties
                obj.Map.FreeThreshold = obj.StateValidator.Map.FreeThreshold;
                obj.Map.OccupiedThreshold = obj.StateValidator.Map.OccupiedThreshold;
                obj.Map.GridLocationInWorld = obj.StateValidator.Map.MapExtent([1 3]);

            end

            % Extracting data out of the map
            obj.CellSize = 1/obj.Map.Resolution;
            obj.Dimensions = obj.Map.GridSize;

            if isinf(obj.StateValidator.ValidationDistance)
                obj.IsValidationDistanceInf = true;
            else
                obj.IsValidationDistanceInf = false;
            end
        end

        function [curvatures, directions] = getCurvaturesAndDirections(obj)
        %getCurvaturesAndDirections Gets the directions and curvatures
        %samples for Hybrid A* search
        %
        % Outputs:
        %   CURVATURES : Curvature samples of motion primitives of shape
        %               [1, 2*NumMotionPrimitives]. First
        %               (2*NumMotionPrimitives-2) elements store
        %                data for circular segments. Last 2 elements store
        %                data for straight segments.
        %
        %   DIRECTIONS:  Direction samples of motion primitives of shape
        %                [1, 2*NumMotionPrimitives].
        %                +1 refers to forward direction and -1 refers to
        %                reverse direction. First (2*NumMotionPrimitives-2)
        %                elements store data for circular segments. Last 2
        %                elements store data for straight segments.

        % Curvatures for motion primitives
            curv = linspace(-1/obj.MinTurningRadius, 1/obj.MinTurningRadius, obj.NumMotionPrimitives);
            curv((obj.NumMotionPrimitives + 1)/2) = [];

            %Replicate curvature for forward direction and reverse
            %direction also append curvature for both (forward and
            % reverse direction) straight motion at the end.
            curvatures = [repmat(curv,1,2) 0 0];

            directions = [ones(1, obj.NumMotionPrimitives-1) -1.*ones(1, obj.NumMotionPrimitives-1) 1 -1];
        end

    end

    methods (Access = ?nav.algs.internal.InternalAccess)

        function gScore = calculateGScore(obj, parentGScore, curvature, direction, currentNode)

            gScore = repmat(parentGScore, size(curvature, 1), 1);
            dirSwitchingCosts = zeros(size(curvature, 1), 1);

            % Checking if the direction of motion is being changed
            if currentNode(7) ~= 0
                dirSwitchingCosts(direction ~= currentNode(1,7)) = obj.DirectionSwitchingCost;
            end

            gScore = gScore + obj.TransitionCostFcn(struct('Curvature', curvature,...
                                                           'Direction', direction, 'StartState', currentNode(4:6),'MotionPrimitiveLength',...
                                                           obj.MotionPrimitiveLength, 'ForwardCost', obj.ForwardCost,...
                                                           'ReverseCost', obj.ReverseCost, 'DirectionSwitchingCost', dirSwitchingCosts));

        end

    end


    %% Visualization helpers
    methods(Access=private)

        function showStartGoalPoses(obj, axHandle, drawPositions)

            if (strcmpi(drawPositions, 'Start') || strcmpi(drawPositions, 'Both')) && ~all(isnan(obj.StartPose))
                [~,startSpec] = plannerLineSpec.start;
                scatter(axHandle, obj.StartPose(1), obj.StartPose(2),startSpec.MarkerSize*4, 'Marker', startSpec.Marker, 'MarkerFaceColor', ...
                        startSpec.MarkerFaceColor, 'MarkerEdgeColor', startSpec.MarkerEdgeColor, ...
                        'DisplayName', message('nav:navalgs:hybridastar:LegendStart').getString);
            end

            % Condition for showing goal pose
            if (strcmpi(drawPositions, 'Goal') || strcmpi(drawPositions, 'Both')) && ~all(isnan(obj.GoalPose))
                [~,goalSpec] = plannerLineSpec.goal;
                scatter(axHandle, obj.GoalPose(1), obj.GoalPose(2),goalSpec.MarkerSize*5, 'Marker', goalSpec.Marker, 'MarkerFaceColor', ...
                        goalSpec.MarkerFaceColor, 'MarkerEdgeColor', goalSpec.MarkerEdgeColor, ...
                        'DisplayName', message('nav:navalgs:hybridastar:LegendGoal').getString);
            end
        end

        function showPath(~, axHandle, pathStates, dirvals)
        %

            directions = [1,-1];

            % Plot path segments with different color forward and reverse
            % directions
            for i = 1:2
                j =  dirvals==directions(i);
                if nnz(j)==0 % No path segments for the current direction
                    continue
                end
                pathStatesPlot = pathStates;
                pathStatesPlot(~j,:) = nan; % Assign nan for path segments in the direction different from the current direction
                                            % Setting up colors and message as per the direction
                if directions(i) == 1
                    % Forward path
                    plotSpec = plannerLineSpec.path;
                    msgStr = message('nav:navalgs:hybridastar:LegendFwdPath').getString;
                else
                    % Reverse path
                    plotSpec = plannerLineSpec.reversePath;
                    msgStr = message('nav:navalgs:hybridastar:LegendRevPath').getString;
                end
                plot(axHandle, pathStatesPlot(:,1), pathStatesPlot(:,2), plotSpec{:}, 'DisplayName', msgStr)
            end
        end

        function showExpansionTree(obj, axHandle, pathStates, dirvals, stepSize)


            [curvatures, directions] = obj.getCurvaturesAndDirections();

            % Compute motion primitives with stepSize used for
            % visualization
            numSamples = floor(obj.MotionPrimitiveLength/stepSize) + 2;
            [~, ~, motionPrim] = nav.algs.internal.circularMotionPrimitives(...
                curvatures, directions, obj.MotionPrimitiveLength, numSamples);

            % Find analytical path states
            analyticalPathStates = pathStates(obj.ExpansionPointInd:end, :);
            analyticalPathDirs = dirvals(obj.ExpansionPointInd:end,:);

            obj.drawMotionPrimitives(axHandle, motionPrim)

            % Plotting analytically expanded path in forward
            % direction
            ind = analyticalPathDirs==1;
            plot(axHandle, analyticalPathStates(ind,1), analyticalPathStates(ind,2), ...
                 plannerLineSpec.path{:}, 'HandleVisibility', 'off');

            % Plotting analytically expanded path in reverse
            % direction
            ind = analyticalPathDirs==-1;
            plot(axHandle, analyticalPathStates(ind,1), analyticalPathStates(ind,2),...
                 plannerLineSpec.reversePath{:}, 'HandleVisibility', 'off');

        end

        function drawMotionPrimitives(obj, axHandle, motionPrim)
        %drawMotionPrimitives To draw straight motion primitives

        % Get node data that contains the valid motion primitive information
        % stored during the A* search
            nodeData = zeros(obj.NodeMapIdLast,4);
            for i = 1:obj.NodeMapIdLast
                nodeData(i,:) = obj.NodeMap.getNodeData(i);
            end
            nodeData = uniquetol(nodeData,'ByRows', true);
            nodeData = nodeData(nodeData(:,4)~=0,:);

            [~, directions] = obj.getCurvaturesAndDirections();

            % Extract the valid motion primitives that were explored during
            % the A* search
            motionPrimId = nodeData(:,4);
            refPoses = nodeData(:,1:3);
            motionPrim = motionPrim(:,:,motionPrimId);
            numPointsMotionPrim = size(motionPrim,1);
            % We put nan between motion primitives for the sake of plotting
            motionPrimPlot = nan(numPointsMotionPrim+1, 3, height(refPoses));
            motionPrimPlot(1:end-1,:,:) =  nav.algs.internal.transformSE2Poses(motionPrim, refPoses);
            directions = directions(nodeData(:,4));

            dirvals = [-1,1];

            % Plot motion primitives with different color forward and reverse
            % directions
            for i = 1:2
                % Setting up colors and message as per the direction
                if dirvals(i) == 1
                    [~,plotSpecS] = plannerLineSpec.tree;
                    Color = plotSpecS.Color;
                    FaceColor = plotSpecS.MarkerFaceColor;
                    plotSpec = plannerLineSpec.tree('MarkerSize',1,'MarkerFaceColor',Color,'MarkerEdgeColor',Color);
                    msgStr = message('nav:navalgs:hybridastar:LegendFwdPrimitives').getString;

                else
                    [~,plotSpecS] = plannerLineSpec.reverseTree;
                    Color = plotSpecS.Color;
                    FaceColor = plotSpecS.MarkerFaceColor;
                    plotSpec = plannerLineSpec.reverseTree('MarkerSize',1,'MarkerFaceColor',Color,'MarkerEdgeColor',Color);
                    msgStr = message('nav:navalgs:hybridastar:LegendRevPrimitives').getString;
                end

                % Plot motion primitive lines
                j = directions==dirvals(i);
                [xmprim, ymprim] = deal(squeeze(motionPrimPlot(:,1,j)), squeeze(motionPrimPlot(:,2,j)));
                plot(axHandle, xmprim(:), ymprim(:), ...
                     plotSpec{:}, 'DisplayName', msgStr);

                % Plot motion primitive end poses
                scatter(axHandle, xmprim(end-1,:), ymprim(end-1,:),...
                        'Color',plotSpecS.Color,...
                        'LineWidth',plotSpecS.LineWidth,...
                        'Marker',plotSpecS.Marker,...
                        'DisplayName',plotSpecS.DisplayName,...
                        'MarkerFaceColor',FaceColor,'MarkerEdgeColor',FaceColor,'HandleVisibility', 'off');

            end
        end

        function showHeading(~, axHandle, pathStates, headingLength)

        % Plotting path poses
            [headingSpec,stateSpec] = plannerLineSpec.heading;
            scatter(axHandle, pathStates(:,1), pathStates(:,2),'Marker',stateSpec.Marker,'MarkerFaceColor',stateSpec.MarkerFaceColor, ...
                    'MarkerEdgeColor',stateSpec.MarkerEdgeColor,'DisplayName',message('nav:navalgs:hybridastar:PathPoints').getString);

            % Calculating coordinates of the poses
            xPoseNew = pathStates(:,1) + (headingLength .* cos(pathStates(:,3)));
            yPoseNew = pathStates(:,2) + (headingLength .* sin(pathStates(:,3)));

            % Arranging orientation of path poses separated by NaN
            plotPoses = nan(3*size(xPoseNew,1), 2);
            plotPoses(1:3:end-2, :) = [pathStates(:,1) pathStates(:,2)];
            plotPoses(2:3:end-1, :) = [xPoseNew yPoseNew];

            % Plotting orientation of poses
            plot(axHandle, plotPoses(:,1), plotPoses(:,2), headingSpec{:}, ...
                 'DisplayName',message('nav:navalgs:hybridastar:Orientation').getString);
        end

        function resetShowVariables(obj)
        %resetShowVariables Resetting the flags used in show method

            obj.PathFound = false;
            obj.StartPose = nan(1,3);
            obj.GoalPose = nan(1,3);

        end

    end


    %% Default properties and extra validators
    methods(Access=private)

        function updateProperties(obj,options)
        % Properties of the class

        % Default value of motion primitive length
        % Setting this value due to the fact that motion primitive
        % should leave the grid cell where the parent node lies
            primitiveLengthDefault = ceil(sqrt(2) * obj.CellSize);

            % Default value of minimum turning radius
            % Setting this value due to the reason that motion primitive
            % length cannot exceed one-fourth the length of the
            % circumference of a circle based on the minimum turning radius
            % Making default not to be less than 2
            minTurnRadDefault = max(2 , 2 * primitiveLengthDefault/pi);


            % Update properties
            if ~isfield(options, 'MinTurningRadius')
                obj.MinTurningRadius = minTurnRadDefault;
            else
                obj.MinTurningRadius = options.MinTurningRadius;
            end
            if ~isfield(options, 'MotionPrimitiveLength')
                obj.MotionPrimitiveLength = primitiveLengthDefault;
            else
                obj.MotionPrimitiveLength = options.MotionPrimitiveLength;
            end
            optionNames = fieldnames(options);
            for i = 1:length(optionNames)
                if strcmpi(optionNames{i}, 'MinTurningRadius') ||...
                        strcmpi(optionNames{i}, 'MotionPrimitiveLength')
                    continue
                end
                obj.(optionNames{i}) = options.(optionNames{i});
            end

            % Update TransitionCostFcn
            if ~isfield(options, 'TransitionCostFcn')
                obj.TransitionCostFcn = @nav.algs.hybridAStar.transitionCost;
            else
                obj.CustomTransitionCostFlag = 1;
                obj.TransitionCostFcn = options.TransitionCostFcn;
            end

            % Update AnalyticalExpansionCostFcn
            if ~isfield(options, 'AnalyticalExpansionCostFcn')
                obj.AnalyticalExpansionCostFcn = @nav.algs.hybridAStar.analyticalExpansionCost;
            else
                obj.CustomAECostFlag = 1;
                obj.AnalyticalExpansionCostFcn = options.AnalyticalExpansionCostFcn;
            end
        end

        function validateStartGoal(obj, state, name)
        %validateStartGoal Validating start and goal states

        % Validating Start State
            nav.internal.validation.validateStartGoal(obj.StateValidator, state, name,'plannerHybridAStar');
        end

        function validateMotionPrimitiveLength(obj, length)
        %validateMotionPrimitiveLength To check the validity of length
        %   of motion primitive. Checking validity here as other
        %   properties of class should not be used in set method

        % Motion primitive should not have difference of heading
        % greater than pi/2
            errorValue = (pi*obj.MinTurningRadius)/2;
            validateattributes(length, {'numeric'}, {'>', sqrt(2) * obj.CellSize, '<=', errorValue},...
                               'plannerHybridAStar', 'MotionPrimitiveLength');

            % ensure that the motionPrimitiveLength is
            % larger than stateValidator.Validation distance
            if ~isinf(obj.StateValidator.ValidationDistance)
                coder.internal.errorIf(length<obj.StateValidator.ValidationDistance,...
                                       'nav:navalgs:hybridastar:MotionPrimitiveLengthError');
            end
        end

        function validateMinimumTurningRadius(obj, radius)
        %validateMinimumTurningRadius Validating the length of
        %   minimum turning radius

        % Motion primitive should not have difference of heading
        % greater than pi/2
            if isempty(obj.MotionPrimitiveLength)
                errorValue = 0;
            else
                errorValue = (2*obj.MotionPrimitiveLength)/pi;
            end
            validateattributes(radius, {'numeric'}, {'>=', errorValue}, ...
                               'plannerHybridAStar', 'MinTurningRadius');

        end

        function validateTransitionCostFcn(obj,tFcn)

            if obj.CustomTransitionCostFlag == 1
                inNum = nargin(tFcn);
                outNum = nargout(tFcn);

                if(inNum~=1||~(outNum==1||outNum==-1))
                    coder.internal.error('nav:navalgs:hybridastar:InvalidTransitionCostFunctionHandle');
                end
            end
        end

        function validateAECostFcn(obj,aeFcn)
            if obj.CustomAECostFlag == 1
                inNum = nargin(aeFcn);
                outNum = nargout(aeFcn);

                if( ~(inNum>0 && inNum<=3) ||~(outNum==1||outNum==-1))
                    coder.internal.error('nav:navalgs:hybridastar:InvalidAECostFunctionHandle');
                end
            end
        end
    end


    %% Overloaded methods
    methods (Access = protected)
        function propgrp = getPropertyGroups(obj)
            propList = struct("StateValidator", obj.StateValidator, 'MinTurningRadius', obj.MinTurningRadius,...
                              'MotionPrimitiveLength', obj.MotionPrimitiveLength, 'NumMotionPrimitives', obj.NumMotionPrimitives, ...
                              'ForwardCost', obj.ForwardCost, 'ReverseCost', obj.ReverseCost, 'DirectionSwitchingCost', ...
                              obj.DirectionSwitchingCost, 'AnalyticExpansionInterval', obj.AnalyticExpansionInterval, ...
                              'InterpolationDistance', obj.InterpolationDistance);

            if obj.CustomTransitionCostFlag == 1
                propList.TransitionCostFcn=obj.TransitionCostFcn;
            end

            if obj.CustomAECostFlag == 1
                propList.AnalyticalExpansionCostFcn=obj.AnalyticalExpansionCostFcn;
            end

            propgrp = matlab.mixin.util.PropertyGroup(propList);

        end
    end

    methods (Static, Hidden)
        function result = matlabCodegenSoftNontunableProperties(~)
        %matlabCodegenSoftNontunableProperties Mark properties as nontunable during codegen
        %
        % Marking properties as 'Nontunable' indicates to Coder that
        % the property should be made compile-time Constant.
            result = {'Map','NumMotionPrimitives','MaxSize','CellSize', 'InterpolationDistance'};
        end
    end

end

function mustBeOdd(input)
%mustBeOdd Validate if the input is odd
    validateattributes(input, {'numeric'}, {'odd'})
end
