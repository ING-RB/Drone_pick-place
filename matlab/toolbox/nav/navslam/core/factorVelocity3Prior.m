classdef factorVelocity3Prior  < nav.algs.internal.UnaryFactor
%FACTORVELOCITY3PRIOR Create prior factor for 3D velocity
%   F = factorVelocity3Prior(ID) returns a factorVelocity3Prior object, F,
%   with the node identification number set to ID. ID is an N-by-1 array
%   where each row is one velocity node ID. N is the number of factors. The
%   measurement represents a a prior on velocity in 3D (in the format of
%   [vx,vy,vz]). By default, the prior value is set to [0,0,0] and the
%   corresponding information matrix is set to eye(3).
%   
%   F = FACTORVELOCITY3PRIOR(...,Name=Value) specifies properties using one
%   or more name-value arguments.
%
%   FACTORVELOCITY3PRIOR properties:
%       NodeID            - ID of node to connect to in factor graph
%       Measurement       - Measured velocity in [vx,vy,vz]
%       Information       - Uncertainty of measurement
%
%   Example:
%       % Add a velocity prior to a factor graph.
%       f = factorVelocity3Prior(1);
%       g = factorGraph;
%       addFactor(g,f);
%       % Check the node type. The node that the velocity prior factor 
%       % connects to is type "VEL3".
%       nodeType(g,1);
%
%   See also factorGraph.

%   Copyright 2021-2023 The MathWorks, Inc.

%#codegen

    properties (Hidden, Constant)
        FactorType = "Vel3_Prior_F";
    end
    
    methods
        function obj = factorVelocity3Prior(id, varargin)
            %FACTORVELOCITY3PRIOR Constructor;
            narginchk(1, Inf);
            obj@nav.algs.internal.UnaryFactor(id, 1, [0,0,0], eye(3), varargin{:});
        end
    end

    methods (Access=protected)
        function type = nodeTypeImpl(~, ~)
            type = nav.internal.factorgraph.NodeTypes.Velocity3;
        end
    end
end

