function tf = isParallelWorker()
% isParallelWorker returns TRUE for any MVM which is a parallel worker.
% Certain operations such as auto-open and auto-recreate of parallel pools
% are currently disabled in these environments.

% Copyright 2023-2024 The MathWorks, Inc.

if parallel.internal.pool.isPoolThreadWorker()
    % Thread-based pool workers.
    tf = true;
elseif system_dependent('isdmlworker') ...
        && (~isempty(getCurrentJob()) || parallel.internal.general.isHadoopWorker())
    % Process-based worker.
    tf = true;
else
    tf = false;
end

end

