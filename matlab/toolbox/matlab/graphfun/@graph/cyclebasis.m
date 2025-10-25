function [cycles, edgecycles] = cyclebasis(G)
% CYCLEBASIS Compute fundamental cycle basis of graph
%   CYCLES = CYCLEBASIS(G) computes a fundamental cycle basis of graph G.
%   CYCLES is a cell array in which CYCLES{i} is a vector of numeric node
%   IDs (if G does not have node names) or a cell array of character
%   vectors (if G has node names). Every cycle in G is a combination of the
%   cycles in CYCLES. If an edge is part of a cycle in G, then it is also
%   part of at least one cycle in CYCLES. Each cycle in CYCLES begins with
%   the smallest node index. If G is acyclic, then CYCLES is empty.
%
%   [CYCLES, EDGECYCLES] = CYCLEBASIS(G) also returns a cell array
%   EDGECYCLES in which EDGECYCLES{i} contains the edges in the cycle
%   CYCLES{i} of G.
%
%   See also ALLCYCLES, HASCYCLES, ALLPATHS

%   Copyright 2020-2021 The MathWorks, Inc.

if numedges(G) == 0
    cycles = cell(0, 1);
    edgecycles = cell(0, 1);
    return
end

% Reordering
[~, reIdx] = sort(degree(G), 'descend');
[H, HEdgesIdx] = reordernodes(G, reIdx);
[~, HTreeEdges] = bfsearch(H, 1, 'edgetonew', 'restart', true);

% Find treeEdgesIdx and build the tree
treeEdgesIdx = sort(HEdgesIdx(HTreeEdges));
[treeEdgesSrc, treeEdgesTgt]= findedge(G, treeEdgesIdx);

% Compute a spanning tree using breadth-first search
T = graph(treeEdgesSrc, treeEdgesTgt, [], numnodes(G));

% Find cycles and edgecycles
nonTreeEdgesIdx = setdiff(1:numedges(G), treeEdgesIdx);
cycles = cell(length(nonTreeEdgesIdx), 1);
edgecycles = cell(length(nonTreeEdgesIdx), 1);
if isempty(cycles)
    return
end

% Compute paths in tree T, from a root node to all other nodes. This allows
% us to compute paths between two nodes in T more quickly.
bins = conncomp(G);
if nargout < 2
    pathFromRoot = pathfromroot_helper(T, bins);
else
    [pathFromRoot, edgeFromRoot] = pathfromroot_helper(T, bins);
end

