function [newPool, remainingPool] = partition(aPool, partitionMethod, partitionArgument)
%PARTITION Create a new pool object which utilizes a subset of the input pool resources.
%   NEWPOOL = PARTITION(POOL, PARTITIONMETHOD, PARTITIONARGUMENT) creates a new pool object, NEWPOOL,
%   which utilizes a subset of the resources of the input pool, POOL. Both POOL and NEWPOOL
%   schedule work to the same underlying collection of workers. Work executing
%   for one pool instance can delay the execution of work for another.
%   The NumWorkers value for NEWPOOL reflects the number of workers the pool
%   can execute work on.
%
%   NEWPOOL shares some properties with the input pool, POOL.
%   Changes to these properties affect all pools. These shared properties include:
%     - AttachedFiles
%     - FileStore
%     - ValueStore
%     - IdleTimeout
%
%   Deleting any pool instance deletes the underlying collection of
%   workers and any Job backing the pool. All pools using the same collection
%   of resources become invalid. If a pool instance is no longer needed,
%   allow the instance to go out of scope rather than explicitly deleting it.
%
%   [NEWPOOL, REMAININGPOOL] = PARTITION(POOL, "Workers", WORKERS)
%   Returns a scalar pool instance, NEWPOOL, contining only workers specified by WORKERS,
%   an array of parallel.Worker. Every worker in WORKERS must be a member of the Workers
%   property of the input pool, POOL. REMAININGPOOL is a scalar pool instance containing
%   the set of workers in POOL, but not in NEWPOOL.
%
%   [NEWPOOL, REMAININGPOOL] = PARTITION(POOL, "MaxNumWorkersPerHost", N)
%   Returns a scalar pool instance with up to N workers for each unique host of the input POOL.
%   If a host has fewer than N available workers, the function selects all available workers.
%   REMAININGPOOL is a scalar pool instance containing the set of workers in POOL, but not in NEWPOOL.
%
%   [NEWPOOL, REMAININGPOOL] = PARTITION(POOL, "MaxNumWorkersPerGPU", N)
%   Returns a scalar pool instance with up to N workers for each unique GPU of the input POOL.
%   If a GPU has fewer than N allocated workers, the function selects all available workers.
%   This method uses the result of gpuDevice on each parallel pool worker to
%   determine which worker is associated with which GPU. The function considers only 
%   workers with an allocated GPU device. The value of gpuDevice is not modified 
%   by this operation.
%   REMAININGPOOL is a scalar pool instance containing the set of workers in POOL, but not in NEWPOOL.
%   For the "NumWorkersPerGPU" partition method, the partition function executes code on all
%   workers in POOL to gather gpuDevice information. If any worker is busy executing a parfeval,
%   the PARTITION function waits until that work completes.
%
%
%   Examples:
%   % Create a pool of one specific worker.
%   [singleWorkerPool, remainingPool] = partition(pool, "Workers", pool.Workers(1));
%
%   % Create a pool with one worker per host.
%   [perHostPool, remainingPool] = partition(pool, "MaxNumWorkersPerHost", 1);
%
%   % Create a pool with one worker per gpu.
%   [gpuWorkers, cpuWorkers] = partition(pool, "MaxNumWorkersPerGPU", 1);
%
%   See also gcp, parfor, spmd, parfeval, parfevalOnAll,
%            parpool, parallel.Cluster/parpool, parallel.Pool/delete.

%   Copyright 2024 The MathWorks, Inc.

arguments (Input)
    aPool (1,1) parallel.Pool
    partitionMethod {mustBeTextScalar}
    partitionArgument
end
aPool.hGetEngine().throwIfShutdown();

partitionWorkers = parallel.internal.partition.PartitionMethods.getPartitionWorkers(partitionMethod, aPool, partitionArgument);
newPool = iCreatePartition(aPool, partitionWorkers);

if nargout > 1
    allWorkers = aPool.Workers;
    if isempty(partitionWorkers)
        remainingWorkers = allWorkers;
    else
        remainingWorkers = setdiff(allWorkers, partitionWorkers, "stable");
    end
    remainingPool = iCreatePartition(aPool, remainingWorkers);
end
end

function partition = iCreatePartition(pool, partitionWorkers)
if isempty(partitionWorkers)
    partition = createArray(0,0,Like=pool);
    return
end
engine = pool.hGetEngine();
partition = engine.createPoolPartition(pool, unique(partitionWorkers, "stable"));
end
