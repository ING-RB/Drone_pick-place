classdef (Abstract) GraphBasedPlanner < nav.algs.internal.InternalAccess
% This class is for internal use only. It may be removed in the future.

% GraphBasedPlanner Create a planner for graph-based path planning
% Derive from this class if you are defining your own graph-based
% planner. This interface allows taking a GraphBase object and plan
% path for a specified start and goal states in the graph.
% such as plannerAStar
%
% This constructor can only be called from a derived class.
%
% GraphBasedPlanner properties:
%   Graph  - GraphBase object
%
% GraphBasedPlanner methods:
%   plan - Search for graph for a valid path between start and goal
%   copy - Create deep copy of the planner object
%
%   See also plannerAStar, navGraph

%   Copyright 2022 The MathWorks, Inc.

%#codegen

    properties(SetAccess={?nav.algs.internal.InternalAccess})        
        Graph
    end

    methods
        function obj = GraphBasedPlanner(graphObj)
        % GraphBasedPlanner constructor
            obj.Graph = graphObj;
        end

        function set.Graph(obj, graphObj)
        % set.Graph
            validateattributes(graphObj, {'nav.algs.internal.GraphBase'}, ...
                               {'nonempty', 'scalar'},  'GraphBasedPlanner', 'Graph');
            obj.Graph = graphObj;
        end
    end

    methods(Abstract)

        [pathOut, solnInfo] = plan(obj, start, goal);

        obj1 = copy(obj);

    end
end