% Go through each non-tree edge, compute the path through T that connects
% its two end nodes, then return the cycle formed by this path combined
% with the edge.
[allSrc, allTgt] = findedge(G, nonTreeEdgesIdx);
for i = 1:length(cycles)
    src = allSrc(i);
    tgt = allTgt(i);
    if nargout < 2
        c = shortestpath_helper(pathFromRoot, [], src, tgt);
    else
        [c, e] = shortestpath_helper(pathFromRoot, edgeFromRoot, src, tgt);
    end
    
    % Standardize such that the first node listed is always the minimal
    % one.
    [~, idx] = min(c);
    c = [c(idx:end), c(1:idx-1)];
    
    % Standardize direction of the loop: From initial node, always move
    % towards the neighboring node with smallest ID.
    if length(c) > 1 && c(2) <= c(end)
        cycles{i} = c;
    else
        cycles{i} = [c(1) c(end:-1:2)];
    end
    
    if nargout >= 2
        eTemp = [treeEdgesIdx(e)', nonTreeEdgesIdx(i)];
        eTemp = [eTemp(idx:end), eTemp(1:idx-1)];
        
        % Standardize direction for edges: From initial node, always move
        % along edge with smallest ID.
        if eTemp(1) <= eTemp(end)
            edgecycles{i} = eTemp;
        else
            edgecycles{i} = flip(eTemp);
        end
    end
end

% Sort cycles and edgecycles
M = cyclesToMatrix(cycles);
if nargout > 1
    M = [M cyclesToMatrix(edgecycles)];
end
[~, idx] = sortrows(M);
cycles = cycles(idx);

if nargout > 1
    edgecycles = edgecycles(idx);
end

% Name nodes
[names, hasNodeNames] = getNodeNames(G);
names = names.';
if hasNodeNames
    for i = 1:size(cycles, 1)
        cycles{i} = names(cycles{i});
    end
end
end

% Return a matrix where each row contains one of the cycles, padded with
% zeros.
function M = cyclesToMatrix(cycles)
n = length(cycles);
lens = cellfun('length', cycles);
M = zeros(n, max(lens));
for i = 1:n
    M(i, 1:lens(i)) = cycles{i};
end
end

% Compute the path from node src to node tgt through the tree T, using the
% precomputed paths from both src and tgt to the root node.
function [path, edge] = shortestpath_helper(pathFromRoot, edgeFromRoot, src, tgt)
pathRoot2S = pathFromRoot{src};
pathRoot2T = pathFromRoot{tgt};

% Determine the number of shared nodes between pathRoot2S and pathRoot2T
lenS = length(pathRoot2S);
lenT = length(pathRoot2T);
numSharedNodes = 1;
while numSharedNodes < min(lenS, lenT) && pathRoot2S(numSharedNodes+1) == pathRoot2T(numSharedNodes+1)
    numSharedNodes = numSharedNodes+1;
end

% Combine pathRoot2S and pathRoot2T to obtain path
path = zeros(1, lenS+lenT-2*numSharedNodes+1);
for k = 1:lenS-numSharedNodes+1
    path(k) = pathRoot2S(end-k+1);
end
for j = 1:lenT-numSharedNodes
    path(lenS-numSharedNodes+j+1) = pathRoot2T(numSharedNodes+j);
end

if nargout > 1
    edgeRoot2S = edgeFromRoot{src};
    edgeRoot2T = edgeFromRoot{tgt};
    
    % Combine edgeRoot2S and edgeRoot2T to obtain edgepath
    edge = zeros(1, lenS+lenT-2*numSharedNodes);
    for k = 1:lenS-numSharedNodes
        edge(k) = edgeRoot2S(end-k+1);
    end
    for j = 1:lenT-numSharedNodes
        edge(lenS-numSharedNodes+j) = edgeRoot2T(numSharedNodes+j-1);
    end
end
end

% Chooses a root node and computes paths from that root node to all other
% nodes. pathFromRoot{i} is the path from the root node to node i, and
% edgeFromRoot{i} is the corresponding edge path.
function [pathFromRoot, edgeFromRoot] = pathfromroot_helper(T, bins)
n = length(bins);
numComponents = max(bins);
if numComponents == 1
    % Choose the highest degree node as the root node
    [~, highestDegree] = max(degree(T));
    pathFromRoot = shortestpathtree(T, highestDegree, 'OutputForm', 'cell');
else
    % Add a utility node as the root node and connect it to the highest
    % degree node in each componenent
    rootByComponent = zeros(numComponents, 1);
    for ii = 1:n
        comp = bins(ii);
        if rootByComponent(comp) == 0  || degree(T, ii) > degree(T, rootByComponent(comp))
            rootByComponent(comp) = ii;
        end
    end
    highestDegree = n+1;
    newT = addedge(T, highestDegree, rootByComponent);
    pathFromRoot = shortestpathtree(newT, highestDegree, 'OutputForm', 'cell');
end

if nargout > 1
    % Find the corresponding edges of pathFromRoot
    if numComponents > 1
        T = addnode(T, 1);
    end
    k = length(pathFromRoot);
    edgeFromRoot = cell(k, 1);
    for j = 1:k
        p = pathFromRoot{j};
        edgeFromRoot{j} = findedge(T, p(1:end-1), p(2:end))';
    end
end
end
