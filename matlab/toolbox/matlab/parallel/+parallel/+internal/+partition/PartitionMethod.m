% Interface for partitioning a parallel pool

% Copyright 2024 The MathWorks, Inc.

classdef (Abstract) PartitionMethod < handle

    methods (Abstract)
        % Validate the argument provided
        validateArguments(obj, pool, arguments);

        % Returns a parallel.Worker array for the pool partition.
        partitionWorkers = partitionWorkers(obj, pool, arguments);
    end
end