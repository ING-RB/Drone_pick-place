function [mf,GF,cs,ct] = maxflow(G,s,t,algorithm)
%MAXFLOW Maximum flow in a directed graph
%   MF = MAXFLOW(G,S,T) returns the maximum flow between two nodes S and T.
%   MF is equal to zero if no flow exists between nodes S and T.
%
%   All edge weights must be non-negative. If the digraph G has no weights,
%	MAXFLOW treats all edges as having weight equal to 1.
%
%   MF = MAXFLOW(G,S,T,ALGORITHM) specifies the maximum flow algorithm.
%   ALGORITHM can be:
%     'searchtrees' - (default) Computes the maximum flow by constructing
%                     two search trees associated with nodes S and T. Uses
%                     the Boykov-Kolmogorov algorithm.
%     'augmentpath' - Computes the maximum flow iteratively by finding an
%                     augmenting path in a residual digraph. Uses the
%                     Ford-Fulkerson algorithm.
%                     The digraph must not contain a two-cycle formed by
%                     two edges with two non-zero weights.
%     'pushrelabel' - Computes the maximum flow by pushing a node's excess
%                     flow to its neighbors and then relabeling the node.
%                     The digraph must not contain a two-cycle formed by
%                     two edges with two non-zero weights.
%
%   [MF,GF] = MAXFLOW(...) also returns a digraph of flows GF formed only
%   from those edges of G that have non-zero flow values.
%
%   [MF,GF,CS,CT] = MAXFLOW(...) also returns two vectors of node ids, CS
%   and CT, representing a minimum cut associated with the maximum flow.
%   A minimum cut partitions the digraph nodes into two sets CS and CT,
%   such that the sum of the weights of all edges connecting CS and CT
%   (weight of the cut) is minimized.
%   The entries of CS indicate the nodes of G associated with node S.
%   The entries of CT indicate the nodes of G associated with node T.
%   The weight of the minimum cut is equal to the maximum flow value MF
%   and NUMEL(CS) + NUMEL(CT) = NUMNODES(G).
%
%   Example:
%       % Create and plot a weighted digraph whose edge weights represent
%       % flow capacities. Compute the maximum flow from node 1 to node 6.
%       s = [1 1 2 2 3 4 4 4 5 5];
%       t = [2 3 3 4 5 3 5 6 4 6];
%       weights = [0.77 0.44 0.67 0.75 0.89 0.90 2 0.76 1 1];
%       G = digraph(s,t,weights);
%       plot(G,'EdgeLabel',G.Edges.Weight)
%       mf = maxflow(G,1,6)
%
%   See also DIGRAPH

%   Copyright 2014-2021 The MathWorks, Inc.


numericSorT = isnumeric(s) || isnumeric(t);
stringSorT = isstring(s) || isstring(t);
s = validateNodeID(G,s);
t = validateNodeID(G,t);
if nargin > 3
    if ~digraph.isvalidoption(algorithm)
        error(message('MATLAB:graphfun:maxflow:InvalidAlgorithm'));
    end
    alglist = ["searchtrees","augmentpath","pushrelabel"];
    alg = find(digraph.partialMatch(algorithm, alglist));
    if isempty(alg)
        error(message('MATLAB:graphfun:maxflow:InvalidAlgorithm'));
    end
else
    alg = 1;
end

if ismultigraph(G)
    edgeind = matlab.internal.graph.simplifyEdgeIndex(G.Underlying);
    [w, hasEdgeWeights] = getEdgeWeights(G); % Returns [] if there are no weights.
    if hasEdgeWeights
        w = accumarray(edgeind, w);
    else
        w = accumarray(edgeind, 1);
    end
else
    [w, hasEdgeWeights] = getEdgeWeights(G); % Returns [] if there are no weights.
    if ~hasEdgeWeights
        w = ones(numedges(G),1);
    end
end

A = adjacency(G.Underlying, 'transp');

