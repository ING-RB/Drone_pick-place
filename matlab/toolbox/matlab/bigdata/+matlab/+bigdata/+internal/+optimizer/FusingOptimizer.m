%FusingOptimizer Optimizer that attempts to fuse closures. Primarily
%aggregations.

% Copyright 2016-2024 The MathWorks, Inc.

classdef FusingOptimizer < matlab.bigdata.internal.Optimizer
    
    properties
        % Set MaxFuseAttempts to 1 since we currently expect all aggregation fusing to
        % occur in the first pass. (This avoids recalculating the graph)
        MaxFuseAttempts = 1;
        Debug = false;
    end
    
    properties (Constant)
        % List of operations that preserve the input tall size.
        IsSizePreservingOpType = categorical([ ...
            "AdaptorAssertionOperation", ...
            "CacheOperation", ...
            "ElementwiseOperation", ...
            "FusedSlicewiseOperation", ...
            "LogicalElementwiseOperation", ...
            "SlicewiseOperation", ...
            "SmallTallComparisonOperation", ...
            "SmallTallSliceComparisonOperation", ...
            "SubsrefTabularVarOperation"]);
        
        % List of operations that preserver reduction depth, i.e. they do
        % not require a reduction or communication between partitions.
        IsDepthPreservingOpType = categorical([ ...
            "AdaptorAssertionOperation", ...
            "CacheOperation", ...
            "ChunkResizeOperation", ...
            "ChunkwiseOperation", ...
            "ElementwiseOperation", ...
            "FilterOperation", ...
            "FixedChunkwiseOperation", ...
            "FusedSlicewiseOperation", ...
            "GeneralizedPartitionwiseOperation", ...
            "LogicalElementwiseOperation", ...
            "LogicalRowSubsrefOperation", ...
            "PartitionwiseOperation", ...
            "SlicewiseOperation", ...
            "SmallTallComparisonOperation", ...
            "SmallTallSliceComparisonOperation", ...
            "SubsrefTabularVarOperation"]);
    end
    
    methods (Access = private)
        function undoGuard = combineAggregations(~, closureGraph, dist, fusableGroupIds)
        % We need to find two or more Aggregate fusible operations where:
        %  * The reduction depths are the same
        %  * Both the input and output has the same partitioning strategy
        % This equates to two AggregateFusibleOperation objects that have
        % the same values in their respective row of fusibleGroupIds.

            undoGuard = matlab.bigdata.internal.optimizer.UndoGuard;

            isClosure = closureGraph.Nodes.IsClosure;
            isAggregation = false(size(isClosure));
            isAggregation(isClosure) = cellfun(...
                @(c) isa(c.Operation, 'matlab.bigdata.internal.lazyeval.AggregateFusibleOperation'), ...
                closureGraph.Nodes.NodeObj(isClosure));
            
            uniqueIds = unique(fusableGroupIds(isAggregation, :), 'rows');
            for ii = 1:size(uniqueIds, 1)
                rowIsThisGroup = all(fusableGroupIds == uniqueIds(ii, :), 2) & isAggregation;
                
                if sum(rowIsThisGroup) > 1
                    % Assert that there are no data dependencies. fusingDistances is a distance
                    % matrix for the nodes we're trying to fuse. It should be 0
                    % on the diagonal and Inf off the diagonal.
                    fusingDistances   = dist(rowIsThisGroup, rowIsThisGroup);
                    expectedDistances = (1 ./ eye(size(fusingDistances))) - 1;
                    assert(isequal(fusingDistances, expectedDistances), ...
                           'Attempt to fuse operations with a data dependency.');
                    
                    % Got multiple aggregations to fuse
                    aggregationsToFuseC = closureGraph.Nodes.NodeObj(rowIsThisGroup);
                    iFuseAggregations(undoGuard, [aggregationsToFuseC{:}]);
                end
            end
        end
        
        function undoGuard = combineAggregationsByKey(~, closureGraph, dist, fusableGroupIds)
        % We need to find two or more AggregateByKey operations (reducebykeyfun
        % operations end up here too) where:
        %  * The reduction depths are the same
        %  * Both the input and output has the same partitioning strategy
        % This equates to two AggregateByKey operations that have the same
        % values in their respective row of fusibleGroupIds.
            undoGuard = matlab.bigdata.internal.optimizer.UndoGuard;
            
            isAggregationByKey    = closureGraph.Nodes.OpType == 'AggregateByKeyOperation' ...
                | closureGraph.Nodes.OpType == 'FusedAggregateByKeyOperation';
            
            uniqueIds = unique(fusableGroupIds(isAggregationByKey, :), 'rows');
            for ii = 1:size(uniqueIds,1)
                rowIsThisGroup = all(fusableGroupIds == uniqueIds(ii, :), 2) & isAggregationByKey;
                numAggByKey    = sum(rowIsThisGroup);
                if numAggByKey > 1
                    % Assert that there are no data dependencies. fusingDistances is a distance
                    % matrix for the nodes we're trying to fuse. It should be 0
                    % on the diagonal and Inf off the diagonal.
                    fusingDistances   = dist(rowIsThisGroup, rowIsThisGroup);
                    expectedDistances = (1 ./ eye(size(fusingDistances))) - 1;
                    assert(isequal(fusingDistances, expectedDistances), ...
                           'Attempt to fuse operations with a data dependency.');
                    
                    % Got multiple aggregations to fuse
                    aggByKeyToFuseC = closureGraph.Nodes.NodeObj(rowIsThisGroup);
                    iFuseAggregationsByKey(undoGuard, [aggByKeyToFuseC{:}]);
                end
            end
        end
    end
    methods
        function undoGuard = optimize(obj, varargin)
            import matlab.bigdata.internal.optimizer.determinePartitioning
            
            done = false;
            undoGuard = matlab.bigdata.internal.optimizer.UndoGuard;
            count = 0;
            closureGraph = matlab.bigdata.internal.optimizer.ClosureGraph(varargin{:});
            while ~done
                graphObj = closureGraph.Graph;
                
                % We need to generate a topological sort of the graph so that we can calculate
                % the tall sizes from the graph connectivity
                order = toposort(graphObj);
                
                % tallSize is +ve for real known sizes, -ve for 'symbolic' sizes. Symbolic sizes
                % are sizes that we know are identical to one another, but we
                % don't (yet) know the actual size.
                tallSize = nan(numel(order), 1);

                % reductionDepth is zero for nodes with no predecessors, and increases as
                % reductions are encountered. Reduction depth -1 indicates a
                % constant value.
                reductionDepth = zeros(numel(order), 1);
                
                % inPartitioningId/outPartitioningId is an integer that represents the
                % partitioning of the input and output of a closure. This can be:
                %  * 0 for non-partitioned
                %  * negative for partition by datastore, where each id
                %    corresponds to one unique datastore)
                %  * positive for partition by N partitions.
                %  * Inf for partition as per back-end choice.
                [inPartitioningId, outPartitioningId] = determinePartitioning(graphObj, order);
                
                % reductionCombinations is a map from a list of input depths to a resulting
                % output depth. It's used to ensure that we don't create a new
                % reduction depth for each time we encounter a given combination
                % of input reduction depths.
                reductionCombinations = containers.Map();

                % inSize is the input size Id for a given node, or NaN if multiple sizes are
                % input to a single node. We use this to be conservative about
                % fusing aggregations - we'll only fuse those aggregations where
                % we can prove they have well-known and unique input sizes.
                inSize   = nan(numel(order), 1);

                % Extract the node list up front so that we minimise the number of times we use
                % the digraph/subsref implementation.
                nodeList = graphObj.Nodes.NodeObj;
                opTypes  = graphObj.Nodes.OpType;

                % Topological sort guarantees that each node we iterate over has all predecessor
                % information available
                for idx = 1:numel(order)
                    nodeIdx = order(idx);
                    nodeObj = nodeList{nodeIdx};
                    opType  = opTypes(nodeIdx);
                    [tallSize, reductionDepth, inSize(nodeIdx)] = ...
                        iCalcTallSizeReductionDepth(graphObj, nodeObj, nodeIdx, opType, tallSize, ...
                                                    reductionDepth, reductionCombinations);
                end

                % Calculate all (directed) distances between nodes so that we can check that we
                % don't accidentally try to fuse aggregations which have data
                % dependencies between them.
                dist            = distances(graphObj);
                fusibleGroupIds = [reductionDepth, inPartitioningId, outPartitioningId];
                newGuardNonKeyed = combineAggregations(obj, graphObj, dist, fusibleGroupIds);
                newGuardKeyed = combineAggregationsByKey(obj, graphObj, dist, fusibleGroupIds);
                newGuard = combine(newGuardNonKeyed, newGuardKeyed);
                count = 1 + count;
                done = ~newGuard.HasActions || count >= obj.MaxFuseAttempts;
                undoGuard = combine(undoGuard, newGuard);
                if ~done && combined
                    % We made changes, recompute the closure graph.
                    recalculate(closureGraph);
                end
            end
            
            if ~nargout
                disarm(undoGuard);
            end
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Derive a real or symbolic tall output size for a given closure. Here we rely
% on the fact that all outputs for any type of closure must have the same tall
% size.
%
% Since the computation is very closely related, we also compute the updated
% "reduction depth" while we're here.
%
% For elementwise and slicewise operation types, if all the input sizes are
% identical (or known to be 1), then the output size is the same as all input
% sizes. In all other cases, a new symbolic output size is allocated.
function [tsz, redDepth] = iDeriveTallSizeReductionDepthForClosure(opType, ...
                                   predecessorIdxs, tszs, redDepths, redCombin)
    import matlab.bigdata.internal.optimizer.FusingOptimizer;
    
    % Default: allocate a new symbolic tall size
    tsz = min(tszs - 1);

    % Default: allocate a new positive reduction depth
    redDepth = max(max(redDepths), 0) + 1;

    % For elementwise and slicewise, we know that we *might* be able to propagate
    % the size
    isSizePreserving = ismember(opType, FusingOptimizer.IsSizePreservingOpType);
    if isSizePreserving
        inputSizes = tszs(predecessorIdxs);
        % Ignore inputs which are size 1 in the tall dimension
        inputSizes(inputSizes == 1) = [];
        
        if isempty(inputSizes) && ~isempty(predecessorIdxs)
            % There were some predecessors, but they were all size 1 in the tall dimension.
            tsz = 1;
        elseif isscalar(unique(inputSizes))
            % All sizes the same, propagate. These sizes might be real +ve sizes, or
            % symbolic -ve sizes.
            tsz = inputSizes(1);
        end
    end

    isDepthPreserving = ismember(opType, FusingOptimizer.IsDepthPreservingOpType);
    uniqueInputDepths = unique(redDepths(predecessorIdxs));

    % Here we are concerned with unique reduction depths of inputs, but we can
    % safely ignore constants as they can always be combined.
    uniqueRedDepthsIgnoringConstant = uniqueInputDepths(uniqueInputDepths ~= -1);
    
    if isDepthPreserving && isscalar(uniqueRedDepthsIgnoringConstant)
        % All inputs are the same depth - so preserve. Avoid problems like g1463265 by
        % assuming that combinations of reduction depths produce a new reduction depth.
        redDepth = uniqueRedDepthsIgnoringConstant;
    else
        depthKey = char(join(string(uniqueRedDepthsIgnoringConstant), ','));
        if redCombin.isKey(depthKey)
            redDepth = redCombin(depthKey);
        else
            % Use the new value
            redCombin(depthKey) = redDepth; %#ok<NASGU> handle
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function is called in a loop on a topologically sorted list of nodes. It
% updates elements of 'tszs' - the tall output size array, and also calculates
% 'insz', the tall size of the inputs to the closure
function [tszs, redDepths, insz] = iCalcTallSizeReductionDepth(graphObj, node, nodeIdx, opType, ...
                                                      tszs, redDepths, redCombin)
    pred = predecessors(graphObj, nodeIdx);
    if isClosure(node)
        if isempty(pred)
            % No predecessors - allocate a new symbolic size for the output of this closure.
            tszs(nodeIdx) = min(-1, min(tszs) - 1);
            
            % reductionDepth for read operations is set to a unique negative
            % value.
            if opType == "ReadOperation"
                redDepths(nodeIdx) = 0;
            end
        else
            % Need to derive from inputs
            [tszs(nodeIdx), redDepths(nodeIdx)] = ...
                iDeriveTallSizeReductionDepthForClosure(opType, pred, tszs, ...
                                                        redDepths, redCombin);
        end
    elseif isFuture(node) && node.IsDone
        % Completed future - we have the actual data, so use that to get a real size.
        tszs(nodeIdx) = size(node.Value, 1);
        
        % reductionDepth for constant values is -1.
        redDepths(nodeIdx) = -1;
        
    elseif isFuture(node)
        % Uncompleted future - output size is simply input size.
        assert(isscalar(pred));
        assert(~isnan(tszs(pred)));
        tszs(nodeIdx) = tszs(pred);
        % Likewise, reduction depth unchanged
        redDepths(nodeIdx) = redDepths(pred);
    else
        assert(false);
    end
    
    % Compute the input size for this node. If all predecessor output sizes are
    % identical, that's our 'input size'. If they aren't, then we don't know
    % what the input size is, so return NaN.
    inszs = tszs(pred);
    if ~isempty(inszs) && isscalar(unique(inszs))
        insz = inszs(1);
    else
        insz = NaN;
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Fusing aggregation starts as follows: we need to en-cellify all inputs, then
% build a fused aggregation closure, then de-cellify all outputs.
function iFuseAggregations(undoGuard, closuresToFuse)
    
    import matlab.bigdata.internal.lazyeval.FusedAggregateOperation;
    import matlab.bigdata.internal.lazyeval.Closure;
    
    inFutures = vertcat(closuresToFuse.InputFutures);
    originalFutures = vertcat(closuresToFuse.OutputFutures);

    newFusedOperation = FusedAggregateOperation.fuse(closuresToFuse.Operation);
    newFusedClosure = Closure(inFutures, newFusedOperation, [originalFutures.IsPartitionIndependent]);
    
    optimizedFutures = newFusedClosure.OutputFutures;
    
    % Finally, swap over the new futures
    undoGuard.swapAndAppend(originalFutures, optimizedFutures);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Fuse aggregations by key
