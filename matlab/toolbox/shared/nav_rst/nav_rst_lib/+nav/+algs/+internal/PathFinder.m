classdef PathFinder < matlab.System & nav.algs.internal.GridAccess
%This class is for internal use only. It may be removed in the future.

%PATHFINDER Find a path between two points using a roadmap
%   PF = nav.algs.internal.PathFinder returns a path finder object
%   to compute an obstacle free path on a graph.
%
%   Step method syntax:
%
%   PATH = step(PF, ROADMAP, MAP, START, GOAL) computes an
%   N-by-2 obstacle free path(PATH) which contains [x y] world
%   coordinates of the waypoints. The input ROADMAP is of type
%   PlannerGraph and MAP is of type binaryOccupancyMap. START
%   and GOAL are 2-by-1 array of points in world coordinate
%   system.

%   Copyright 2014-2019 The MathWorks, Inc.

%   Copyright (C) 1993-2014, by Peter I. Corke
%
%   This file is part of The Robotics Toolbox for Matlab (RTB).
%
%   http://www.petercorke.com
%
%   Peter Corke 8/2009.


%#codegen
    methods
        function cpObj = copy(~)
        %copy Create copy of RoadmapBuilder object
            cpObj = nav.algs.internal.PathFinder;
        end
    end

    methods(Access = protected)
        function shortestPath = stepImpl(obj, roadmap, map, start, goal)
        %stepImpl Compute a shortest path on the roadmap

            shortestPath = [];

            % Return immediately if start and goal are same
            if isequal(start, goal)
                shortestPath = start;
                return;
            end

            % Find the vertex closest to the goal
            goalNode = obj.findClosestNode(goal, roadmap, map);

            % Find the vertex closest to the start
            startNode = obj.findClosestNode(start, roadmap, map);

            % Check if cannot find a closestNode when calling
            % findClosestNode method. Instead of check for empty, check for
            % nan
            if isnan(goalNode) || isnan(startNode)
                return;
            end

            % Check if the vertices are connected
            % Use isequal instead of ~= in codegen
            componentStart = roadmap.componentFromNodes(startNode);
            componentGoal = roadmap.componentFromNodes(goalNode);
            if ~isequal(componentStart, componentGoal)
                return;
            end

            % If connected, find a path through the graph
            nodepath = roadmap.aStar(startNode, goalNode);

            % Get coordinates of the nodes
            gpath  = roadmap.nodeCoordinate(nodepath);

            % Add start and goal points to the path. Do not add start or
            % goal if they are the same as first or last points in the path
            % respectively to avoid repeated points.

            % Avoid changing variable size directly using index,
            % i.e. shortestPath(end+1,:) = goal
            shortestPath = start;

            % Check if start point is the same as the node
            if (norm(start - gpath(:,1)') < eps)
                shortestPath = [shortestPath; gpath(2:end, :)'];
            else
                shortestPath = [shortestPath; gpath'];
            end

            % Check if goal point is same as the last node
            if (norm(goal - gpath(:, end)') > eps)
                % Avoid changing variable size directly using index,
                % i.e. shortestPath(end+1,:) = goal
                shortestPath = [shortestPath; goal];
            end
        end

        function num = getNumInputsImpl(~)
            num = 4;
        end

        function num = getNumOutputsImpl(~)
            num = 1;
        end
    end

    methods (Access = private, Static)
        function closestNode = findClosestNode(node, roadmap, map)
        %findClosestNode Find a closest node and test for collision

        % Instead of [], use nan as default. This avoids variable
        % changing size during function call.
            closestNode = nan;

            [dist,nearByNodes] = roadmap.distanceFromAllNodes(node);

            % Test neighbors in order of increasing distance
            for i=1:length(dist)
                if norm(node - nearByNodes(i)) < eps
                    continue;
                end

                % If the line passes through obstacles then skip adding edge
                nearbyNode = roadmap.nodeCoordinate(nearByNodes(i));
                isObstacleFree = nav.algs.internal.checkLineCollision(node, nearbyNode', map);

                if isObstacleFree
                    % Find the vertex closest to the goal
                    closestNode = nearByNodes(i);
                    return;
                end
            end
        end
    end
end
