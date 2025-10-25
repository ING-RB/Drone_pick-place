function H = rmedge(G, s, t)
%RMEDGE Remove edges from a graph or digraph

%   Copyright 2021 The MathWorks, Inc.
%#codegen

H = G;
coder.varsize('ind',[inf,1],[1,0]);
% Determine the indices of the edges to be removed.
if nargin == 2
    coder.internal.assert(isnumeric(s),'MATLAB:graphfun:findedge:nonNumericEdges');
    coder.internal.assert(isreal(s),'MATLAB:graphfun:findedge:CodegenComplexEdges');
    if isempty(s)
        ind = zeros(0,1,'like',s);
    else
        ind = reshape(s, [], 1);
    end
    currentNumEdges = numedges(G);
    for ii = coder.internal.indexInt(1):numel(ind)
        currentInd = ind(ii);
        coder.internal.assert(fix(currentInd)==currentInd && ...
            currentInd >= 1 && currentInd <= currentNumEdges, ...
            'MATLAB:graphfun:findedge:EdgeBounds', numedges(G));
    end
else
    ind = findedge(G, s, t);
    ind(ind == 0) = [];
end

% Remove edges from the graph.
if ~ismultigraph(G)
    % Convert the edge indices to pairs of Node IDs.
    [s, t] = findedge(G, ind);
    A = H.adjacencyTransp();

    if strcmp(G.errTag,'digraph')
        A(sub2ind([numnodes(H), numnodes(H)], t, s)) = 0;
    else
        A(sub2ind([numnodes(H), numnodes(H)], [s; t], [t; s])) = 0;
    end
    H.Underlying = G.underlyingConstructorTransp(A);
else
    ed = H.Underlying.Edges;
    ed(ind, :) = [];
    H.Underlying = G.underlyingConstructor(ed(:, 1), ed(:, 2), numnodes(H));
end

H.EdgeProperties = H.EdgeProperties.remove(ind);
if nargout < 1
    coder.internal.compileWarning('MATLAB:graphfun:rmedge:NoOutput');
end