function iFuseAggregationsByKey(undoGuard, closuresToFuse)
    import matlab.bigdata.internal.lazyeval.AggregateByKeyOperation;
    import matlab.bigdata.internal.lazyeval.FusedAggregateByKeyOperation;
    import matlab.bigdata.internal.FunctionHandle;
    import matlab.bigdata.internal.lazyeval.Closure;
    import matlab.bigdata.internal.lazyeval.SlicewiseOperation;
    
    % Calculate the number of inputs and outputs per *closure* (remembering that 'by
    % key' operations have the 'key' input/output which is not passed to the
    % aggregation/reduction functions).
    originalOperations = arrayfun(@(c) c.Operation, closuresToFuse, 'UniformOutput', false);

    % Get the input list for the fused AggregateByKeyOperation
    fusedAggByKeyInputFutures = vertcat(closuresToFuse.InputFutures);
    originalFutures = vertcat(closuresToFuse.OutputFutures);
    
    % Put the two new functions together into a single AggregateByKeyOperation and
    % Closure.
    newOperation         = FusedAggregateByKeyOperation.fuse(originalOperations{:});
    newFusedClosure      = Closure(fusedAggByKeyInputFutures, newOperation, [originalFutures.IsPartitionIndependent]);
    
    optimizedFutures = newFusedClosure.OutputFutures;
    
    % Finally, swap over the new futures
    undoGuard.swapAndAppend(originalFutures, optimizedFutures);
end
