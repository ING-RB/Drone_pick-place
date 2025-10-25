function n = maxpartitions(ds)
%MAXPARTITIONS Return the maximum number of partitions
%   possible for the datastore.

%   Copyright 2022 The MathWorks, Inc.

ds.verifyPartitionable("numpartitions");

% Handle the empty case first.
if isempty(ds.UnderlyingDatastores)
    n = 0;
else
    n = sum(cellfun(@numpartitions, ds.UnderlyingDatastores));
end
end