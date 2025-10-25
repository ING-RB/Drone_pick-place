function varargout = gather(varargin)
% Gather the data underlying the provided LazyPartitionedArray inputs.
%

%   Copyright 2022-2024 The MathWorks, Inc.

import matlab.bigdata.internal.lazyeval.GatherOperation;
import matlab.bigdata.internal.lazyeval.LazyPartitionedArray;

[metadatas, metadataFillingPartitionedArrays] = ...
    iGenerateMetadataFillingPartitionedArrays(varargin);

allPartitionedArrays = [varargin, ...
   metadataFillingPartitionedArrays];

% If there is more than one array to be gathered, we insert
% GatherOperation closures so that the fusing optimizer can
% fuse these into any existing aggregate operations. This is
% not needed for broadcast arrays as those are already in a
% gathered state.
if nargin > 1
    gatherOperation = GatherOperation(1);
    for ii = 1:numel(varargin)
        if ~allPartitionedArrays{ii}.PartitionMetadata.Strategy.IsBroadcast
            allPartitionedArrays{ii} = ...
                LazyPartitionedArray.applyOperation(gatherOperation, allPartitionedArrays{ii});
        end
    end
end

[taskGraph, taskToClosureMap, ~, executor, optimUndoGuard] = getEvaluationObjects(allPartitionedArrays{:}); %#ok<ASGLU>
if isempty(taskGraph)
    readFailureSummary = matlab.bigdata.internal.executor.ReadFailureSummary();
else
    % Default for all outputs is to gather.
    outputHandler = LazyPartitionedArray.createGatherOutputHandler(taskToClosureMap);
    readFailureSummary = executor.executeWithHandler(taskGraph, outputHandler);
    LazyPartitionedArray.cleanupOldCacheEntries(taskGraph.CacheEntryKeys);
end

if readFailureSummary.NumFailures == 0
    iApplyMetadataResults(metadatas, allPartitionedArrays((1+nargin):end));
end

varargout = cell(1, nargin + 1);
for ii = 1:nargin
    assert (allPartitionedArrays{ii}.ValueFuture.IsDone, ...
        'Assertion failed: Output %i of gather was not complete by end of evaluation', ii);
    varargout{ii} = allPartitionedArrays{ii}.ValueFuture.Value;
end
varargout{end} = readFailureSummary;
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Given a list of partitioned arrays, get the metadata objects that can be
% filled out, and the corresponding list of partitioned arrays that will compute
% the metadata.
function [metadatas, partitionedArrays] = ...
    iGenerateMetadataFillingPartitionedArrays(inputArrays)

executorToConsider = [];

keepArray = false(1, numel(inputArrays));

for idx = 1:numel(inputArrays)
    inputArray = inputArrays{idx};
    if isempty(executorToConsider) && ~isempty(inputArray.Executor)
        executorToConsider = inputArray.Executor;
    end

    if ~isempty(executorToConsider)
        keepArray(idx) = isequal(inputArray.Executor, executorToConsider);
    end
end

inputArrays(~keepArray) = [];

[metadatas, partitionedArrays] = iGenerateMetadata(inputArrays, executorToConsider);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Generate partitioned arrays to compute metadata. We do this for arrays that are:
% - upstream of all aggregations
% - downstream of any read
% - not adaptor-assertion operations
% - not downstream of any "depends only on head" operations
function [metadatas, metadataPartitionedArrays] = iGenerateMetadata(partitionedArrays, exec)
import matlab.bigdata.internal.lazyeval.LazyPartitionedArray

% Get the closure graph for this partitioned array.
cg           = matlab.bigdata.internal.optimizer.ClosureGraph(partitionedArrays{:});
allNodeObjs  = cg.Graph.Nodes.NodeObj;
allOpTypes   = cg.Graph.Nodes.OpType;
isClosure    = cg.Graph.Nodes.IsClosure;
allDistances = distances(cg.Graph);

% compute which closures are 'head only' closures, and nodes which are
% downstream thereof
isHeadOnlyClosure      = iFindHeadOnlyClosures(allNodeObjs, isClosure);
isDownstreamOfHeadOnly = iFindDownstreamOfAny(allDistances, isHeadOnlyClosure);

% compute which closures are 'assertion' closures.
isAssertionClosure = iFindAssertionClosures(allOpTypes, isClosure);

% compute which closures are downstream of any read operation
isClosureDownstreamOfRead = iFindDownstreamOfAnyRead(allDistances, allOpTypes, isClosure);

% compute which closures are read operation that can be optimized to read
% less if not everything is required.
isClosureOptimizableRead = iFindOptimizableRead(allNodeObjs, allOpTypes, isClosure);

% compute which closures are upstream of any cache operation
isClosureUpstreamOfCache = iFindUpstreamOfCache(allDistances, allOpTypes, isClosure);

% compute which closures are upstream of all aggregations
isClosureUpstreamOfAggregate = iFindUpstreamOfAllAggregates(allDistances, ...
    allOpTypes, isClosure, isDownstreamOfHeadOnly);

% Combine all the above to select the nodes for which we'll even consider
% collecting metadata.
nodesToKeep = isClosure & ...
    ~isDownstreamOfHeadOnly & ...
    ~isAssertionClosure & ...
    isClosureDownstreamOfRead & ...
    ~isClosureOptimizableRead & ...
    isClosureUpstreamOfAggregate & ...
    ~isClosureUpstreamOfCache;

