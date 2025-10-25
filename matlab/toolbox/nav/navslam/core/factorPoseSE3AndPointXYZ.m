classdef factorPoseSE3AndPointXYZ < nav.algs.internal.FactorGaussianNoiseModel
%FACTORPOSESE3ANDPOINTXYZ Factor relating SE(3) pose and 3D point.
%
%   F = FACTORPOSESE3ANDPOINTXYZ(IDs) returns a factorPoseSE3AndPointXYZ
%   object, F, that connects two nodes with the identification number IDs.
%   One factor object supports constructing multiple factors at once with
%   multiple node ID sets. IDs is an N-by-2 array where each row is of the
%   form [poseID landmarkID]. N is the number of factors, poseID is robot
%   pose node ID, and landmarkID is the landmark node ID. The measurement
%   represents a relative position [dx,dy,dz]. By default the measurement
%   is set to [0,0,0] and the corresponding information matrix is set to
%   eye(3). If the nodes with the given IDs do not exist in the factor
%   graph, new nodes with expected types will be initialized and added to
%   the factor graph.
%
%   F = FACTORPOSESE3ANDPOINTXYZ(...,Name=Value) specifies properties 
%   using one or more name-value arguments.
%
%   FACTORPOSESE3ANDPOINTXYZ methods:
%       nodeType          - Retrieve the node type for specified node ID
%
%   FACTORPOSESE3ANDPOINTXYZ properties:
%       NodeID            - IDs of nodes to connect to in factor graph
%       Measurement       - Measured relative position in meters
%       Information       - Uncertainty of measurement
%
%   Example:
%       % Create a factorPoseSE3AndPointXYZ object that specifies two
%       % factors. The first factor connects node 1 and 2. The second
%       % factor connects node 1 and 3.
%       f = factorPoseSE3AndPointXYZ([1 2; 1 3]);
%       g = factorGraph;
%       % Add the factor object to the factor graph to create the factors.
%       % Nodes 1, 2, and 3 are added to the factor graph and connected as
%       % specified by the factors.
%       addFactor(g,f);
%       % Node 1 is type "POSE_SE3". Nodes 2 and 3 are type "POINT_XYZ"
%       % and both connect to Node 1.
%       nodeType(g,1);
%       nodeType(g,2);
%       nodeType(g,3);
%
%   See also factorGraph.
    
%   Copyright 2022 The MathWorks, Inc.

%#codegen

    properties (Hidden, Constant)
        FactorType = "SE3_Point3_F";
    end
    
    methods
        function obj = factorPoseSE3AndPointXYZ(ids, varargin)
            %FACTORPOSESE3ANDPOINTXYZ Constructor
            narginchk(1, Inf);
            obj@nav.algs.internal.FactorGaussianNoiseModel(ids, 2, zeros(1,3), eye(3), varargin{:});
        end
    end

    methods (Access=protected)
        function type = nodeTypeImpl(obj, id)
            % The node in the first column is SE3 type and the second column is Point3.
            [~, col] = find(obj.NodeID == id);
            if col == 1
                type = nav.internal.factorgraph.NodeTypes.SE3;
            else
                type = nav.internal.factorgraph.NodeTypes.Point3;
            end
        end
    end
end

