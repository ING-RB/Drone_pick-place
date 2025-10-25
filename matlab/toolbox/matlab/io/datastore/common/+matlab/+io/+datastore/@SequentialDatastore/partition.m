function partds = partition(ds, n, index)
%PARTITION   Return a SequentialDatastore containing a
%   part of the underlying datastore.
%
%   SUBDS = PARTITION(DS, N, INDEX) partitions DS into N parts
%   and  returns the partitioned Datastore, SUBDS, corresponding
%   to INDEX. An estimate for a reasonable value for N can be obtained
%   by using the NUMPARTITIONS function.
%
%   SUBDS = partition(DS, "Files", INDEX) partitions DS by files in the
%   underlying datastores and returns the partition corresponding to INDEX.
%
%   SUBDS = partition(DS, "Files", FILENAME) partitions DS by files in the
%   underlying datastores and returns the partition corresponding to FILENAME.
%
%   A SequentialDatastore is only partitionable when
%   all of its underlying datastores are partitionable. The
%   isPartitionable method indicates whether a datastore is
%   partitionable or not.
%
%   See also: isPartitionable, numpartitions

%   Copyright 2022 The MathWorks, Inc.

try
    ds.verifyPartitionable("partition");

    % Basic type validation for Partition Strategy.
    partitionStrategy = convertStringsToChars(n);
    validateattributes(partitionStrategy, {'char', 'string', 'numeric'}, ...
        {'nonempty'}, 'partition', 'second argument');

    if isnumeric(partitionStrategy)
        % Numeric Partition Strategy.
        partds = partitionByNumericIndex(ds, partitionStrategy, index);
    else
        % "Files" is the only accepted non-numeric Partition Strategy,
        % early error if not.
        if ~strcmpi(partitionStrategy, "Files")
            error(message("MATLAB:datastoreio:splittabledatastore:invalidPartitionStrategy", partitionStrategy));
        end

        % "Files" Partition Strategy.
        partds = partitionByFiles(ds, partitionStrategy, index);
    end
catch ME
    throw(ME);
end
end