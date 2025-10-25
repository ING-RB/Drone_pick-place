% This class is unsupported and might change or be removed without notice in a
% future version.

% This enumeration class provides classification for different types of
% nodes in a tree representing NetCDF or HDF5 file.

% Copyright 2022-2023 The MathWorks, Inc.

classdef NodeType
    enumeration
        % These nodes correspond to individual entities in a netCDF or HDF5
        % file
        Attribute
        DatasetOrVariable % represents the value
        Group
        Datatype
        Dimension % only in netCDF
        Link % only in HDF5

        % These "cluster" nodes exist to cluster together nodes of the same
        % type, e.g. "Attributes (5)" node containing 5 individual
        % attribute nodes.
        AttributesCluster
        GroupsCluster
        DatatypesCluster
        DatasetsOrVariablesCluster
        DimensionsCluster % only in netCDF
        LinksCluster % only in HDF5

        % Example tree structure with some cluster nodes:
        % Groups (1)              <-- GroupsCluster node
        %  |- raw_observations    <-- Group node
        %    |- Attributes (2)    <-- AttributesCluster node
        %      |- conditions      <-- Attribute node
        %      |- description     <-- Attribute node
        %    |- Variables(1)      <-- DatasetsOrVariablesCluster node
        %      |- wind_speed      <-- DatasetOrVariable node
      
        % This node is the parent of DatasetOrVariable node and
        % AttributesCluster node. It is only present if a variable has
        % attributes (see explanation below).
        DatasetOrVariableWithAtts

        % Variable nodes can be of two types: DatasetOrVariable and
        % DatasetOrVariableWithAtts. If a variable has associated
        % attributes, the node structure looks like this (e.g. for a
        % variable named obs_id):
        %
        % Variabes (1)
        %  |- obs_id     <-- DatasetOrVariableWithAtts node
        %    |- obs_id   <-- DatasetOrVariable node
        %    |- Attributes (2)
        %      |- units
        %      |- long_name
        %
        % If a variable has no associated attributes, it only has a
        % DatasetOrVariable node, e.g.:
        %
        % Variabes (1)
        %  |- obs_id     <-- DatasetOrVariable node
        %
    end

    methods
        % Returns a boolean value signifying whether this is a cluster node
        function tf = isClusterNode(obj)
            import matlab.internal.importsci.NodeType;
            tf = (NodeType.AttributesCluster == obj) || ...
                (NodeType.GroupsCluster == obj) || ...
                (NodeType.DatasetsOrVariablesCluster == obj) || ...
                (NodeType.DatatypesCluster == obj) || ...
                (NodeType.DimensionsCluster == obj) || ...
                (NodeType.LinksCluster == obj);
        end

        % Returns a boolean value signifying whether this node is
        % importable. Importable nodes are nodes for which the import code
        % needs to be generated when they are checked.
        function tf = isImportable(obj)
            import matlab.internal.importsci.NodeType;
            % Cluster nodes, Dimension nodes, or DatasetOrVariableWithAtts
            % nodes cannot be imported.
            % HDF5 Links are importable because we can import dataset
            % links. 
            % HDF5 Datatypes are importable because they can have
            % attributes that can be imported.
            tf = ~obj.isClusterNode() && ~(NodeType.Dimension == obj) &&...
                ~(NodeType.DatasetOrVariableWithAtts == obj);
        end
    end
end