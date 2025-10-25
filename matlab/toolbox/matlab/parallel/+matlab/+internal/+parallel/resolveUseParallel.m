function pool = resolveUseParallel(parallelSupportRequested)
% resolveUseParallel Resolve a UseParallel request from the user and return pool to use
%
%     Use matlab.internal.parallel.resolveUseParallel to validate the
%     customer-provided value for the name-value argument UseParallel. This
%     name-value argument enables CPU parallelization with parallel pools
%     and Parallel Computing Toolbox.
%
%     pool =
%     matlab.internal.parallel.resolveUseParallel(parallelSupportRequested)
%     returns either a non-empty parallel.Pool instance that can be used by
%     the caller, or parallel.Pool.empty(), or throws an appropriate error.
%
%     Valid values for parallelSupportRequested are:
%       - scalar text with value: "on", "off", "auto"
%       - scalar logical, where TRUE is equivalent to "auto", and FALSE
%         equivalent to "off"
%
%     resolveUseParallel("on") returns a non-empty parallel.Pool instance.
%     If one cannot be created for any reason, then an appropriate error is
%     thrown. This error should be forwarded to the user.
%
%     resolveUseParallel("off" | false) returns parallel.Pool.empty() in
%     all cases.
%
%     resolveUseParallel("auto" | true) returns a parallel.Pool instance in
%     the following cases:
%       - a parallel pool is already open - this pool is returned
%       - the user has left AutoCreate in its default state of "on",
%         and a parallel pool can be created
%
%     The following "auto" cases return an empty parallel.Pool:
%       - no parallel pool is open, and AutoCreate is "off"
%       - no parallel pool is open, and the code is executing on a worker
%       - no PCT licence is available
%       - PCT is not installed
%       - constructing the parallel pool results in an error
%
%    All errors are thrown using throwAsCaller, so wrapping calls to
%    resolveUseParallel in try/catch is not recommended.
%
%    See also matlab.internal.parallel.validateUseParallelOption, 
%    canUseParallelPool, parallel.Pool, parpool.

% Copyright 2024-2025 The MathWorks, Inc.

    try
        pool = iResolveUseParallel(parallelSupportRequested);
    catch E
        throwAsCaller(E);
    end
end

function pool = iResolveUseParallel(parallelSupportRequested)
    parallelSupportRequested = matlab.internal.parallel.validateUseParallelOption(parallelSupportRequested);
    pool = parallel.Pool.empty();

    % Request is "off" - no further action required.
    if strcmp(parallelSupportRequested, "off")
        return
    end

    % Starting point is to query whether we can use a pool.
    canUse = canUseParallelPool();
    if canUse
        try
            pool = gcp();
        catch err
            if parallelSupportRequested == "auto"
                warnStruct = warning("off", "backtrace"); % Do not display stack
                warning(message("MATLAB:parallel:pool:InvalidParallelPoolFallBack"));
                warning(warnStruct);
                pool = parallel.Pool.empty();
                return
            else
                throwAsCaller(err);
            end
        end
    end

    % If we got a pool, or we're in "auto" mode, we're done.
    if parallelSupportRequested == "auto" || ~isempty(pool)
        return
    end
    
    % Must be in "on" mode with no pool, so let's work out why and throw an error.
    if ~matlab.internal.parallel.isPCTLicensed()
        error(message('MATLAB:parallel:pool:PCTNotLicensed'));
    end
    if ~matlab.internal.parallel.isPCTInstalled()
        error(message('MATLAB:parallel:pool:PCTNotInstalled'));
    end
    if parallel.internal.general.isParallelWorker()
        error(message('MATLAB:parallel:pool:NoAutoCreateOnWorker'));
    end
    [canAutoCreate, reasons] = parallel.internal.parpool.shouldAutoCreate(pool);
    if ~canAutoCreate
        if ~reasons.DefaultProfileEnabled
            error(message('parallel:cluster:MatlabOnlineNoDefaultProfile'));
        end
        error(message('MATLAB:parallel:pool:NoAutoCreate'));
    end
    % The above cases are intended to cover everything, hence we leave this case as a simple
    % assertion.
    assert(false, "Unexpected failure to create parallel pool.");
end
