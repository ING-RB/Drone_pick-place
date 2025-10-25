function sz = dotListLength(G,indexOp,indexContext)
%

%   Copyright 2022-2024 The MathWorks, Inc.

% Initial quick return statements, based on tabular/dotListLength.
if isscalar(indexOp)
    % G.Nodes / G.Edges
    sz = 1;
    return
elseif indexOp(2).Type == matlab.indexing.IndexingOperationType.Dot
    % G.Nodes.prop[...] / G.Edges.prop[...]
    if length(indexOp) == 2
        % G.Nodes.prop / G.Edges.prop
         % table returns one variable for dot
        sz = 1;
        return
    elseif indexContext == matlab.indexing.IndexingContext.Assignment
        % G.Nodes.prop[...] = rhs / G.Edges.prop[...] = rhs
         % table assignment only ever accepts one rhs value
        sz = 1;
        return
    end
end

if strcmp(indexOp(1).Name, 'Edges')
    % G.Edges[...]
    if indexOp(2).Type == matlab.indexing.IndexingOperationType.Dot
        % G.Edges.prop[...]
        % Short-circuit to EdgeProperties if appropriate.
        S2name = indexOp(2).Name;
        edges = G.EdgeProperties;
        if strcmp(S2name, 'Weight') && isnumeric(edges) && iscolumn(edges)
            % G.Edges.Weight[...]
            sz = 1;
        elseif matches(S2name, 'EndNodes')
            % G.Edges.EndNodes[...]
            [names, hasNodeNames] = getNodeNames(G);
            if hasNodeNames
                % EndNodes is a cell array, could be complicated
                EndNodes = G.Underlying.Edges;
                edges = reshape(names(EndNodes), [], 2);
                sz = listLength(edges, indexOp(3:end), indexContext);
            else
                sz = 1;
            end
        elseif matches(S2name, 'Properties')
            % G.Edges.Properties[...]
            edges = getEdgesTable(G);
            sz = listLength(edges, indexOp(2:end), indexContext);
        else
            % G.Edges.(prop)
            edges = getEdgePropertiesTable(G);
            sz = listLength(edges, indexOp(2:end), indexContext);
        end
    else
        % G.Edges(...)[...] or G.Edges{...}[...]
        edges = getEdgesTable(G);
        sz = listLength(edges, indexOp(2:end), indexContext);
    end
    
elseif strcmp(indexOp(1).Name, 'Nodes')
    % G.Nodes[...]

    if indexOp(2).Type == matlab.indexing.IndexingOperationType.Dot && ...
            strcmp(indexOp(2).Name, 'Name')
        % G.Nodes.Name[...]
        % Short-circuit to minimized NodeProperties if appropriate.
        nodeprop = G.NodeProperties;
        if iscell(nodeprop)
            % G.Nodes.Name{...}
            indexOp = indexOp(3:end);
            sz = listLength(nodeprop, indexOp, indexContext);
            return
        end
    end

    % G.Nodes[...]
    % (no special-case for 'Properties' needed here, since
    % NodePropertiesTable is just the Nodes table)
    nodeprop = getNodePropertiesTable(G);
    sz = listLength(nodeprop, indexOp(2:end), indexContext);
else
    % G.(notNodesOrEdges)[...]
    % Error out, doesn't matter what size we return
    sz = 1;
end
