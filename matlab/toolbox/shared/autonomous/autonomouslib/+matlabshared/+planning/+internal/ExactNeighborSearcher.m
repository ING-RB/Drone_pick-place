%matlabshared.planning.internal.ExactNeighborSearcher exact neighbor search.
%
%   Performs exact nearest neighbor search using O(n) algorithm.
%
%   neighborSearcher = matlabshared.planning.internal.ExactNeighborSearcher(connMech) 
%   creates a NeighborSearcher object for performing exact nearest neighbor
%   search using the metric specified by the connection mechanism object
%   connMech. 
%
%   Example
%   -------
%   % Create a Dubins connection mechanism
%   connMech = matlabshared.planning.internal.DubinsConnectionMechanism;
%
%   % Create a neighbor searcher for exact neighbor search
%   nSearcher = matlabshared.planning.internal.ExactNeighborSearcher(connMech);
%
%   % Compute distance between nodes
%   from = [ 0 0 0];
%   to   = [10 0 0];
%   d = nSearcher.distance(from, to);
%
%   % Compute the nearest among a set of nodes
%   nodeBuffer = zeros(1000,3);
%   numNodes = 500;
%   nodeBuffer(1:numNodes, :) = rand(numNodes,3);
%   [nearest, id] = nSearcher.nearest(nodeBuffer, numNodes, node);
%
%   % Compute 3-near neighbors among a set of nodes
%   K = 3;
%   [near, ids] = nSearcher.near(nodeBuffer, numNodes, K);
%
%   See also matlabshared.planning.internal.NeighborSearcher.

% Copyright 2017-2018 The MathWorks, Inc.

%#codegen
classdef ExactNeighborSearcher < matlabshared.planning.internal.NeighborSearcher
    
    methods
        %------------------------------------------------------------------
        function this = ExactNeighborSearcher(varargin)
            
            this@matlabshared.planning.internal.NeighborSearcher(varargin{:});
        end
        
        %------------------------------------------------------------------
        function [nearestNode, nearestId] = nearest(this, nodeBuffer, numNodes, node)
            
            [~,nearestId] = min( this.distance( ...
                nodeBuffer( 1 : numNodes, :), node ) );
            
            nearestNode = nodeBuffer(nearestId, :);
        end
        
        %------------------------------------------------------------------
        function [nearNodes, nearIds] = near(this, nodeBuffer, numNodes, node, K)
            
            [~,nearIds] = mink( this.distance( ...
                nodeBuffer( 1 : numNodes, :), node ), K);
            
            nearNodes = nodeBuffer(nearIds, :);
        end
    end
end
