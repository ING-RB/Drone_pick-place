function [B, I] = sortFixtureRequirements(A)
% This function is undocumented and subject to change in a future release

% Copyright 2017-2018 The MathWorks, Inc.

[G, GA, GC] = unique(A,'rows','stable');

% block into disjoint sets of fixture requirements
colmap = 1:size(G,2);
rowmap = (1:size(G,1)).';
for k=1:size(G,1)
    mask = G(k,:);
    colmap(mask) = min(colmap(mask));
end
[~,ucol,colmap] = unique(colmap);
for k=1:length(ucol)
    mask = any(G(:,k==colmap),2);
    rowmap(mask) = k;
end
[~,HA,HC] = unique(rowmap,'stable');

bincounts = accumarray(HC, 1);
setsToRefine = find(bincounts>1);
for k=setsToRefine(:).'
    mask = HC == HA(k);
    blk = G(mask,:);
    [GA,GC] = attemptToReduceAndRerun(blk, GA, GC, mask);
end

% transform back to get the permutation array for the original suite
T = unwind(HC, GA, GC);

[~,I] = sort(T);
B = A(I,:);
end

function P = unwind(T,A,C)
[~,T] = sort(T);
[~,T] = sort(T);
P = A(T(C));
end

function [GA,GC] = attemptToReduceAndRerun(blk, GA, GC, mask)
import matlab.unittest.internal.sortFixtureRequirements;

% look for columns of all-trues and rows that have only those columns as
% true
colmask = all(blk,1);
rowmask = all(blk==colmask,2);
if ~any(rowmask)
    % can't decouple/reduce further, use an optimization algorithm on the
    % subset
    gi = kruskal(blk);
    ga = GA(mask);
    GA(mask) = ga(gi);
    return;
end

% Reduce and re-analyze on the smaller matrix
subblk = blk(~rowmask,~colmask);
[~,I] = sortFixtureRequirements(subblk);

% Process resulting index vector
rownum = find(rowmask, 1); % guaranteed to be only one
shift = I >= rownum;
I(shift) = I(shift)+1;
[~,P] = sort([rownum; I]);

% Return a modified GC to account for any swaps
map = GA;
y = GA(mask);
map(mask) = y(P);
[~,~,map] = unique(map);
GC = map(GC);
end

function I = kruskal(G)
% Kruskal's Algorithm for Minimum-Spanning-Trees applied to a directed
% acyclic sequence of vertices

% Calculate the cost (edge weights) of each vertex to each vertex - this is
% a complete graph
N = size(G,1);
C = zeros(N);
for k=1:N
    cost = sum(G(k,:) ~= G,2);
    C(k,:) = cost.';
end

% weight the vertices' edges on themselves to be an infinite weight
C(C==0) = Inf;

% sort the edge weights
[~, edgeIdx] = sort(C(:));
% Map back to subscripts to identify what vertices an edge connects.
% Transpose to get row-major costs to favor "stable" permutations
[col,row] = ind2sub([N N], edgeIdx);

% Make a map such that vertex i has a directed edge pointing to vertex j
% iff map(i,j). This map will hold one truthy element per row and per
% column, similar to the N-queens problem.
map = false(N);
% Keep a record of these key masks to avoid many extra "any" checks on the
% map matrix
rowmask = false(1,N);
colmask = false(1,N);

for k=1:N^2-N
    r = row(k);
    c = col(k);
    
    if rowmask(r) || colmask(c)
        % Already accounted for - can't add a second edge on a vertex in
        % the same direction
        continue;
    end
    
    mark(r,c,true);
    
    if all(rowmask & colmask)
        % The only allowable cycle-exception where the map is at
        % capacity and we're done
        break
    end
    
    % test if this new edge made a cycle
    first = map(r,:);
    next = first;
    for j=1:nnz(map)
        next = map(next,:);
        if ~any(next)
            % not a cycle
            break;
        end
        if all(first == next)
            % this made a sub-cycle and we have to revert it
            mark(r,c,false);
            break;
        end
    end
    
end

% The map is currently cyclic - we need to identify a "starting" vertex.
% We'll do this by finding the cheapest start.
[~,I] = min(sum(G,2));

% Walk through map to connect vertices in the generated order
f = 1:N; % avoid a repetive "find" operation to map masks to indices
for k=2:N
    I(k) = f(map(I(k-1),:));
end

    function mark(r,c,bool)
        map(r,c) = bool;
        rowmask(r) = bool;
        colmask(c) = bool;
    end

end