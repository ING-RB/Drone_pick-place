function H = subgraph(G, ind)
%SUBGRAPH Extract a subgraph

%   Copyright 2021 The MathWorks, Inc.
%#codegen

coder.internal.assert(isvector(ind) || isequal(size(ind), [0 0]), ...
    'MATLAB:graphfun:subgraph:InvalidInd');
if islogical(ind)
    coder.internal.assert(isvector(ind) && length(ind) == numnodes(G), ...
        'MATLAB:graphfun:subgraph:InvalidInd');
    ind = ind(:);
else
    ind = validateNodeID(G, ind);
    coder.internal.assert(numel(unique(ind)) == numel(ind), ...
        'MATLAB:graphfun:subgraph:InvalidInd');
end

if ~ismultigraph(G)
    if ~hasEdgeProperties(G)
        N = G.adjacencyTransp();
        N = N(ind, ind);
        % EdgeProperties also track the number of edges, so it needs to be
        % updated. EdgeProperties contains no data, so the indices don't
        % matter.
        if islogical(ind)
            edgeprop = matlab.internal.coder.graphPropertyContainer(G.EdgeProperties, 1:sum(ind));
        else
            edgeprop = matlab.internal.coder.graphPropertyContainer(G.EdgeProperties, 1:numel(ind));
        end
    else
        N = G.adjacencyTransp(1:numedges(G));
        N = N(ind, ind);
        edgeind = edgeIndFromAdjacency(G,N);
        edgeprop = matlab.internal.coder.graphPropertyContainer(G.EdgeProperties, edgeind);
    end
    mlg = G.underlyingConstructorTransp(N);
else
    perm = zeros(1, numnodes(G));
    perm(ind) = 1:nnz(ind);

    ed = perm(G.Underlying.Edges);
    edgeind = find(all(ed, 2));

    ed = ed(edgeind, :);

    if strcmp('graph',G.errTag)
        ed = sort(ed, 2);
    end

    if hasEdgeProperties(G)
        [ed, ei] = sortrows(ed);
        edgeind = edgeind(ei);
        edgeprop = matlab.internal.coder.graphPropertyContainer(G.EdgeProperties, edgeind);
    else
        edgeprop = matlab.internal.coder.graphPropertyContainer(G.EdgeProperties, 1:numel(edgeind));
    end

    mlg = G.underlyingConstructor(ed(:, 1), ed(:, 2), nnz(ind));
end

H = G;
H.Underlying = mlg;
H.EdgeProperties = edgeprop;
H.NodeProperties = matlab.internal.coder.graphPropertyContainer(G.NodeProperties, ind);
end