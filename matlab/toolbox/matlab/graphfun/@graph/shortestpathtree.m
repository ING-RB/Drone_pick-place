function [tree, d, isTreeEdge] = shortestpathtree(G, s, varargin)
% SHORTESTPATHTREE Compute the shortest path tree from a node
%
%   TREE = SHORTESTPATHTREE(G,S) returns digraph TREE containing the tree
%   composed of the shortest paths from S to all other nodes in the graph.
%   If the graph is weighted (that is, G.Edges contains a Weight variable),
%   then those weights are used as the distances along the edges in the
%   graph. Otherwise, all edge distances are taken to be 1.
%
%   [TREE,D] = SHORTESTPATHTREE(G,S) also returns vector D, where D(j) is
%   the length of the shortest path from node S to node j.
%
%   [TREE,D] = SHORTESTPATHTREE(G,S,T) computes the shortest path tree
%   between source nodes S and target nodes T. Either S or T must be a
%   single node ID (there can be several source nodes OR several target
%   nodes, but not both). S and T can be vectors of numeric node IDs, string
%   vectors, cell arrays of character vectors, or 'all' to represent the
%   set of all nodes, 1:numnodes(G). If there are several target nodes, then the
%   distance to T(j) is D(j). If there are several source nodes, then the
%   distance from S(j) is D(j). By default T is 'all'.
%
%   [TREE,D,EDGEINTREE] = SHORTESTPATHTREE(___) also returns a logical
%   vector that indicates whether each edge is in the tree. This is useful
%   when there are several edges between the same two nodes.
%
%   [TREE,D,EDGEINTREE] = SHORTESTPATHTREE(...,'OutputForm',OUTPUTFLAG)
%   optionally controls the format of output TREE.
%   OUTPUTFLAG can be:
%
%         'tree'  -  TREE is a digraph representing the shortest path tree.
%                    EDGEINTREE is a logical vector indicating if an edge
%                    is in the tree.
%                    This form is the default.
%
%         'cell'  -  TREE is a cell array where TREE{k} represents the path
%                    from source node S to target node T(k) (or from source
%                    node S(k) to target node T). TREE{k} can be a numeric vector,
%                    a string vector, or a cell array of character vectors,
%                    depending on the types of S and T.
%                    EDGEINTREE is a cell array where EDGEINTREE{k} is a
%                    vector containing the edge indices of all edges on
%                    the path TREE{k}.
%                    TREE{k} and EDGEINTREE{k} are empty if node k is not
%                    part of the tree.
%
%       'vector'  -  Compact representation where TREE is a vector that
%                    describes the tree:
%                      * If S contains a single source node, then TREE(k)
%                        is the ID of the node that precedes node k on the
%                        path from S to k. TREE(s) = 0 by convention.
%                      * If S contains multiple source nodes, then TREE(k)
%                        is the ID of the node that succeeds node k on the
%                        path from k to T. TREE(t) = 0 by convention.
%                     In each case TREE(k) is NaN if node k is not part of
%                     the tree.
%                     EDGEINTREE(k) is the edge ID of the edge connecting
%                     node TREE(k) and node k.
%
%   [TREE,D] = SHORTESTPATHTREE(...,'Method',METHODFLAG) optionally
%   specifies the method to use in computing the shortest path.
%   METHODFLAG can be:
%
%         'auto'  -  Uses 'unweighted' if no weights are set, and
%                    'positive' otherwise. This method is the default.
%
%   'unweighted'  -  Treats all edge weights as 1.
%
%     'positive'  -  Requires all edge weights to be positive.
%
%   Example:
%       % Create and plot a graph. Compute and highlight the shortest path
%       % tree from node 1 of the graph.
%       s = [1 1 2 3 3 4 4 6 6 7 8 7 5];
%       t = [2 3 4 4 5 5 6 1 8 1 3 2 8];
%       G = graph(s,t);
%       G.Edges
%       tree = shortestpathtree(G,1)
%       tree.Edges
%       p = plot(G);
%       highlight(p,tree)
%
%   Example:
%       % Create and plot a graph. Compute and highlight the shortest path
%       % tree from subset [1 3 4] of the nodes to node 8.
%       s = [1 1 2 3 3 4 4 6 6 7 8 7 5];
%       t = [2 3 4 4 5 5 6 1 8 1 3 2 8];
%       G = graph(s,t);
%       G.Edges
%       tree = shortestpathtree(G,[1 3 4], 8)
%       tree.Edges
%       p = plot(G);
%       highlight(p,tree)
%
%   See also SHORTESTPATH, DISTANCES, DIGRAPH/SHORTESTPATHTREE

