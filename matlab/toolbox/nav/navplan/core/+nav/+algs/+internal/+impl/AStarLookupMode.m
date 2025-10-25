function [pathNodeIDs, pathCost, exploredNodeIDs] = AStarLookupMode(start, goal, nodeData, edgeData, successorLookup)
% This class is for internal use only. It may be removed in the future.

% AStarLookupMode Computes optimal path in a graph using A* in lookup mode. 
%
%   This function takes the start, goal node IDs, node & edge data of the
%   graph and the lookup table to extract the successors. It outputs the
%   path output node IDs, path cost and explored node IDs.
%   
%   [PATHNODEIDS, PATHCOST, EXPLOREDNODEIDS] = AStarLookupMode(START, GOAL, NODEDATA, EDGEDATA, SUCCESSORLOOKUP)
%   Inputs: 
%      START          : Start node ID
%      GOAL           : Goal node ID
%      NODEDATA       : Column vector containing the heuristic costs of
%                       graph's nodes
%      EDGEDATA       : Matrix with first two columns containing source &
%                       target node IDs of the edges. The third column
%                       contains the transition costs of the edges. Note 
%                       that the matrix must be sorted by the node IDs in  
%                       the first two columns in the ascending order. 
%      SUCCESSORLOOKUP: Matrix containing successor node ID data. Each row
%                       of the matrix corresponds to the each node on the
%                       graph.First column of the matrix contains the first
%                       successor node ID and second column contains the 
%                       last successor node ID. E.g. successorLookup(3, :) 
%                       =[5,8] means that the successors of nodeID=3 
%                       corresponds to EDGEDATA(5:8, 1:2) and edge cost 
%                       is EDGEDATA(5:8, 3)
%
%   Outputs:
%      PATHNODEIDS    : List of node IDs representing the optimal path
%                       between START node ID and GOAL node ID
%      PATHCOST       : Cost of the optimal path equal to the sum of
%                       transition costs of successive nodes in PATHNODEIDS
%      EXPLOREDNODEIDS: List of node IDs explored during the process
%                       of finding the optimal path

%   Copyright 2022 The MathWorks, Inc.

%#codegen

% Initialize AStarCore object
astar = nav.algs.internal.AStarCoreBuiltins;

% Set start and goal node IDs
astar.setStart(start);
astar.setGoal(goal);

% Run Astar loop
while ~astar.stopCondition()

    % Get current node from the priority queue
    currentNodeID = astar.getCurrentNode();
    
    % If current node is 0, no path is found and break the loop
    if currentNodeID==0
        break
    end

    % Get first and last node IDs of the successor nodes
    % If none found continue to next loop
    successorsInd = successorLookup(currentNodeID,:);
    if successorsInd == 0 
        continue
    end

    % Get successors node IDs
    successorsNodeIDs = edgeData(successorsInd(1):successorsInd(2),2);

    % Get transition costs for edges connecting the current node and 
    % the successor nodes 
    transitionCosts = edgeData(successorsInd(1):successorsInd(2),3);

    % Get heuristic costs for the successor nodes 
    heuristicCosts = nodeData(successorsNodeIDs);
 
    % Loop through successors of the current node
    astar.loopThroughNeighbors(successorsNodeIDs, transitionCosts, heuristicCosts);

end

% Get node IDs of the solution path
pathNodeIDs = astar.getPath();

% Get cost of the solution path
pathCost = astar.getPathCost();

% Get list of explored nodes during the search
exploredNodeIDs = astar.getExploredNodes();