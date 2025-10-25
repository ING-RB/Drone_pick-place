function [path,cost,numNodes,nodesExplored] = aStar(startNode, goalNode, edgeList, adjacencyMatrix)
%This function is for internal use only. It may be removed in the future.

%aStar Perform A* search algorithm
%   PATH = aStar(STARTNODE, GOALNODE, EDGELIST, ADJACENCYMATRIX) is the 
%   lowest cost path from node STARTNODE to GOALNODE. PATH is a list of 
%   nodes starting with STARTNODE and ending on GOALNODE. ADJACENCYMATRIX
%   has weights for each possible pairs of edges.
%   Input:
%       startNode       - Start node id 
%       goalNode        - Goal node id 
%       EdgeList        - List of edges
%       ADJACENCYMATRIX - NxN matirx of double, stores edges weight

%   Copyright 2014-2021 The MathWorks, Inc.

%#codegen

% For simulation use the mex-file
if isempty(coder.target)
    % Run mex
    [path,cost,numNodes,nodesExplored] = nav.algs.internal.mex.aStar(startNode, goalNode, ...
                                                      edgeList, adjacencyMatrix);
else
    % Run MATLAB-code
    [path,cost,numNodes,nodesExplored] = nav.algs.internal.impl.aStar(startNode, goalNode, ...
                                                      edgeList, adjacencyMatrix);
end
end