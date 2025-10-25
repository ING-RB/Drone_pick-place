classdef factorTwoPoseSE2 < nav.algs.internal.FactorGaussianNoiseModel
%FACTORTWOPOSESE2 Factor relating two SE(2) poses
%
%   F = FACTORTWOPOSESE2(ID) returns a factorTwoPoseSE2 object, F, with the
%   node identification number set to ID. One factor object supports
%   constructing multiple factors at once with multiple node ID sets. ID is
%   an N-by-2 array where each row is of the form [poseID poseID]. N is the
%   number of factors, poseID is robot pose node ID. The measurement
%   represents a relative pose in SE2. By default the measurement is set to
%   [0,0,0] and the corresponding information matrix is set to eye(3).
%
%   F = FACTORTWOPOSESE2(...,Name=Value) specifies properties using one
%   or more name-value arguments.
%
%   FACTORTWOPOSESE2 methods:
%       nodeType          - Retrieve the node type for specified node ID
%
%   FACTORTWOPOSESE2 properties:
%       NodeID            - IDs of nodes to connect to in factor graph
%       Measurement       - Measured relative pose [x,y,theta]
%       Information       - Uncertainty of measurement
%
%   Example:
%       % Create a factorTwoPoseSE2 object that specifies two factors. The
%       % first factor connects node 1 and 2. The second factor connects
%       % node 2 and 3.
%       f = factorTwoPoseSE2([1 2; 2 3]);
%       g = factorGraph;
%       addFactor(g,f);
%       % Nodes 1, 2, and 3 are added to the factor graph and connected as
%       % specified by the factors. All nodes are of type "POSE_SE2".
%       nodeType(g,1);
%
%   See also factorGraph.
    
%   Copyright 2021-2022 The MathWorks, Inc.

%#codegen

    properties (Hidden, Constant)
        FactorType = "Two_SE2_F";
    end
    
    methods
        function obj = factorTwoPoseSE2(ids, varargin)
            %FACTORTWOPOSESE2 Constructor
            narginchk(1, Inf);
            obj@nav.algs.internal.FactorGaussianNoiseModel(ids, 2, zeros(1,3), eye(3), varargin{:});
        end
    end

    methods (Access=protected)
        function type = nodeTypeImpl(~, ~)
            type = nav.internal.factorgraph.NodeTypes.SE2;
        end
    end
end

