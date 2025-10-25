classdef RoadmapBuilder < matlab.System & nav.algs.internal.GridAccess
%This class is for internal use only. It may be removed in the future.

%RoadmapBuilder Create a roadmap using a map and number of nodes
%   RB = nav.algs.internal.RoadmapBuilder returns a RoadmapBuilder
%   object to construct PRM roadmap.
%
%   RoadmapBuilder Properties:
%       Roadmap - A graph object representing the probabilistic roadmap
%
%   Step method syntax:
%       step(RB, MAP, NUMNODES, DIST) creates a probabilistic roadmap using
%       the MAP as the environment representation. The probabilistic
%       roadmap constructs a roadmap with nodes equal to NUMNODES
%       and connects all nodes in the roadmap which are within DIST connection
%       distance of each other.

%   Copyright 2014-2019 The MathWorks, Inc.

%   Copyright (C) 1993-2014, by Peter I. Corke
%
%   This file is part of The Robotics Toolbox for Matlab (RTB).
%
%   http://www.petercorke.com
%
%   Peter Corke 8/2009.

%#codegen

    properties
        %Roadmap The graph object representing the roadmap
        Roadmap
    end

    methods
        function obj = RoadmapBuilder
        %RoadmapBuilder initialize the internal Roadmap
        % Initialize a single node graph to allow update() in stepImpl
            obj.Roadmap = nav.algs.internal.PlannerGraph(2, 'euclidean', 2);
        end

        function cpObj = copy(obj)
        %copy Create copy of RoadmapBuilder object
            cpObj = nav.algs.internal.RoadmapBuilder;
            cpObj.Roadmap = obj.Roadmap.copy();
        end
    end

    methods (Access = protected)

        function stepImpl(obj, map, desirednodes, connectionDistance)
        %stepImpl Create roadmap from map and desired nodes

        % Instead of constructing new graph, update old graph
            update(obj.Roadmap, 2, 'euclidean', desirednodes);

            % Extract occupancy grid data
            if isa(map, 'binaryOccupancyMap')
                grid = map.occupancyMatrix;
            else
                % Unknowns are treated as occupied
                grid = logical(map.occupancyMatrix('ternary'));
            end

            % If all cells are occupied then there is no path
            coder.internal.errorIf(all(all(grid)),'nav:navalgs:prm:NoFreeSpace');

            % Upper and lower limits for sampling
            xl = map.XWorldLimits(1);
            xu = map.XWorldLimits(2);
            yl = map.YWorldLimits(1);
            yu = map.YWorldLimits(2);

            % Pre-allocate
            x = zeros(desirednodes,1);
            y = zeros(desirednodes,1);

            % Sample until the number of obstacle free points equals to
            % the desired number of nodes
            lastind = 0;
            while lastind < desirednodes

                % Generate random numbers between world limits
                xyrand = rand(desirednodes,2);

                xrand = (xu-xl).*xyrand(:,1) + xl;
                yrand = (yu-yl).*xyrand(:,2) + yl;

                % Check for occupancy of those points
                xyGrid = map.world2grid([xrand(:), yrand(:)]);
                gridIdx = sub2ind(size(grid), xyGrid(:,1), xyGrid(:,2));
                idx = ~grid(gridIdx);

                % Find last non-zero index
                % In code generation, varsize value cannot be directly
                % assigned to fixed size variable.
                % find returns varsize value with size 0 or 1
                % lastind has size 1
                % Use temp here to workaround the limitation
                temp = find(x, 1, 'last');
                if isempty(temp)
                    lastind = 0;
                else
                    lastind = temp(1);
                end

                ptLen = sum(idx);

                % x,y cannot change size during execution
                % Original code allow x,y to exceed desirenodes
                % which is not necessary
                % Fixed here
                if lastind < desirednodes
                    xrandfree = xrand(idx);
                    yrandfree = yrand(idx);
                    endIndice = min(desirednodes,lastind+ptLen);
                    toFill = endIndice - lastind;
                    x(lastind+1:endIndice) = xrandfree(1:toFill);
                    y(lastind+1:endIndice) = yrandfree(1:toFill);
                end
            end

            % Create local variables as property access is expensive
            resolution = map.Resolution;
            location = map.GridLocationInWorld;

            % Iterate over each node and add edges
            for j=1:desirednodes

                newNode = [x(j); y(j)];

                newNodeID = obj.Roadmap.addNode(newNode);

                [dist,nearByNodes] = obj.Roadmap.distanceFromAllNodes(newNode);

                % Test neighbors in order of increasing distance
                for i=1:length(dist)
                    % If the same node then skip adding edge
                    if nearByNodes(i) == newNodeID
                        continue;
                    end

                    % If distance is greater than threshold then skip adding edge
                    if dist(i) > connectionDistance
                        break;
                    end

                    % If the line passes through obstacles then skip adding edge
                    nearbyNode = obj.Roadmap.nodeCoordinate(nearByNodes(i));

                    isObstacleFree = nav.algs.internal.raycast(newNode', ...
                                                               nearbyNode', grid, resolution, location);

                    if ~isObstacleFree
                        continue;
                    end

                    % Add an edge
                    obj.Roadmap.addEdge(newNodeID, nearByNodes(i), dist(i));
                end
            end
        end

        function num = getNumInputsImpl(~)
            num = 3;
        end

        function num = getNumOutputsImpl(~)
            num = 0;
        end

        function svObj = saveObjectImpl(obj)
        %saveObjectImpl Custom save method
            svObj = saveObjectImpl@matlab.System(obj);
            % call PlannerGraph's copy method explicitly
            svObj.Roadmap = obj.Roadmap.copy;
        end


        function loadObjectImpl(obj, svObj, wasLocked)
        %loadObjectImpl Custom load method
            loadObjectImpl@matlab.System(obj, svObj, wasLocked);

            % Need to call copy at either load or save to ensure
            % appropriate behavior of "clone" method which calls
            % saveObjectImpl and loadObjectImpl to create a clone.

            if isempty(svObj.Roadmap)
                % When loading older versions Roadmap could be empty,
                % reinitialize the roadmap with 2 nodes
                obj.Roadmap = nav.algs.internal.PlannerGraph(2, 'euclidean', 2);
            else
                obj.Roadmap = svObj.Roadmap.copy;
            end
        end
    end
end
