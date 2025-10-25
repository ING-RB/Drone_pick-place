function T = pigeonHoleDatastoreList(N, numPartitionsPerDatastore)
%PIGEONHOLEDATASTORELIST   pigeonHole improvement to be used when
%   partitioning or subsetting a list of vertically merged datastores as in
%   SequentialDatastore.
%
%   This helper function maps the observations to the partitions or subsets
%   on individual underlying datastores and returns a table listing the N
%   and ii to be used with partitioning or subsetting each of the
%   underlying datastores.

%   Copyright 2022 The MathWorks, Inc.

arguments
    N (1,1) double {mustBeInteger, mustBeNonnegative}
    numPartitionsPerDatastore (1,:) double {mustBeInteger, mustBeNonnegative}
end

totalNumPartitions = sum(numPartitionsPerDatastore, "all");
% Use basic pigeonHole without the optional third argument of indices 'ii'
% for the specific partition.
pigeonHolePartitionIndices = matlab.io.datastore.internal.util.pigeonHole(N, totalNumPartitions);
% To handle the case of 0 totalNumPartitions and empty
% numPartitionsPerDatastore when all underlying datastores are empty.
pigeonHolePartitionIndices = reshape(pigeonHolePartitionIndices, [], 1);

% Generate the source datastore index list corresponding to the
% totalNumPartitions.
% E.g.: if numPartitionsPerDatastore = [1 3 2]
% We generate the column vector: [1 2 2 2 3 3]'
% meaning, the first partition comes from first underlying datastore,
% the next 3 partitions come from the second underlying datastore, and
% finally the last 2 partitions should come from the third underlying datastore.
sourceDatastoreIndices = double.empty(0, 1);
for index = 1:numel(numPartitionsPerDatastore)
    sourceDatastoreIndices = [sourceDatastoreIndices; repmat(index, numPartitionsPerDatastore(index), 1)]; %#ok<AGROW>
end

% Generate a list or table for easier mapping of the pigeonHole partition
% indices to the source datastore indices.
T = table(sourceDatastoreIndices, pigeonHolePartitionIndices, VariableNames=["SourceDatastoreIndex" "PartitionIndex"]);
% Remove all duplicate rows as we are not interested in knowing which block
% out of the totalNumPartitions does each of these pigeonHolePartitionIndices
% belong to. This also avoids creating separate new underlying datastores
% in the output partition corresponding to each of the partitions within a
% single underlying datastore.
T = unique(T);

% Get the actual N which should be used for each underlying datastore. This
% will be count of the number of occurences for each SourceDatastoreIndex.
summary = groupsummary(T, "SourceDatastoreIndex");
T.N = zeros(height(T), 1);
for idx = 1:height(T)
    T.N(idx) = summary.GroupCount(summary.SourceDatastoreIndex == T.SourceDatastoreIndex(idx));
end

% Get the actual ii for each underlying datastore.
[uniqueSourceDatastoreIndices, startRowOfUniqueSourceDatastoreIndices, sourceDatastoreIndices] = unique(T.SourceDatastoreIndex); %#ok<ASGLU>
startPartitionIndex = T.PartitionIndex(startRowOfUniqueSourceDatastoreIndices);
allStartPartitionIndices = startPartitionIndex(sourceDatastoreIndices);
T.ii = T.PartitionIndex - allStartPartitionIndices + 1;
end