%   Copyright 2014-2024 The MathWorks, Inc.

[src, target, method, pathFormat, outputNodeNames, outputString] = parseInput(G, s, varargin{:});

if ~isscalar(src) && ~isscalar(target)
    error(message('MATLAB:graphfun:shortestpathtree:AllToAll'));
end

if method == "unweighted"
    w = [];
else
    w = getEdgeWeights(G);
end

if ~isscalar(src)
    reverseDirection = true;
    singleNode = target;
    subset = src;
else
    reverseDirection = false;
    singleNode = src;
    subset = target;
end

[d, pred, edgepred] = applyOneToAll(G.Underlying, w, singleNode, subset, method);

% target represents a subset (that is, target is not 'all')
if ~ischar(subset)
    d = d(subset);
    
    % find all nodes of the subtree between singleNode and subset
    ind = findSubtree(pred, singleNode, subset);
    pred(~ind) = NaN;
    edgepred(~ind) = NaN;
end

[tree, isTreeEdge] = constructTree(G, pred, edgepred, singleNode, subset, ...
    pathFormat, outputNodeNames, outputString, reverseDirection);


function [d, pred, edgepred] = applyOneToAll(H, w, src, target, methodStr)

if methodStr == "auto"
    if isempty(w) || all(w == 1)
        methodStr = "unweighted";
    else
        methodStr = "positive";
    end
end

if methodStr == "unweighted"
    [d, pred, edgepred] = bfsShortestPaths(H, src, target, Inf);
    return;
end

if isempty(w)
    w = ones(H.EdgeCount, 1);
end
if any(w < 0)
    error(message('MATLAB:graphfun:shortestpathtree:NegativeWeights'));
end
[d, pred, edgepred] = dijkstraShortestPaths(H, w, src, target, Inf);


function ind = findSubtree(pred, singleNode, subset)

ind = false(size(pred));
ind(subset) = true;

tmp = pred(ind);
addNodes = tmp(tmp>0);
while ~isempty(addNodes)
    ind(addNodes) = true;
    tmp = pred(addNodes);
    addNodes = tmp(tmp>0);
end
ind(singleNode) = true;


function [tree, isTreeEdge] = constructTree(G, pred, edgepred, singleNode, subset, ...
    pathFormat, outputNodeNames, outputString, reverseDirection)

if pathFormat == "vector"
    tree = pred;
    isTreeEdge = edgepred;
elseif pathFormat == "cell"
    tree = cell(numnodes(G), 1);
    isTreeEdge = cell(numnodes(G), 1);
    indRootToLeafs = findRootToLeafsOrder(pred, singleNode);
    for k=indRootToLeafs
        if pred(k) == 0
            tree{k} = k;
            isTreeEdge{k} = zeros(1, 0);
        elseif ~isnan(pred(k))
            tree{k} = [tree{pred(k)}, k];
            isTreeEdge{k} = [isTreeEdge{pred(k)}, edgepred(k)];
        end
    end
    for k = 1:numnodes(G)
        if reverseDirection
            tree{k} = flip(tree{k});
            isTreeEdge{k} = flip(isTreeEdge{k});
        end
        if outputNodeNames
            names = getNodeNames(G);
            tree{k} = names(tree{k}).';
            if outputString
                tree{k} = string(tree{k});
            end
        end
    end
    if ~ischar(subset)
        tree = tree(subset);
        isTreeEdge = isTreeEdge(subset);
    end
else % pathFormat == "tree"
    heads = pred(pred>0);
    tails = 1:numel(pred);
    tails = tails(pred>0);
    if hasNodeProperties(G)
        nodeprops = G.NodeProperties;
    else
        nodeprops = numnodes(G); % Set number of nodes in output tree.
    end
    if hasEdgeProperties(G)
        edgeprops = G.EdgeProperties(edgepred(edgepred>0), :);
    else
        edgeprops = [];
    end
    if reverseDirection
        tree = digraph(tails, heads, edgeprops, nodeprops);
    else
        tree = digraph(heads, tails, edgeprops, nodeprops);
    end
    isTreeEdge = false(numedges(G), 1);
    isTreeEdge(edgepred(edgepred>0)) = true;
