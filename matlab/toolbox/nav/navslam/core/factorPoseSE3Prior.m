classdef factorPoseSE3Prior  < nav.algs.internal.UnaryFactor
%FACTORPOSESE3PRIOR Full-state prior factor for SE(3) pose
%
%   F = FACTORPOSESE3PRIOR(ID) returns a factorPoseSE3Prior object, F, with
%   the node identification number set to ID. One factor object supports
%   constructing multiple factors at once with multiple node ID sets. ID
%   is an N-by-1 array where each row is one pose node ID. N is the number
%   of factors. The measurement represents a absolute SE3 pose prior (in
%   local coordinates). By default, the measurement is set to
%   [0,0,0,1,0,0,0] and the corresponding information matrix is set to
%   eye(6).
%
%   F = FACTORPOSESE3PRIOR(...,Name=Value) specifies properties using one
%   or more name-value arguments.
%
%   FACTORPOSESE3PRIOR properties:
%       NodeID            - ID of node to connect to in factor graph
%       Measurement       - Measured SE3 pose in [x,y,z,qw,qx,qy,qz]
%       Information       - Uncertainty of measurement
%
%   Example:
%       % Add a 3D pose prior factor with a node ID of 1 to a factor graph.
%       f = factorPoseSE3Prior(1);
%       g = factorGraph;
%       addFactor(g,f);
%       % Check the node type. The node that the 3D pose prior factor 
%       % connects to is type "POSE_SE3".
%       nodeType(g,1);
%
%   See also factorGraph.

%   Copyright 2021-2023 The MathWorks, Inc.

%#codegen
    
    properties (Hidden, Constant)
        FactorType = "SE3_Prior_F";
    end

    methods
        function obj = factorPoseSE3Prior(id, varargin)
            %FACTORPOSESE3PRIOR Constructor
            narginchk(1, Inf);
            obj@nav.algs.internal.UnaryFactor(id, 1, [0,0,0,1,0,0,0], eye(6), varargin{:});
        end
    end

    methods (Access=protected)
        function type = nodeTypeImpl(~, ~)
            type = nav.internal.factorgraph.NodeTypes.SE3;
        end
    end
end

