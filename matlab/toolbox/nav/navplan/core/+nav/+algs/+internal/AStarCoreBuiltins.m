classdef AStarCoreBuiltins < nav.algs.internal.InternalAccess
    %This class is for internal use only. It may be removed in the future.
    
    %AStarCoreBuiltins Interface to builtins used for core A* algorithm
    %
    %   This class is a collection of functions used for interfacing with the
    %   core A* algorithm implementing in C++. Its main purpose is to dispatch
    %   function calls correctly when executed in MATLAB or code
    %   generation.
    %   During MATLAB execution, we call the existing MCOS C++ class.
    %   During code generation we use a codegen-compatible version.
    % 
    %   The C++ code for MCOS API is located in builtins/src/astarcorebuiltins
    %   The C++ code for C-API is located in builtins/libsrc/astarcodegen
    %
    %   nav.algs.internal.AStarCoreBuiltins() creates a AStarCore object
    %
    %   AStarCoreBuiltins methods:
    %     setStart             - Set start node ID for A* search
    %     setGoal              - Set goal node ID for A* search
    %     getCurrentNode       - Get current node ID from A* search loop
    %     loopThroughNeighbors - Loop through neighbor nodes & update openSet, gScore etc.
    %     getPath              - Get the path output node IDs after the A* search
    %     getPathCost          - Get the path cost after the A* search
    %     getExploredNodes     - Get the explored nodes after the A* search
    %     stopCondition        - Get stop condition for ending the A* loop 
    %
    %   Example:
    %
    %       % Creates a AStarCore object. Set start, goal and find path for
    %       % given successors, transition & heuristic costs
    %       astar = nav.algs.internal.AStarCoreBuiltins;
    %       start = 1; % start node ID
    %       goal = 3; % goal node ID
    %       astar.setStart(start);
    %       astar.setGoal(goal);
    %       % Edge info
    %       successors = 3;
    %       transitionCosts = 1.0;
    %       heuristicCosts = 1.0;
    %       % Run A* loop 
    %       while ~astar.stopCondition()
    %           current = astar.getCurrentNode();
    %           astar.loopThroughNeighbors(successors, transitionCosts, heuristicCosts);
    %       end
    %       % Get outputs after A* search
    %       pathNodeIDs = astar.getPath();
    %       pathCost = astar.getPathCost();
    %       exploredNodeIDs = astar.getExploredNodes();             

    %   See also nav.algs.internal.codegen.AStarCoreBuildable

    % Copyright 2022 The MathWorks, Inc.

    %#codegen

    properties (Access=private)
        %MCOSObj - MCOS interface object to AStarCore        
        %   This is only used during MATLAB execution.
        MCOSObj
    end

    methods
        function obj = AStarCoreBuiltins()
            %aStarCore Constructor for codegen redirect class

            % Create the MCOS class in MATLAB
            obj.MCOSObj = nav.algs.internal.AStarCore();
        end

        function setStart(obj, start)
            % setStart Set start node ID for A* search

            % Call the MCOS method in MATLAB
            obj.MCOSObj.setStart(uint32(start));
        end

        function setGoal(obj, goal)
            % setGoal Set goal node ID for A* search

            % Call the MCOS method in MATLAB
            obj.MCOSObj.setGoal(uint32(goal));
        end

        function currentNodeID = getCurrentNode(obj)
            % getCurrentNode Get current node ID from A* search loop
            % The current node is popped from the priority queue

            % Call the MCOS method in MATLAB
            currentNodeID = obj.MCOSObj.getCurrentNode();
        end

        function loopThroughNeighbors(obj, neighbors, transitionCosts, heuristicCosts)
            % loopThroughNeighbors Loop through neighbor node IDs and update the openSet, gScore etc.

            % Call the MCOS method in MATLAB
            obj.MCOSObj.loopThroughNeighbors(neighbors, transitionCosts, heuristicCosts);
        end

        function pathNodeIDs = getPath(obj)
            % getPath Get the path output node IDs after the A* search

            % Call the MCOS method in MATLAB
            pathNodeIDs = obj.MCOSObj.getPath();
        end

        function cost = getPathCost(obj)
            % getPathCost Get the path cost after the A* search

            % Call the MCOS method in MATLAB
            cost = obj.MCOSObj.getPathCost();
        end        

        function exploredNodeIDs = getExploredNodes(obj)
            % getExploredNodes Get the explored node IDs after the A* search

            % Call the MCOS method in MATLAB
            exploredNodeIDs = obj.MCOSObj.getExploredNodes();
        end

        function stop = stopCondition(obj)
            % stopCondition  Get stop condition when the A* search is
            % complete

            % Call the MCOS method in MATLAB
            stop = obj.MCOSObj.stopCondition();
        end
    end

    methods (Static = true, Access = private)
        function name = matlabCodegenRedirect(~)
            % matlabCodegenRedirect Redirect to buildable class that calls
            % C-API
            name = 'nav.algs.internal.codegen.AStarCoreBuildable';
        end
    end
end
