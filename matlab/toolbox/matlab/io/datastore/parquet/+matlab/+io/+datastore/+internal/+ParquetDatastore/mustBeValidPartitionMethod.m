function partitionMethod = mustBeValidPartitionMethod(providedPartitionMethod)
%mustBeValidPartitionMethod   Validates the input PartitionMethod value.

%   Copyright 2023 The MathWorks, Inc.




partitionMethod = validatestring(providedPartitionMethod, ["rowgroup" "bytes" "file" "auto"], "parquetDatastore", "PartitionMethod");
partitionMethod = string(partitionMethod);

end
