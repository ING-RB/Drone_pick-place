function out = vertcatpartitions(varargin)
% Vertically concatenate the partitions of the input LazyPartitionedArray.

%   Copyright 2022 The MathWorks, Inc.

import matlab.bigdata.internal.lazyeval.PadWithEmptyPartitionsOperation;
import matlab.bigdata.internal.lazyeval.SelectNonEmptyPartitionOperation;
import matlab.bigdata.internal.lazyeval.LazyPartitionedArray;
import matlab.bigdata.internal.PartitionMetadata;

% This switch exists as the only way to disable the vertcat
% optimization is to revert back to the old implementation.
if matlab.bigdata.internal.optimizer.VertcatBackendOptimizer.enable()
    inputMetadata = cellfun(@getPartitionMetadata, varargin, 'UniformOutput', false);
    outputMetadata = PartitionMetadata.vertcatPartitionMetadata(inputMetadata{:});
    for subIndex = 1:numel(varargin)
        op = PadWithEmptyPartitionsOperation(outputMetadata.Strategy, subIndex);
        varargin{subIndex} = LazyPartitionedArray.applyOperation(op, outputMetadata, varargin{subIndex});
    end
else
    % Fall back to old version
    [varargin{:}] = matlab.bigdata.internal.lazyeval.vertcatrepartition(varargin{:});
end

functionHandle = matlab.bigdata.internal.FunctionHandle(@deal); % To make this the first frame in error stacks
out = LazyPartitionedArray.applyOperation(SelectNonEmptyPartitionOperation(functionHandle, numel(varargin), nargout), varargin{:});
end
