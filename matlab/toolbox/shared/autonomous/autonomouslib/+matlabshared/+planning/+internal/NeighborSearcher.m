%matlabshared.planning.internal.NeighborSearcher Interface for neighbor search.
%
%   Defines an interface for neighbor search.
%
%   Inherit from this class and implement nearest() and near() methods.
%
%   See also matlabshared.planning.internal.ExactNeighborSearcher,
%   matlabshared.planning.internal.SqrtApproxNeighborSearcher

% Copyright 2017-2018 The MathWorks, Inc.

%#codegen
classdef NeighborSearcher < matlabshared.planning.internal.EnforceScalarHandle
    
    properties (SetAccess = protected)
        ConnectionMechanism
    end
    
    methods (Abstract)
        [nearestNode, nearestId] = nearest(this, node)
        
        [nearNodes, nearIds] = near(this, node, K)
    end
    
    methods
        %------------------------------------------------------------------
        function this = NeighborSearcher(connMech)
            
            this.ConnectionMechanism = connMech;
        end
        
        %------------------------------------------------------------------
        function configureConnectionMechanism(this, connMechanism)
            
            this.ConnectionMechanism = connMechanism;
        end
        
        %------------------------------------------------------------------
        function d = distance(this, from, to)
            
            d = this.ConnectionMechanism.distance(from, to);
        end
        
        %------------------------------------------------------------------
        function reset(~)
            % Default impl
        end
    end
end
