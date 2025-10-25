function opts = parforOptions(executor, varargin)
%PARFOROPTIONS Options for parfor
%   OPTS = parforOptions(CLUSTER) builds a parfor options structure to be
%   used with parfor to specify that the body of the parfor-loop should be
%   executed directly on workers in parallel.Cluster CLUSTER without
%   creating a parallel pool. Instead, independent tasks will be submitted
%   to the cluster to execute the body of the loop. When building
%   parforOptions with a parallel.Cluster, it is important that the
%   NumWorkers property of the cluster accurately reflects the number of
%   workers available, otherwise the loop will not be partitioned as
%   expected.
%
%   OPTS = parforOptions(POOL) builds a parfor options structure to be used
%   with parfor to specify that the body of the parfor-loop should be
%   executed using the parallel.Pool instance POOL.
%
%   OPTS = parforOptions(POOL, 'MaxNumWorkers', M) builds a parfor options
%   structure to be used with parfor to specify that the body of the
%   parfor-loop should be executed using the parallel.Pool instance POOL
%   with a maximum of M workers. M must be a positive integer. By default,
%   MATLAB uses as many workers as it finds available.
%
%   OPTS = parforOptions(..., 'RangePartitionMethod', METHOD) defines how
%   the iterations of the parfor-loop will be divided into sub-ranges. Each
%   "sub-range" is a contiguous block of loop iterations that will be
%   executed as a group on a worker. Controlling the range partitioning can
%   enable the performance of a parfor-loop to be optimized. Each sub-range
%   should be large enough that the overhead of scheduling the sub-range is
%   small compared with the execution time of that sub-range. Sub-ranges
%   should be small enough that the loop iterates can be divided into a
%   sufficient number of sub-ranges to keep all the workers busy. Valid
%   values for METHOD are:
%
%      'auto' - the default sub-range partitioning method. This divides the
%      loop into sub-ranges of varying sizes to try and achieve good
%      performance for a variety of parfor-loops. In the special case where
%      the number of loop iterations is equal to the number of workers W
%      available, then the 'auto' method divides the loop into W
%      sub-ranges of size 1.
%
%      'fixed' - use fixed sub-range sizes. You must also specify
%      SubrangeSize to choose the size of the subranges.
%
%      FUN - uses function FUN to divide the loop iterations into
%      sub-ranges. SIZES is a vector of sub-range sizes such that SIZES =
%      FUN(N,W) where N is the number of iterations in the parfor-loop, and
%      W is the number of workers available to execute the loop. When the
%      loop is running on a parallel pool, W is the size of the pool. When
%      the loop is running using a cluster, W is the NumWorkers property of
%      the cluster. parforOptions requires sum(SIZES) == N.
%
%   OPTS = parforOptions(..., 'RangePartitionMethod', 'fixed', 'SubrangeSize', S)
%   divides the loop iterations into sub-ranges of size approximately S.
%   'SubrangeSize' is only supported when 'RangePartitionMethod' is set to
%   'fixed'.
%
%   OPTS = parforOptions(CLUSTER, ..., 'AutoAddClientPath', TF) specifies
%   if the client path is added to the path of the workers in the
%   parallel.Cluster instance CLUSTER. TF can be true or false. The default
%   is true.
%
%   OPTS = parforOptions(CLUSTER, ..., 'AutoAttachFiles', TF) enables
%   dependency analysis on the parfor-loop body and transfers required
%   files to the workers in the parallel.Cluster instance CLUSTER. TF can
%   be true or false. The default is true.
%
%   OPTS = parforOptions(CLUSTER, ..., 'AttachedFiles', FILES) specifies
%   the files to transfer to the workers in the parallel.Cluster instance
%   CLUSTER. FILES can be a character vector, string, string array, or cell
%   array of character vectors. The default is {}.
%
%   OPTS = parforOptions(CLUSTER, ..., 'AdditionalPaths', PATHS) specifies
%   the paths to add to the MATLAB path of the workers in the
%   parallel.Cluster instance CLUSTER before parfor executes. PATHS can be
%   a character vector, string, string array, or a cell array of character
%   vectors. The default is {}.
%
% See also parfor, parcluster, parpool.

% Copyright 2018-2021 The MathWorks, Inc.

narginchk(1, Inf);

if isscalar(executor) && isa(executor, 'parallel.Pool')
    % Short-circuit for the commonest case
    opts = parallel.parfor.PoolOptions.build(executor, varargin{:});
    return
end
    
validateattributes(executor, {'parallel.Pool', 'parallel.Cluster'}, ...
                   {'scalar'}, mfilename, 'executor', 1);

try
    if isa(executor, 'parallel.Pool')
        opts = parallel.parfor.PoolOptions.build(executor, varargin{:});
    elseif isa(executor, 'parallel.Cluster')
        opts = parallel.parfor.ClusterOptions.build(executor, varargin{:});
    end
catch E
    rethrow(E);
end
end
