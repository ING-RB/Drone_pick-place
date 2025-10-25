function canOpenPool = canUseParallelPool()
%canUseParallelPool  Verify that parallel features can use a pool
%   canUseParallelPool returns true if Parallel Computing Toolbox is
%   installed and licensed, and parallel features such as parfor, parfeval
%   can use a parallel pool. This function does not create a parallel pool.
%   If this function returns true, you can still receive an error when a 
%   parallel pool is created if your parallel cluster is not properly
%   configured or cannot be contacted.
%
%   Example:
%       if canUseParallelPool()
%           pool = gcp(); % Opens pool if not already open
%           ... % Parallel-optimized code
%       else
%           ... % Normal in-memory code
%       end
%
%   See also GCP, canUseGPU.

% Copyright 2020-2023 The MathWorks, Inc.

if ~matlab.internal.parallel.isPCTInstalled() ...
        || ~matlab.internal.parallel.isPCTLicensed()
    % If we don't have Parallel Computing Toolbox then the answer is definitely no!
    canOpenPool = false;
    
elseif ~isempty(gcp("nocreate"))
    % If a pool is already open, the answer is definitely yes!
    canOpenPool = true;
    
else
    % Finally, check if auto-create is active and if so that a valid
    % default is set.
    canOpenPool = parallel.internal.parpool.shouldAutoCreate(parallel.Pool.empty());
    
end
end
