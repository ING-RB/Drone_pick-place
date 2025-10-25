% Implementation for "MaxNumWorkersPerHost" partitioning of a parallel pool

% Copyright 2024 The MathWorks, Inc.

classdef PartitionMethodMaxNumWorkersPerHost < parallel.internal.partition.PartitionMethod

    methods
        function validateArguments(~, ~, maxNumWorkersPerHost)
            if ~iIsValidInteger(maxNumWorkersPerHost)
                throwAsCaller(MException(message("MATLAB:parallel:pool:InvalidPartitionNumWorkersPerHost")));
            end
        end
        
        function partitionWorkers = partitionWorkers(~, pool, maxNumWorkersPerHost)
            allWorkers = pool.Workers;
            [uniqueHosts, ~, workerHost] = unique({allWorkers.Host});
            partitionWorkers = cell(numel(uniqueHosts), 1);
            for idx = 1:numel(uniqueHosts)
                workersForHost = allWorkers(workerHost == idx);
                numWorkersToSelect = min(numel(workersForHost), maxNumWorkersPerHost);
                partitionWorkers{idx} = workersForHost(1:numWorkersToSelect);
            end
            partitionWorkers = [partitionWorkers{:}];
        end
    end
end


function isValid = iIsValidInteger(n)
isValid = isscalar(n) && ...
        isnumeric(n) && ...
        n >= 0 && ...
        ~isinf(n) && ...
        (round(n) == n);
end
