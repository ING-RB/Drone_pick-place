function [path,cost,numNodesExp,nodesExp] = aStar(startNode, goalNode, edgeList, nodeWeights)
%This function is for internal use only. It may be removed in the future.

%aStar Perform A* search algorithm
%   [PATH, COST, NUMNODESEXP, NODESEXP] = aStarWithPrecomputedAdjMatrix( 
%   STARTNODE, GOALNODE, EDGELIST, ADJACENCYMATRIX)  is the lowest cost
%   path from node STARTNODE to node GOALNODE.  Path is a list of nodes
%   starting with STARTNODE and ending GOALNODE. COST is the length of the 
%   PATH, NUMNODESEXP is the number of nodes, which are explored and NODESEXP
%   is the list of nodes which were explored while finding Path. Path and
%   NODESEXP are array of double values. Cost and NumNodesExp are double
%   values.
%   Input:
%       startNode       - Start node id 
%       goalNode        - Goal node id 
%       EdgeList        - List of edges
%       ADJACENCYMATRIX - NxN matirx of double, stores edges weight

%   Copyright 2014-2021 The MathWorks, Inc.
%
%   References:
%   [1] "A Formal Basis for the Heuristic Determination of Minimum Cost
%       Paths," Hart, P., Nilsson, N., and Raphael, B., IEEE Trans.
%       Syst. Science and Cybernetics, SSC-4(2):100-107, 1968.
%   [2] "Correction to "A Formal Basis for the Heuristic Determination of
%       Minimum Cost Paths"". Hart, P., Nilsson, N., Raphael, B.
%       SIGART Newsletter 37: 28-29, 1972.

%#codegen
    
    %Total number of nodes
    nNodes = size(nodeWeights,1);

    % The set of nodes already evaluated.
    closedSet = zeros(1,nNodes);

    % Initialize costs

    % Distance from start along optimal path
    gScore = Inf*ones(1,nNodes);

    % Heuristic estimate of distance
    hScore = gScore;

    % Estimated total distance from start to goal through a point
    fScore = gScore;

    % Cost from start along best known path.
    gScore(startNode) = 0;

    % The set of tentative nodes to be evaluated, initially containing the start node
    openSet = zeros(1,nNodes);
    openSet(1) = startNode;

    % The map of navigated nodes.
    cameFrom = zeros(1,nNodes);

    % calculate displacement from start to goal
    dist = nodeWeights(startNode, goalNode);

    hScore(startNode) = dist;

    % Estimated total cost from start to goal through y.
    fScore(startNode) = gScore(startNode) + hScore(startNode);

    cost=0;
    numNodesExp=0;
    nodesExp=[];
    % search until there is no nodes in the frontier
    while ~all(openSet==0)
        % current := the node in openset having the lowest fScore[] value

        [~,index] = min(fScore(openSet(openSet>0)));
        availableSet = openSet(openSet>0);
        currentNode = availableSet(index);

        if currentNode == goalNode
            path = constructPath(goalNode, cameFrom);
            cost = gScore(currentNode);
            closedSet = closedSet(closedSet>0);
            numNodesExp = length(availableSet)+length(closedSet);
            nodesExp = [closedSet availableSet];
            return;
        end

        % Remove current from openset
        openSet(openSet==currentNode) = 0;

        % Add current to closedset

        label = find(closedSet==0,1);
        closedSet(label) = currentNode;
        closedSet(1:label(1)) = sort(closedSet(1,1:label(1)));

        % Find neighboring nodes
        edgeLabels = edgeList(1,:) == currentNode;
        neighboringNodes = edgeList(:,edgeLabels);
        % Remove references to self
        neighborList = neighboringNodes(neighboringNodes~=currentNode)';

        for i = 1:size(neighborList, 2)

            % If node has been already explored then skip it
            if ~isempty(find(closedSet==neighborList(i),1))
                continue;
            end

            % Calculate distance to the neighbor
            tentativeGScore = gScore(currentNode) + ...
                nodeWeights(currentNode, neighborList(i));

            % If seeing the node for first time then add to openlist
            if isempty(find(openSet==neighborList(i), 1))
                % Add neighbor to openset
                openSet(find(openSet==0,1))=neighborList(i);

                % calculate distance from neighbor to goal
                hScore(neighborList(i)) = nodeWeights(neighborList(i), goalNode);

                tentativeIsBetter = true;
            elseif tentativeGScore < gScore(neighborList(i))
                tentativeIsBetter = true;
            else
                tentativeIsBetter = false;
            end

            if tentativeIsBetter
                cameFrom(neighborList(i)) = currentNode;
                gScore(neighborList(i)) = tentativeGScore;
                fScore(neighborList(i)) = gScore(neighborList(i)) + ...
                    hScore(neighborList(i));
            end
        end
    end
    path = [];
end

function path = constructPath(goalNode, cameFrom)
%constructPath Construct path at the end of astar
    path = [];
    p = goalNode;
    while true
        path = [p path]; %#ok<AGROW>
        p = cameFrom(p);
        if p == 0
            break;
        end
    end
end