% Next, we need to find the futures that are immediately downstream of all
% those closures. Use the distance matrix again, and find the places where the
% distance is exactly 1.
distFromClosure = allDistances(nodesToKeep, :);
isFutureMatrix = distFromClosure == 1;
futureIdxs     = find(sum(isFutureMatrix, 1));

% Finally, get the promises, and build the metadata-gathering partitioned
% arrays.
metadatas                 = cell(1, numel(futureIdxs));
metadataPartitionedArrays = cell(1, numel(futureIdxs));
for idx = 1:numel(futureIdxs)
    thisFuture = allNodeObjs{futureIdxs(idx)};
    metadatas{idx} = hGetMetadata(thisFuture);
    if ~isempty(metadatas{idx}) && ~hasGotResults(metadatas{idx})
        % Build with empty datastore - presume checks upstream will sort
        % things out.
        tmpPartitionedArray = LazyPartitionedArray.createFromFuture(thisFuture, [], exec);
        [aggFcn, redFcn] = getAggregateAndReduceFcns(metadatas{idx});
        metadataPartitionedArrays{idx} = aggregatefun(...
            aggFcn, redFcn, tmpPartitionedArray);
    end
end

% Discard those elements that turned out not to have any metadata to compute.
discard = cellfun(@isempty, metadataPartitionedArrays);
metadatas(discard) = [];
metadataPartitionedArrays(discard) = [];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Find all nodes upstream of all aggregate operations - providing there are some
% aggregates. If there are no aggregates, this will return an all-false vector.
function isUpstream = iFindUpstreamOfAllAggregates(allDistances, allOpTypes, ...
    isClosure, isDownstreamOfHeadOnly)
isAggregate = false(size(isClosure));
isAggregate(isClosure) = allOpTypes(isClosure) == 'AggregateOperation';
% Disregard aggregates that are downstream of 'head only' operations as
% these do not represent a full pass through the data
isAggregate(isDownstreamOfHeadOnly) = false;
distUpToAggregate = allDistances(:, isAggregate);
isUpstreamMatrix = distUpToAggregate > 0 & ~isinf(distUpToAggregate);
isUpstream = all(isUpstreamMatrix, 2) & any(isAggregate);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Find all nodes downstream of some list of nodes
function isDownstream = iFindDownstreamOfAny(allDistances, sourceNodes)
distToSource = allDistances(sourceNodes, :).';
isDownstreamMatrix = distToSource >= 0 & ~isinf(distToSource);
isDownstream = any(isDownstreamMatrix, 2);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Get a vector defining whether a closure node is downstream of any read operation
function isDownstream = iFindDownstreamOfAnyRead(allDistances, allOpTypes, isClosure)
isReadClosure = false(size(isClosure));
isReadClosure(isClosure) = allOpTypes(isClosure) == 'ReadOperation';
isDownstream = iFindDownstreamOfAny(allDistances, isReadClosure);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Find all nodes that are optimizable read closures. These are precisely
% those that can be optimized to read less if not all variables or all rows
% required.
function isOptimizableRead = iFindOptimizableRead(allNodeObjs, allOpTypes, isClosure)
import matlab.bigdata.internal.optimizer.ReadTabularVarAndRowOptimizer
import matlab.bigdata.internal.optimizer.ReadTabularVarSubsrefOptimizer
datastoresToIgnore = union(ReadTabularVarSubsrefOptimizer.DatastoreForOptimization, ReadTabularVarAndRowOptimizer.DatastoreForOptimization);
isOptimizableRead = false(size(isClosure));
isOptimizableRead(isClosure) = allOpTypes(isClosure) == 'ReadOperation';
isOptimizableRead(isOptimizableRead) = cellfun(@(nodeObj) isClosureDatastoreAnyOf(nodeObj, datastoresToIgnore), allNodeObjs(isOptimizableRead));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Return true if and only if the closure's datastore is any of the given
% class names.
function tf = isClosureDatastoreAnyOf(closure, names)
clz = class(closure.Operation.Datastore);
if isequal(clz, 'matlab.io.datastore.internal.FrameworkDatastore')
    clz = class(closure.Operation.Datastore.Datastore);
end
tf = ismember(clz, names);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Get a vector defining whether a closure node is upstream of any cache operation
function isUpstream = iFindUpstreamOfCache(allDistances, allOpTypes, isClosure)
isCacheClosure = false(size(isClosure));
isCacheClosure(isClosure) = allOpTypes(isClosure) == 'CacheOperation';
distCacheUpToX = allDistances(:, isCacheClosure);
% Keep rows of distCacheUpToX where any column is finite and >= 0
isUpstream = any(distCacheUpToX >= 0 & ~isinf(distCacheUpToX), 2);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Get a vector defining whether a node is an 'assertion' closure
function isAssertionClosure = iFindAssertionClosures(allOpTypes, isClosure)
isAssertionClosure = false(size(isClosure));
isAssertionClosure(isClosure) = allOpTypes(isClosure) == 'AdaptorCheckOperation';
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Get a vector defining whether a node is a 'head only' closure
function isHeadOnlyClosure = iFindHeadOnlyClosures(allNodeObjs, isClosure)
isHeadOnlyClosure = false(size(isClosure));
isHeadOnlyClosure(isClosure) = cellfun(@(c) c.Operation.DependsOnOnlyHead, ...
    allNodeObjs(isClosure));
end

% Apply the results of computing metadata to the metadata objects
function iApplyMetadataResults(metadatas, metadataFillingPartitionedArrays)
cellfun(@(m, mfpa) applyResult(m, mfpa.ValueFuture.Value), ...
    metadatas, metadataFillingPartitionedArrays);
end
