classdef(Hidden) UnaryFactor < nav.algs.internal.FactorGaussianNoiseModel
%This class is for internal use only. It may be removed in the future.

%UNARYFACTOR Represent a general unary factor whose measurement noise
%   follows Gaussian distribution.

%   Copyright 2023 The MathWorks, Inc.

%#codegen

    methods
        function obj = UnaryFactor(ids, numNodes, defaultMeasurement, defaultInformation, varargin )
            %UNARYFACTOR Constructor
            obj@nav.algs.internal.FactorGaussianNoiseModel(ids, numNodes, defaultMeasurement, defaultInformation, varargin{:});
        end

        function type = nodeType(obj, id)
            %nodeType Retrieve the node type for a unary factor.
            %
            %   TYPE = NODETYPE(F) returns the node type, TYPE, for the
            %   node defined by F.
            %   TYPE = NODETYPE(_,ID) returns the node type, TYPE, for the
            %   node with the number ID.

            narginchk(1,2);
            if nargin == 2
                nav.algs.internal.validation.validateNodeID_FactorQuery(id, obj.NodeID, class(obj), 'id');
            end
            type = obj.nodeTypeImpl();
        end
    end

end

