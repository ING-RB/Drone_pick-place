function H = rmnode(G, N)
%RMNODE Remove nodes

%#codegen
%   Copyright 2021 The MathWorks, Inc.

ind = unique(findnode(G, N));
keepNode = setxor((1:numnodes(G))',ind(:)); %FIXME
keepNode(keepNode == 0) = [];
% Normally ind would need to be sorted for codegen setxor but unique takes
% care of that.

if ~ismultigraph(G)
    N = G.adjacencyTransp(1:numedges(G));
    N = N(keepNode, keepNode);
    mlg = G.underlyingConstructorTransp(N);
    edgeind = edgeIndFromAdjacency(G,N)'; % Transpose is needed to make the shape of edgeind consistent
else
    % Determine mapping from old to new node indices
    perm = zeros(1, numnodes(G));
    perm(keepNode) = 1:numel(keepNode);
    
    % Determine which edges are kept
    ed = perm(G.Underlying.Edges);
    tmp = 1:size(ed,1);
    edgeind = tmp(all(ed > 0, 2));
    
    mlg = G.underlyingConstructor(ed(edgeind, 1), ed(edgeind, 2), numel(keepNode));
end
edgesToRemove = setxor(1:size(G.Underlying.Edges,1),sort(edgeind));

H = G;
H.EdgeProperties = H.EdgeProperties.remove(edgesToRemove); %FIXME make remove take logical indices
H.NodeProperties = H.NodeProperties.remove(ind);
H.Underlying = mlg;

if nargout < 1
    coder.internal.compileWarning('MATLAB:graphfun:rmnode:NoOutput');
end
end