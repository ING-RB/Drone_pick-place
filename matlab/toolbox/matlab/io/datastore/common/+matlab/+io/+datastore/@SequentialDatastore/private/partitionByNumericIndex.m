function partds = partitionByNumericIndex(ds, n, index)

%   Copyright 2022 The MathWorks, Inc.

import matlab.io.datastore.internal.util.pigeonHoleDatastoreList;

validateattributes(n, {'numeric'}, ...
    {'scalar', 'integer', 'positive'}, ...
    "partition", "NumPartitions");

validateattributes(index, {'numeric'}, ...
    {'nonempty', 'scalar', 'integer', 'positive', '<=', n}, ...
    "partition", "PartitionIndex");

numPartitionsPerDatastore = cellfun(@numpartitions, ds.UnderlyingDatastores);

% Generate the partition strategy table listing N and ii to be used with
% partition() on each underlying datastore in the required partition.
partitionStrategyTable = pigeonHoleDatastoreList(n, numPartitionsPerDatastore);
% We are only interested in the 'index' slice asked for in the partition
% input.
partitionStrategyTable = partitionStrategyTable(partitionStrategyTable.PartitionIndex == index, :);
% Clean up unwanted variables in the partitionStrategyTable.
partitionStrategyTable.PartitionIndex = [];

% Build the required partitions from the underlying datastores.
partDsList = cell.empty(height(partitionStrategyTable), 0);
for idx = 1: height(partitionStrategyTable)
    partDsList{idx} = partition(ds.UnderlyingDatastores{...
        partitionStrategyTable.SourceDatastoreIndex(idx)}, ...
        partitionStrategyTable.N(idx), ...
        partitionStrategyTable.ii(idx));
end

partds = matlab.io.datastore.SequentialDatastore(partDsList{:});
end