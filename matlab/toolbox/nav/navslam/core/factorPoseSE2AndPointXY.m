classdef factorPoseSE2AndPointXY < nav.algs.internal.FactorGaussianNoiseModel
%FACTORPOSESE2ANDPOINTXY Factor relating SE(2) pose and 2D point.
%
%   F = FACTORPOSESE2ANDPOINTXY(IDs) returns a factorPoseSE2AndPointXY
%   object, F, that connects two nodes with the identification number IDs.
%   One factor object supports constructing multiple factors at once with
%   multiple node ID sets. IDs is an N-by-2 array where each row is of the
%   form [poseID landmarkID]. N is the number of factors, poseID is robot
%   pose node ID, and landmarkID is the landmark node ID. The measurement
%   represents a relative position [dx,dy]. By default the measurement is
%   set to [0,0] and the corresponding information matrix is set to eye(2).
%   If the nodes with the given IDs do not exist in the factor graph, new
%   nodes with expected types will be initialized and added to the factor
%   graph.
%
%   F = FACTORPOSESE2ANDPOINTXY(...,Name=Value) specifies properties using 
%   one or more name-value arguments.
%
%   FACTORPOSESE2ANDPOINTXY methods:
%       nodeType          - Retrieve the node type for specified node ID
%
%   FACTORPOSESE2ANDPOINTXY properties:
%       NodeID            - IDs of nodes to connect to in factor graph
%       Measurement       - Measured relative position in meters
%       Information       - Uncertainty of measurement
%
%   Example:
%       % Create a factorPoseSE2AndPointXY object that specifies two
%       % factors. The first factor connects node 1 and 2. The second
%       % factor connects node 1 and 3.
%       f = factorPoseSE2AndPointXY([1 2; 1 3]);
%       g = factorGraph;
%       % Add the factor object to the factor graph to create the factors.
%       % Nodes 1, 2, and 3 are added to the factor graph and connected as
%       % specified by the factors.
%       addFactor(g,f);
%       % Node 1 is type "POSE_SE2". Nodes 2 and 3 are type "POINT_XY" and
%       % both connect to Node 1.
%       nodeType(g,1);
%       nodeType(g,2);
%       nodeType(g,3);
%
%   See also factorGraph.
    
%   Copyright 2022 The MathWorks, Inc.

%#codegen

    properties (Hidden, Constant)
        FactorType = "SE2_Point2_F";
    end

    methods
        function obj = factorPoseSE2AndPointXY(ids, varargin)
            %FACTORPOSESE2ANDPOINTXY Constructor
            narginchk(1, Inf);
            obj@nav.algs.internal.FactorGaussianNoiseModel(ids, 2, zeros(1,2), eye(2), varargin{:});
        end
    end

    methods (Access=protected)
        function type = nodeTypeImpl(obj, id)
            % The node in the first column is SE2 type and the second column is Point2.
            [~, col] = find(obj.NodeID == id);
            if col == 1
                type = nav.internal.factorgraph.NodeTypes.SE2;
            else
                type = nav.internal.factorgraph.NodeTypes.Point2;
            end
        end
    end
end

