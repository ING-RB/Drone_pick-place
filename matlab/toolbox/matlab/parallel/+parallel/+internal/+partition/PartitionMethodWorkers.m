% Implementation for "Workers" partitioning of a parallel pool

% Copyright 2024 The MathWorks, Inc.

classdef PartitionMethodWorkers < parallel.internal.partition.PartitionMethod

    methods
        function validateArguments(~, pool, workers)
            if isempty(workers)
                return;
            end
            
            isValid = isa(workers, "parallel.Worker") && ...
                    isvector(workers) && ...
                    isempty(setdiff(workers, pool.Workers));

            if ~isValid
                throwAsCaller(MException(message("MATLAB:parallel:pool:InvalidPartitionWorkersArgument")));
            end
        end
        
        function partitionWorkers = partitionWorkers(~, ~, workers)
            partitionWorkers = workers;
        end
    end
end