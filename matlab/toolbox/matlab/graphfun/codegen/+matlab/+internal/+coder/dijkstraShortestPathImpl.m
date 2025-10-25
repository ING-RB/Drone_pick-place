function [dist, pred, edgepred] = dijkstraShortestPathImpl(G, weight, start, subsetAllNodes, inTargetSubset, maxNrNodes, nearestRadius)

%#codegen
%   Copyright 2022 The MathWorks, Inc.

ONE = coder.internal.indexInt(1);

returnNodes = nargout >= 2; % compPath >= NODES in the in-memory source
returnEdges = nargout == 3; % compPath == NODESANDEDGES in the in-memory source

n = G.numnodes;
if returnNodes
    pred = NaN(n,1);
end
if returnEdges
    edgepred = NaN(n,1);
end

dist = inf(n,1);

if returnNodes
    pred(start) = 0;
end
if returnEdges
    edgepred(start) = 0;
end
dist(start) = 0;

if maxNrNodes == 0
    return
end

% Initialize queue
queue = matlab.internal.coder.minPriorityQueue(n);

WHITE = char(0);
GRAY = char(1);
BLACK = char(2);
colors = char(zeros(n,1)); % WHITE

colors(start) = GRAY;
queue = push(queue, start, dist);

while(~isempty(queue))
    [queue, u] = queue.pop(dist);
    colors(u) = BLACK;
    if subsetAllNodes || inTargetSubset(u)
        maxNrNodes = maxNrNodes - 1;
        if maxNrNodes == 0 || ~(dist(u) <= nearestRadius)
            % Stop the algorithm, requested node has been found

            % Put NaNs in dist, pred, and edgepred to indicate where the
            % algorithm stopped
            for ii = ONE:numel(queue)
                it = queue.getValue(ii);
                if returnNodes
                    pred(it) = NaN;
                end
                if returnEdges
                    edgepred(it) = NaN;
                end
                dist(it) = Inf;
            end
            if ~(dist(u) <= nearestRadius)
                % This should only be true when called from the NEAREST
                % method, so returnNodes == true and returnEdges == false
                pred(u) = NaN;
                dist(u) = Inf;
            end
            return
        end
    end
    
    [outEdges,outNodes] = outedges(G, u);

    for ii = ONE:numel(outNodes)
        v = outNodes(ii);
        edge = outEdges(ii);
        if colors(v) == WHITE
            colors(v) = GRAY;
            dist(v) = dist(u) + weight(edge);
            if returnNodes
                pred(v) = u;
            end
            if returnEdges
                edgepred(v) = edge;
            end
            queue = push(queue, v, dist);
        elseif colors(v) == GRAY
            newCost = dist(u) + weight(edge);
            if returnNodes
                if newCost < dist(v) || (newCost == dist(v) ...
                        && u + 1 < pred(v))
                    dist(v) = newCost;
                    pred(v) = u;
                    if returnEdges
                        edgepred(v) = edge;
                    end
                    queue = update(queue, v, dist);
                end
            else
                if newCost < dist(v)
                    dist(v) = newCost;
                    queue = update(queue, v, dist);
                end
            end
        end
    end
end