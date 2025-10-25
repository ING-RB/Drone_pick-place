%matlabshared.planning.internal.SqrtApproxNeighborSearcher approximate neighbor search.
%
%   Performs approximate nearest neighbor search using O(sqrt(n))
%   algorithm.
%
%   neighborSearcher = matlabshared.planning.internal.SqrtApproxNeighborSearcher(connMech) 
%   creates a NeighborSearcher object for performing approximate nearest
%   neighbor search using the metric specified by the connection mechanism
%   object connMech. 
%
%   Example
%   -------
%   % Create a Dubins connection mechanism
%   connMech = matlabshared.planning.internal.DubinsConnectionMechanism;
%
%   % Create a neighbor searcher for approximate neighbor search
%   nSearcher = matlabshared.planning.internal.SqrtApproxNeighborSearcher(connMech);
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
classdef SqrtApproxNeighborSearcher < matlabshared.planning.internal.NeighborSearcher
    
    properties (Access = private)
        Offset = 0;
    end
    
    methods
        %------------------------------------------------------------------
        function this = SqrtApproxNeighborSearcher(varargin)
            
            this@matlabshared.planning.internal.NeighborSearcher(varargin{:});
            
            reset(this);
        end
        
        %------------------------------------------------------------------
        function [nearestNode, nearestId] = nearest(this, nodeBuffer, numNodes, node)
            
            % Compute quantities required to index correctly into node
            % buffer so that only sqrt(N) neighbors are searched over.
            [offset, step, numNodes] = this.computeOffsets(numNodes);
            
            % Find nearest neighbor over the sqrt(N) neighbors.
            [~,nearestId] = min( this.distance( ...
                nodeBuffer(offset : step : numNodes, :), node ) );
            
            % Transform back to global node buffer index.
            nearestId = offset + (nearestId-1)*step;
            
            nearestNode = nodeBuffer(nearestId, :);
        end
        
        %------------------------------------------------------------------
        function [nearNodes, nearIds] = near(this, nodeBuffer, numNodes, node, K)
            
            % Compute quantities required to index correctly into node
            % buffer so that only sqrt(N) neighbors are searched over.
            [offset, step, numNodes] = this.computeOffsets(numNodes);
            
            % Find near neighbors over the sqrt(N) neighbors.
            [~,nearIds] = mink( this.distance( ...
                nodeBuffer(offset : step : numNodes, :), node ), ...
                K);
            
            % Transform back to global node buffer indices.
            nearIds = offset + (nearIds-1).*step;
            
            nearNodes = nodeBuffer(nearIds, :);
        end
        
        %------------------------------------------------------------------
        function reset(this)
            this.Offset = 0;
        end
    end
    
    methods (Access = private)
        %------------------------------------------------------------------
        function [offset,step,numNodes] = computeOffsets(this, numNodes)
            
            % Compute step between samples
            step = floor( sqrt(numNodes) );
            
            % Compute offset to start from
            offset = mod( this.Offset, step ) + 1;
            
            % Increment offset so that we pick a different set of nodes
            % each time.
            this.Offset = this.Offset + 1;
        end
    end
end
