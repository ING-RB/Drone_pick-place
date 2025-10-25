function H = addnode(G, N)
%ADDNODE Add nodes to a digraph
%   H = ADDNODE(G,nodeNames) returns digraph H that is equivalent to G but
%   with nodes specified by nodeNames added to it. nodeNames must be a string 
%   vector, a character vector, or a cell array of character vectors, and
%    must specify nodes not already present in G.
%
%   H = ADDNODE(G,N) returns digraph H that is equivalent to G but with N
%   nodes added. N must be a nonnegative numeric scalar.
%
%   H = ADDNODE(G,NodeProps) returns digraph H that is equivalent to G but
%   with as many nodes as there are rows in the table NodeProps added to
%   it. NodeProps must be able to be concatenated with G.Nodes.
%
%   Example:
%       % Construct a digraph with named nodes, then add two named nodes.
%       G = digraph({'A' 'B' 'C'},{'D' 'C' 'D'})
%       G.Nodes
%       G = addnode(G,{'E' 'F'})
%       G.Nodes
%
%   Example:
%       % Construct a digraph with four nodes, then add two nodes.
%       G = digraph([1 2 3],[2 3 4])
%       G = addnode(G,2)
%
%   See also DIGRAPH, NUMNODES, RMNODE, ADDEDGE

%   Copyright 2014-2020 The MathWorks, Inc.

H = G;
[H.NodeProperties, newnodes] = addToNodeProperties(G, N);

if newnodes > 0
    nrNodes = numnodes(G) + newnodes;
    if ~ismultigraph(H)
        A = adjacency(H.Underlying, 'transp');
        A(nrNodes, nrNodes) = 0;
        H.Underlying = matlab.internal.graph.MLDigraph(A, 'transp');
    else
        ed = H.Underlying.Edges;
        H.Underlying = matlab.internal.graph.MLDigraph(ed(:, 1), ed(:, 2), nrNodes);
    end
end

if nargout < 1
    warning(message('MATLAB:graphfun:addnode:NoOutput'));
end
