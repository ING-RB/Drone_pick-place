function tf = hasCommunicatingOperations(partitionedArray)
%hasCommunicatingOperations Does the partitioned array contain
%communicating operations?

% Copyright 2023 The MathWorks, Inc.

closureGraph = matlab.bigdata.internal.optimizer.ClosureGraph(partitionedArray);
opTypes = closureGraph.Graph.Nodes.OpType;
opTypes = string(unique(rmmissing(opTypes)));
isDepthPreserving = ismember(opTypes, string(matlab.bigdata.internal.optimizer.FusingOptimizer.IsDepthPreservingOpType));
isSource = ismember(opTypes, ["ReadOperation", "ConstantOperation", "DistributedGetOperation"]);
tf = any(~(isDepthPreserving | isSource));

end