end

function indRootToLeafs = findRootToLeafsOrder(pred, singleNode)

heads = pred(pred>0);
tails = 1:numel(pred);
tails = tails(pred>0);
n = numel(pred);

T = matlab.internal.graph.MLDigraph(heads, tails, n);

events = [true, false(1, 5)];
indRootToLeafs = breadthFirstSearch(T, singleNode, events, false, false).';


function [src, target, method, pathFormat, outputNodeNames, outputString] = parseInput(G, s, varargin)

target = 'all';
method = 'auto';
pathFormat = 'tree';
outputNodeNames = false;
outputString = false;

% Parse first input source
if ~isNodeName(s, {'all'}, G) && strcmpi(s, 'all')
    src = 'all';
else
    src = validateNodeID(G, s);
    if ~allunique(src)
        error(message('MATLAB:graphfun:shortestpathtree:DuplicateSRC'));
    end
    if ~isnumeric(s)
        outputNodeNames = true;
        outputString = isstring(s);
    end
end

if numel(varargin) == 0
    return;
end

% Parse second input (check if this represents a subset of nodes)
t = varargin{1};
if isNodeName(t, {'all', 'Method', 'OutputForm'}, G)
    target = validateNodeID(G, t);
    if ~allunique(target)
        error(message('MATLAB:graphfun:shortestpathtree:DuplicateTARG'));
    end
    varargin(1) = [];
    if ~isnumeric(t)
        outputNodeNames = true;
        outputString = outputString || isstring(t);
    end
elseif strcmpi(t, 'all')
    varargin(1) = [];
end

if numel(varargin) == 0
    return;
end

% Parse trailing arguments (name-value pairs)
for ii=1:2:numel(varargin)
    name = varargin{ii};
    if ~graph.isvalidoption(name)
        error(message('MATLAB:graphfun:shortestpathtree:ParseFlags'));
    end
    
    if graph.partialMatch(name, "Method")
        if ii+1 > numel(varargin)
            error(message('MATLAB:graphfun:shortestpathtree:KeyWithoutValue', 'Method'));
        end
        value = varargin{ii+1};
        if ~graph.isvalidoption(value)
            error(message('MATLAB:graphfun:shortestpathtree:ParseMethodUndir'));
        end
        
        methodNames = ["positive", "unweighted", "auto"];
        match = graph.partialMatch(value, methodNames);
        
        if nnz(match) == 1
            method = methodNames(match);
        else
            error(message('MATLAB:graphfun:shortestpathtree:ParseMethodUndir'));
        end
    elseif graph.partialMatch(name, "OutputForm")
        if ii+1 > numel(varargin)
            error(message('MATLAB:graphfun:shortestpathtree:KeyWithoutValue', 'OutputForm'));
        end
        value = varargin{ii+1};
        if ~graph.isvalidoption(value)
            error(message('MATLAB:graphfun:shortestpathtree:ParseOutput'));
        end
        if graph.partialMatch(value, "cell")
            pathFormat = "cell";
        elseif graph.partialMatch(value, "tree")
            pathFormat = "tree";
        elseif graph.partialMatch(value, "vector")
            pathFormat = "vector";
        else
            error(message('MATLAB:graphfun:shortestpathtree:ParseOutput'));
        end
    else
        error(message('MATLAB:graphfun:shortestpathtree:ParseFlags'));
    end
end


function tf = isNodeName(arg, NVpairs, G)

[names, hasNodeNames] = getNodeNames(G);

if ~( (ischar(arg) && isrow(arg)) || (isstring(arg) && isscalar(arg)) )
    % Not correct size and type for an NV-pair
    tf = true;
elseif ~hasNodeNames
    % Graph has no node names
    tf = false;
elseif ismember(arg, NVpairs)
    % Count as an NV-pair if it matches exactly (even upper/lower case)
    tf = false;
elseif ismember(arg, names)
    % Count as node name if this is matched exactly
    tf = true;
elseif any(graph.partialMatch(arg, NVpairs))
    % Partial match on a Name-Value pair
    tf = false;
else
    % Neither a valid node input nor a valid Name-Value pair.
    % Generate error messages assuming input is a node name.
    tf = true;
end