switch alg
    case 1  % searchtrees
        
        [Gsym,w] = symmetrizeDigraph(A,w);
        % Remove self-loops
        nnodes = G.Underlying.NodeCount;
        allnodes = 1:nnodes;
        idx = findedge(Gsym,allnodes,allnodes);
        if any(idx > 0)
            A = adjacency(Gsym, 'transp');
            A(1:nnodes+1:end) = 0;
            Gsym = matlab.internal.graph.MLDigraph(A, 'transp');
            
            idx(idx == 0) = [];
            w(idx) = [];
        end
        
        if nargout == 1
            mf = boykovKolmogorovMaxFlow(Gsym,s,t,w);
        elseif nargout == 2
            [mf,fST,fW] = boykovKolmogorovMaxFlow(Gsym,s,t,w);
        else
            [mf,fST,fW,cs,ct] = boykovKolmogorovMaxFlow(Gsym,s,t,w);
        end
        
    case 2  % augmentpath
        
        [Gsym,w] = symmetrizeDigraph(A,w);
        if nargout == 1
            mf = fordFulkersonMaxFlow(Gsym,s,t,w);
        elseif nargout == 2
            [mf,fST,fW] = fordFulkersonMaxFlow(Gsym,s,t,w);
        else
            [mf,fST,fW,cs,ct] = fordFulkersonMaxFlow(Gsym,s,t,w);
        end
        
    otherwise % pushrelabel
        
        [Gsym,w] = symmetrizeDigraph(A,w);
                
        if nargout == 1
            mf = pushRelabelMaxFlow(Gsym,s,t,w);
        elseif nargout == 2
            [mf,fST,fW] = pushRelabelMaxFlow(Gsym,s,t,w);
        else
            [mf,fST,fW,rST,rW] = pushRelabelMaxFlow(Gsym,s,t,w);
            if isempty(rST)
                cs = s;
            else
                RG = digraph(rST(:,1),rST(:,2),rW);
                cs = dfsearch(RG, s);
                cs = sort(cs);
            end
            ct = (1:numnodes(G)).';
            ct(cs) = [];
        end
        if nargout > 1
            % Remove all edges that involve nodes which aren't on a path
            % from s to t.
            isNodeOnPath = nodesOnPath(G.Underlying,s,t);
            ind = ~all(isNodeOnPath(fST), 2);
            fST(ind, :) = [];
            fW(ind) = [];
        end
end

names = getNodeNames(G);

% Construct the resulting subgraph of non-zero flows.
if nargout > 1
    if mf ~= inf
        if ~numericSorT
            GF = digraph(fST(:,1),fST(:,2),fW,names);
        else
            GF = digraph(fST(:,1),fST(:,2),fW,numnodes(G));
        end
    else
        GF = adjustInfFlows(G,Gsym,s,t,w,numericSorT);
        if nargout > 2
            cs = s;
            ct = (1:numnodes(G)).';
            ct(cs) = [];
        end
    end
end
if nargout > 2 && ~numericSorT
    cs = names(cs);
    ct = names(ct);
    if stringSorT
       cs = string(cs);
       ct = string(ct);
    end
end

%--------------------------------------------------------------------------
function [Gsym, weightsGsym] = symmetrizeDigraph(A,w)
% SYMMETRIZEDIGRAPH Symmetrize the adjacency matrix A of input digraph G.
% If G contains the edge [i,j] but does not contain the reverse edge [j,i],
% then the reverse edge [j,i] with a zero weight is added in the
% symmetrized digraph. Uses the fact that A has only 0 and 1 entries.
if issymmetric(A)
    Gsym = matlab.internal.graph.MLDigraph(A, 'transp');
    weightsGsym = w;
else
    wmarker = 10; % ~= 0, ~= 1
    Asym = wmarker.*A + A.';
    Gsym = matlab.internal.graph.MLDigraph(Asym, 'transp');
    weightsGsym = nonzeros(Asym);
    if isa(w,'single')
        weightsGsym = single(weightsGsym);
    end
    idx = (weightsGsym >= wmarker);
    weightsGsym( idx) = w; % original weights
    weightsGsym(~idx) = 0; % new reverse edges
end
%--------------------------------------------------------------------------
% ADJUSTINFEDGEFLOWS When the maxflow value is Inf, return the shortestpath
% tree with all Inf weights.
function GF = adjustInfFlows(G,Gsym,s,t,w,numericSorT)
eind = find(w == Inf);
e = Gsym.Edges(eind,:);
if ~numericSorT
    Ginf = digraph(e(:,1),e(:,2),w(eind),getNodeNames(G));
else
    Ginf = digraph(e(:,1),e(:,2),w(eind),numnodes(G));
end
GF = shortestpathtree(Ginf,s,t);

function isNodeRelevant = nodesOnPath(G,s,t)
% Exclude some nodes that can't be on a path from s to t explicitly, to
% eliminate some edges in GF with round-off size flows that make no sense.

% Prevent path from passing through t by setting all its outedges to inf.
wMask = ones(numedges(G), 1);
wMask(outedges(G, t)) = Inf;

% Check for each node if it's reachable from node s without passing through
% node t. If not, no edge of this node should be part of GF.
isNodeRelevant = isfinite(dijkstraAllShortestPaths(G, wMask, s, 'all'))';

% If node t is not reachable from node s, no node is relevant since there
% can't be any flow.
if ~isNodeRelevant(t)
    isNodeRelevant(:) = false;
end
