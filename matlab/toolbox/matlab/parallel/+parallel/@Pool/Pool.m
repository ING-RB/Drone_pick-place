%Pool base class for all pool objects
%   parallel.Pool is the class for all parallel pool objects.
%
%   parallel.Pool methods:
%      addAttachedFiles      - Attach files to pool
%      delete                - Delete the pool of workers
%      listAutoAttachedFiles - lists the files automatically attached to pool
%      parfeval              - Execute function on worker in parallel pool
%      parfevalOnAll         - Execute function on all workers in parallel pool
%      updateAttachedFiles   - Update changed files that are attached to pool
%      ticBytes              - Start counting bytes transferred within parallel pool
%      tocBytes              - Read how many bytes have been transferred since calling ticBytes
%
%   See also parallel.Pool/addAttachedFiles,
%   parallel.Pool/updateAttachedFiles, parallel.Pool/listAutoAttachedFiles,
%   parallel.Pool/delete, parfor.

% Copyright 2013-2021 The MathWorks, Inc.

%{
    properties (Abstract, SetAccess = private)
        % NumWorkers Number of workers comprising this pool
        %   (read-only)
        NumWorkers

        % Busy True if this pool has outstanding work to complete.
        %   (read-only)
        Busy
        
        %Connected False if the parallel pool has shut down
        %   (read-only)
        Connected
        
        %SpmdEnabled True if the SPMD language construct is enabled
        %   (read-only)
        SpmdEnabled
    end
    
    properties (Abstract, SetAccess = immutable)
        %FevalQueue parallel pool FevalQueue instance
        %   FevalQueue can be used to inspect the pending
        %   and running FevalFutures of a parallel pool. New futures are created using
        %   the parfeval and parfevalOnAll functions.
        %
        %   See also parfeval, parfevalOnAll,
        %            parallel.Pool.parfeval,
        %            parallel.Pool.parfevalOnAll,
        %            parallel.FevalQueue.
        FevalQueue
    end
%}

