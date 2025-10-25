classdef factorTwoPoseSE3 < nav.algs.internal.FactorGaussianNoiseModel
%FACTORTWOPOSESE3 Factor relating two SE(3) poses
%
%   F = FACTORTWOPOSESE3(ID) returns a factorTwoPoseSE3 object, F, with the
%   node identification number set to ID. One factor object supports
%   constructing multiple factors at once with multiple node ID sets. ID is
%   an N-by-2 array where each row is of the form [poseID poseID]. N is the
%   number of factors, poseID is robot pose node ID. The measurement
%   represents a relative pose in SE3. By default the measurement is set to
%   [0,0,0,1,0,0,0] (in [dx,dy,dz,dqw,dqx,dqy,dqz] format) and the
%   corresponding information matrix is set to eye(6).
%
%   F = FACTORTWOPOSESE3(...,Name=Value) specifies properties using one
%   or more name-value arguments.
%
%   FACTORTWOPOSESE3 methods:
%       nodeType          - Retrieve the node type for specified node ID
%
%   FACTORTWOPOSESE3 properties:
%       NodeID            - IDs of nodes to connect to in factor graph
%       Measurement       - Measured relative pose in [x,y,z,qw,qx,qy,qz]
%       Information       - Uncertainty of measurement
%
%   Example:
%       % Create a factorTwoPoseSE3 object that specifies two factors. The
%       % first factor connects node 1 and 2. The second factor connects
%       % node 2 and 3.
%       f = factorTwoPoseSE3([1 2; 2 3]);
%       g = factorGraph;
%       addFactor(g,f);
%       % Nodes 1, 2, and 3 are added to the factor graph and connected as
%       % specified by the factors. All nodes are of type "POSE_SE3".
%       nodeType(g,1);
%
%   See also factorGraph.

%   Copyright 2021-2022 The MathWorks, Inc.

%#codegen

    properties (Hidden, Constant)
        FactorType = "Two_SE3_F";
    end
    
    methods
        function obj = factorTwoPoseSE3(ids, varargin)
            %FACTORTWOPOSESE3 Constructor
            narginchk(1, Inf);
            obj@nav.algs.internal.FactorGaussianNoiseModel(ids, 2, [0,0,0,1,0,0,0], eye(6), varargin{:});
        end
    end

    methods (Access=protected)
        function type = nodeTypeImpl(~, ~)
            type = nav.internal.factorgraph.NodeTypes.SE3;
        end
    end
end

