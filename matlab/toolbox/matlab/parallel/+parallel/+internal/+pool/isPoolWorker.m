function tf = isPoolWorker()
% isPoolWorker returns TRUE for workers that are part of a pool, FALSE otherwise.

% Copyright 2014-2024 The MathWorks, Inc.


if parallel.internal.pool.isPoolThreadWorker()
    % Thread-based pool workers.
    tf = true;
elseif ~system_dependent('isdmlworker') || ~matlab.internal.parallel.isPCTInstalled()
    % Client.
    tf = false;
else
    % Otherwise, check for process-based pool workers.
    j = getCurrentJob();
    tf = ~isempty(j) && pCurrentTaskIsPartOfAPool(j);
end
end
