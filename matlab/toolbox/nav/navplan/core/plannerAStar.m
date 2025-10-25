classdef plannerAStar < nav.algs.internal.GraphBasedPlanner
%

% Copyright 2022-2024 The MathWorks, Inc.

%#codegen

    properties
        HeuristicCostFcn

        TieBreaker
    end

    properties(Access={?nav.algs.internal.InternalAccess})
        % LookupMode Flag to use lookup mode
        %   Enabled or disabled to true or false
        LookupMode

        % SuccessorLookup Contains starting location and end location for
        % the sorted endstates of Links table for the given node.
        % Used for look-up mode
        SuccessorLookup

        % LinkWeightLookup Stores endstates ids and weight as matrix.
        % Used for look-up mode.
        LinkWeightLookup
    end

    properties(Dependent, Access=private)
        % Flag if tie breaker property is to be used or not.
        TieBreakConstant;
    end

    % Public methods
    methods
        function obj = plannerAStar(graphObj, varargin)

            narginchk(1, 5);

            % Initialize the superclass
            obj = obj@nav.algs.internal.GraphBasedPlanner(graphObj);

            % Parse the name-value pair inputs to constructor
            propsStruct = plannerAStar.parseConstructorInputs(varargin{:});

            % Set properties
            obj.HeuristicCostFcn = propsStruct.HeuristicCostFcn;
            obj.TieBreaker = propsStruct.TieBreaker;
            obj.LookupMode = false; % default LookupMode is false

            % Lookup mode used for accelerating the planning process for
            % static graphs (e.g. navGraph)
            if isa(obj.Graph, 'navGraph')
                obj.LookupMode = true;
            end

            % Pre-allocate lookup data for successors and link weights
            obj.LinkWeightLookup = zeros(height(obj.Graph.States),2);
            obj.SuccessorLookup = zeros(height(obj.Graph.Links),3);

            % Generate lookup data from graph LookupMode is enabled
            if obj.LookupMode
                obj.Graph.generateLookup();
                obj.LinkWeightLookup = obj.Graph.LinkWeightLookup;
                obj.SuccessorLookup = obj.Graph.SuccessorLookup;
            end
        end

        function [path, solutionInfo] = plan(obj, start, goal)

            narginchk(3,4);

            % Validate and get the numeric index for start and goal inputs
            start = obj.validateStartGoal(start, 'start');
            goal = obj.validateStartGoal(goal, 'goal');

            % Plan path between start and goal
            if obj.LookupMode

                % Generate lookup data from graph if lookupData is not
                % present
                if isempty(obj.Graph.SuccessorLookup)
                    obj.Graph.generateLookup();
                    obj.LinkWeightLookup = obj.Graph.LinkWeightLookup;
                    obj.SuccessorLookup = obj.Graph.SuccessorLookup;
                end

                % Plan path with mex for lookup mode.
                heuristicCosts = obj.getHeuristicCosts(1:height(obj.Graph.States), goal);
                if coder.target("MATLAB")
                    % Use mex in simulation mode
                    aStar = @nav.algs.internal.mex.AStarLookupMode;
                else
                    % Use impl in code gen mode
                    aStar = @nav.algs.internal.impl.AStarLookupMode;
                end
                [pathStateIDs, pathCost, exploredStateIDs] = ...
                    aStar(start, goal, heuristicCosts,...
                          obj.LinkWeightLookup, obj.SuccessorLookup);
            else
                % Plan path without mex for non-lookup mode
                [pathStateIDs, pathCost, exploredStateIDs] = obj.aStar(start, goal);
            end

            % Post process plan method outputs
            [path, solutionInfo] = obj.processPlanOutputs(pathStateIDs, pathCost, exploredStateIDs);

        end

        function newObj = copy(obj)

            graphObj = copy(obj.Graph);
            newObj = plannerAStar(graphObj, HeuristicCostFcn=obj.HeuristicCostFcn);
            newObj.TieBreaker = obj.TieBreaker;
        end
    end

    % Set, get methods for public properties
    methods
        function set.HeuristicCostFcn(obj, heuristicCostFcn)
        % set.HeuristicCostFcn
            validateattributes(heuristicCostFcn, {'function_handle'}, ...
                               {'nonempty', 'scalar'}, obj.getClassName(), 'HeuristicCostFcn')

            % Validate number of input and output arguments
            nargIn = nargin(heuristicCostFcn);
            nargOut = nargout(heuristicCostFcn);

            % Number of inputs to function handle must be atleast 2
            % excluding varargin
            if (nargIn>=0 && nargIn<2) || ...  % without varargin
                        (nargIn<0 && nargIn>-3 ) % with varargin
                error(message('nav:navalgs:plannerAStar:InvalidCostFunctionHandle', 2, 'inputs'))
            end

            % Number of outputs from function handle must be atleast 1
            % including varargout
            if abs(nargOut)< 1
                error(message('nav:navalgs:plannerAStar:InvalidCostFunctionHandle', 1, 'outputs'))
            end

            % Update HeuristicCostFcn property
            obj.HeuristicCostFcn = heuristicCostFcn;
        end

        function set.TieBreaker(obj, tieBreaker)
        % set.TieBreaker
            validateattributes(tieBreaker, {'logical', 'numeric'}, {'scalar', 'binary'},...
                               obj.getClassName(), 'TieBreaker');
            obj.TieBreaker = tieBreaker;
        end

        function value = get.TieBreakConstant(obj)
        %get.TieBreakConstant

        % When the tie breaker is enabled we nudge the scale of
        % heuristic cost slightly upwards by 7% like plannerAStarGrid.
        % This tie breaker helps A* expand nodes close to goal. Note
        % that the tie breaking slightly breaks the "admissibility" of
        % the heuristic.
            if obj.TieBreaker
                value = 1.07;
            else
                value = 1.0;
            end
        end
    end

    methods(Access=private)

        function cname = getClassName(obj) %#ok<MANU>
        %getClassName
            cname = 'plannerAStar';
        end

        function index = validateStartGoal(obj, state, name)
        % validateStartGoal Validates the start or goal inputs to the
        % the plan method and returns the numeric index in the graph.

        % The start and goal inputs to plan method must be numeric IDs,
        % or name IDs or state vector
            validateattributes(state, {'numeric', 'char', 'string'},...
                               {'nonempty'}, 'plan', name);

            % Process the start and goal depending upon the type
            if isscalar(state) && isnumeric(state)
                %If the node is specified as index
                validateattributes(state, {'numeric'},...
                                   {'nonempty', 'integer','positive', '<=', height(obj.Graph.States)},...
                                   'plan', name);
                index = state;

            elseif ischar(state) || isstring(state)
                % If state is specified as name

                % Must be numeric if the table has no Name column
                if ~strcmp(obj.Graph.States.Properties.VariableNames, 'Name')
                    validateattributes(state, {'numeric'}, {''}, 'plan', name);
                end

                % Must be non-missing string scalar or character vector
                state = convertStringsToChars(state);
                validateattributes(state, {'char'},...
                                   {'nonempty', 'scalartext'}, 'plan', name);

                % Locate the state in the Name column
                matches = strcmp(obj.Graph.States.Name, state);

                % Check if state name exists in the Graph
                coder.internal.errorIf(~any(matches), 'nav:navalgs:plannerAStar:StateNameNotFound', state)

                % Get state index
                index = find(matches);

            elseif isnumeric(state)
                % If state is specified as a vector

                % Must be a vector
                validateattributes(state, {'numeric'},...
                                   {'vector', 'ncols', width(obj.Graph.States.StateVector)}, 'plan', name)

                % Get state index
                index = obj.Graph.closestStateID(state);
            end

            % Convert index to double type to be compatible with MEX A*
            if ~isa(index, 'double')
                index = cast(index, 'double');
            end

            % Reaffirm scalar for codegen while working with a state vector
            index = index(1);
        end

        function [pathStateIDs, pathCost, exploredStateIDs] = aStar(obj, start, goal)
        % aStar Find path using A* for non-lookup mode.
        %   This version is used when the graph is updated during
        %   the planning loop i.e., the successors and their
        %   costs cannot be pre-computed before calling the plan
        %   method.

        % Initialize aStarCore object
            astarObj = nav.algs.internal.AStarCoreBuiltins;
            astarObj.setStart(start);
            astarObj.setGoal(goal);

            while ~astarObj.stopCondition()

                % AStarCore: Get current node
                current = double(astarObj.getCurrentNode());

                % Get successors and the transition costs
                [successors, transitionCosts] = obj.Graph.successors(current);

                if ~isempty(successors)
                    % Get heuristic costs for the successor nodes
                    heuristicCosts = obj.getHeuristicCosts(successors, goal);

                    % AStarCore: Loop through neighbors
                    astarObj.loopThroughNeighbors(successors, transitionCosts, heuristicCosts);
                end
            end

            pathStateIDs = astarObj.getPath();
            pathCost = astarObj.getPathCost();
            exploredStateIDs = astarObj.getExploredNodes();
        end

        function [path, solutionInfo] = processPlanOutputs(obj, pathStateIDs, pathCost, exploredStateIDs)
        % processPlanOutputs Process the outputs of plan method for
        % lookup and non-lookup modes

        % Default outputs for no path found scenario
            path = zeros(0, width(obj.Graph.States.StateVector));
            solutionInfo = plannerAStar.solutionInfoDefaults();

            % Process the path outputs
            % When no path is found: PathStateIDs=empty, PathCost=nan
            % When start and goal are same: PathStateIDs=start, PathCost=0
            % In other cases: PathStateIDs is vector, PathCost>0
            if ~all(pathStateIDs==0)

                % Get path output containing the matrix of state vectors
                path = obj.Graph.States.StateVector(pathStateIDs, :);

                % Get fields for solutionInfo struct
                solutionInfo.IsPathFound = true;
                solutionInfo.PathCost = pathCost;

                % Get numeric IDs or name IDs if names are provided
                if ~any(strcmp(obj.Graph.States.Properties.VariableNames, 'Name'))
                    solutionInfo.PathStateIDs = pathStateIDs;
                else
                    solutionInfo.PathStateIDs = obj.Graph.States.Name(pathStateIDs);
                    solutionInfo.PathStateIDs = solutionInfo.PathStateIDs(:)'; % make row vector
                end
            end

            % Process the explored nodes
            % When no nodes are explored: ExploredStateIDs=empty, NumExploredStates=0,
            % When start and goal are same: ExploredStateIDs=start, NumExploredStates=1
            % In other cases: ExploredStateIDs is vector, NumExploredStates>1
            if ~all(exploredStateIDs==0)
                solutionInfo.NumExploredStates = length(exploredStateIDs);
                % Get numeric IDs or name IDs if names are provided
                if ~any(strcmp(obj.Graph.States.Properties.VariableNames, 'Name'))
                    solutionInfo.ExploredStateIDs = exploredStateIDs;
                else
                    solutionInfo.ExploredStateIDs = obj.Graph.States.Name(exploredStateIDs, :);
                    solutionInfo.ExploredStateIDs = solutionInfo.ExploredStateIDs(:)'; % make row vector
                end
            end
        end

        function hcosts = getHeuristicCosts(obj, stateIDs, goal)
        % getHeuristicCosts Compute heuristic between the given list of
        % state IDs and the goal state

            states = obj.Graph.States.StateVector(stateIDs, :);
            goalState = obj.Graph.States.StateVector(goal, :);
            hcosts = obj.HeuristicCostFcn(states, goalState);
            coder.internal.assert(height(states)==height(hcosts),....
                                  'nav:navalgs:plannerAStar:InvalidHeuristicCostFunction')
            % Apply tiebreaker
            hcosts = hcosts*obj.TieBreakConstant;
        end
    end

    methods(Hidden, Static)

        function propsStruct = parseConstructorInputs(varargin)
        % parseInputs Parse name-value pair inputs to the constructor

        % Get default properties
            propsDefault = plannerAStar.propertyDefaults;

            % Parse name-value pair inputs and return struct containing
            % properties
            props = coder.internal.parseParameterInputs(propsDefault, struct(), varargin{:});
            propsStruct = coder.internal.vararginToStruct(props, propsDefault, varargin{:});
        end

        function defaults = propertyDefaults()
        % propertyDefaults Define the default values for the
        % public properties
            defaults = struct(...
                'HeuristicCostFcn', @nav.algs.distanceManhattan, ...
                'TieBreaker', false);
        end

        function defaults = solutionInfoDefaults()
        % solutionInfoDefaults Define the default outputs for solution
        % info assuming no path is found
            defaults = struct(...
                'IsPathFound', false,...
                'PathStateIDs', zeros(0,1),...
                'PathCost', nan,...
                'ExploredStateIDs', zeros(0,1),...
                'NumExploredStates',0);
        end


        function obj = loadobj(S)
            obj = plannerAStar(S.Graph,...
                HeuristicCostFcn=S.HeuristicCostFcn,...
                TieBreaker=S.TieBreaker);
        end
    end
end
