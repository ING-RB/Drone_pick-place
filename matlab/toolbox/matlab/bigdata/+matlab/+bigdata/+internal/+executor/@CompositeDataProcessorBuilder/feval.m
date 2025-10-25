function processor = feval(obj, partition, varargin)
% Build the graph of DataProcessors and wrap them in an enclosing
% CompositeDataProcessor.

%   Copyright 2023 The MathWorks, Inc.

import matlab.bigdata.internal.executor.CompositeDataProcessor;
g = obj.getAsGraph();

numNodes = numnodes(g);
numInputNodes = sum([g.Nodes.IsGlobalInput]);

[s, t] = findedge(g);
adjacencyWithOrder = sparse(s, t, g.Edges.OrderIndex, numNodes, numNodes);

builders = g.Nodes.Builder;
nodeProcessors = cell(numNodes, 1);
for nodeIdx = numInputNodes + 1 : numel(builders) - 1
    nodeProcessors{nodeIdx} = buildUnderlyingProcessor(builders(nodeIdx), partition);
end
nodeProcessors{end} = buildUnderlyingProcessor(builders(end), partition, varargin{:});

processor = CompositeDataProcessor(nodeProcessors, adjacencyWithOrder, numInputNodes);
end
