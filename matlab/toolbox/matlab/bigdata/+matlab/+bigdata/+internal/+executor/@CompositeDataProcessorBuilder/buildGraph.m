function buildGraph(obj)
% Build a digraph object that represents the graph of
% underlying builders. This digraph will be in topological
% order, with all nodes that represent global inputs at the
% beginning of the node table.

%   Copyright 2023-2024 The MathWorks, Inc.

[builders, dependencies, orderIndices] = obj.findAllDependencies();
% The cached digraph has references back to this object, we break the
% cyclic dependency by making those references weak. We don't have to worry
% about lifetime as this object keeps everything necessary alive.
builderWeakRefs = arrayfun(@matlab.lang.WeakReference, builders);
nodeTable = table([builders.Id]', builderWeakRefs, vertcat(builders.IsGlobalInput),...
    'VariableNames', {'Name', 'Builder', 'IsGlobalInput'});
edgeTable = table(dependencies, orderIndices, ...
    'VariableNames', {'EndNodes', 'OrderIndex'});

g = digraph(edgeTable, nodeTable);

topoSortIdx = toposort(g);
isGlobalInput = g.Nodes.IsGlobalInput(topoSortIdx);
numGlobalInputs = sum(isGlobalInput);
if numGlobalInputs > 0
    % The inputs are moved to the beginning as this is required
    % by CompositeDataProcessor.
    topoSortIdx = [topoSortIdx(isGlobalInput), topoSortIdx(~isGlobalInput)];
    % SparkExecutor expects inputs to be in order of InputId.
    inputBuilders = builders(topoSortIdx(1:numGlobalInputs));
    if isnumeric(inputBuilders(1).InputId)
        inputIds = [inputBuilders.InputId];
    else
        inputIds = string({inputBuilders.InputId});
    end
    [~, inputSortIdx] = sort(inputIds);
    topoSortIdx(1:numGlobalInputs) = topoSortIdx(inputSortIdx);
end

g = reordernodes(g, topoSortIdx);

obj.Graph = g;
end
