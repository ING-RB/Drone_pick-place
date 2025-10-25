function subds = subset(ds, indices)
%SUBSET   returns a new SequentialDatastore containing the
%   specified observation indices
%
%   SUBDS = SUBSET(DS, INDICES) creates a deep copy of the input
%   datastore DS containing observations corresponding to INDICES.
%
%   It is only valid to call the SUBSET method on a
%   SequentialDatastore if it returns isSubsettable true.
%
%   INDICES must be a vector of positive and unique integer numeric
%   values. INDICES can be a 0-by-1 empty array and does not need
%   to be provided in any sorted order when nonempty.
%
%   The output datastore SUBDS, contains the observations
%   corresponding to INDICES and in the same order as INDICES.
%
%   INDICES can also be specified as a N-by-1 vector of logical
%   values, where N is the number of observations in the datastore.
%
%   See also matlab.io.Datastore.isSubsettable,
%   matlab.io.datastore.ImageDatastore.subset

%   Copyright 2022 The MathWorks, Inc.

arguments
    ds
    indices (1,:) {mustBeNumericOrLogical}
end

ds.verifySubsettable("subset");

%% Validate Subset Indices
import matlab.io.datastore.internal.validators.validateSubsetIndices;

numPartitionsPerDatastore = cellfun(@numpartitions, ds.UnderlyingDatastores);
totalNumPartitions = ds.numpartitions();

try
    indices = validateSubsetIndices(indices, totalNumPartitions, ...
        'SequentialDatastore');
catch ME
    % Provide a more accurate error message in the empty subset case.
    if ME.identifier == "MATLAB:datastoreio:splittabledatastore:zeroSubset"
        msgid = "MATLAB:io:datastore:common:sequentialdatastore:zeroSubset";
        error(message(msgid));
    end
    throw(ME)
end

%% Generate the partition strategy table listing indices to be used with subset() on each underlying datastore.
import matlab.io.datastore.internal.util.pigeonHoleDatastoreList;
partitionStrategyTable = pigeonHoleDatastoreList(totalNumPartitions, numPartitionsPerDatastore);
% We are only interested in the 'indices' asked for in the subset input.
partitionStrategyTable = partitionStrategyTable(indices, :);
% Clean up unwanted variables in the partitionStrategyTable.
partitionStrategyTable.PartitionIndex = [];
partitionStrategyTable.N = [];

%% Build the required subsets from the underlying datastores.
sourceDatastoreIndices = partitionStrategyTable.SourceDatastoreIndex';
subDsList = cell.empty(height(findgroups(partitionStrategyTable)), 0);
sourceDatastoreIndex = 0;
subDsListIndex = 1;
while(sourceDatastoreIndex < length(sourceDatastoreIndices))
    sourceDatastoreIndex = sourceDatastoreIndex + 1;
    tableIndices = sourceDatastoreIndex;
    while sourceDatastoreIndex < length(sourceDatastoreIndices) && sourceDatastoreIndices(sourceDatastoreIndex) == sourceDatastoreIndices(sourceDatastoreIndex+1)
        sourceDatastoreIndex = sourceDatastoreIndex + 1;
        tableIndices = [tableIndices, sourceDatastoreIndex]; %#ok<AGROW>
    end
    subDsList{subDsListIndex} = subset(ds.UnderlyingDatastores{sourceDatastoreIndices(sourceDatastoreIndex)}, partitionStrategyTable.ii(tableIndices));
    subDsListIndex = subDsListIndex+1;
end
subds = matlab.io.datastore.SequentialDatastore(subDsList{:});
end