function cleanupWorkerLogicalState
% Function to cleanup all per-logical-pool state on a thread worker.

%   Copyright 2021-2024 The MathWorks, Inc.

parallel.internal.dataqueue.AbstractDataQueue.cleanupWorkerLogicalState();

% Turn off profiling is still enabled. This is triggered if a user deletes
% either the parpool("Threads") or backgroundPool. The fact this affects
% both is a necessary trade-off for the MVM to be shared, we choose to do
% so here because we don't expect users to be profiling across pool
% shutdown.
if ~isdeployed ...
        && exist("matlab.internal.profiler.ProfilerService", "class") ...
        && ~matlab.internal.profiler.ProfilerService.getInstance().Locked
    profile("off");
end

% Ensure that GPU caches (E.G. kernels, memory pool etc.) are cleared when
% a user deletes parpool("Threads") or backgroundPool. We don't go further
% than this because this worker might be shared between two pools and we
% don't want to invalidate gpuArrays still held by the other pool.
if matlab.internal.parallel.isPCTLicensed && matlab.internal.parallel.isPCTInstalled
    % It's possible for the underlying GPU device to be in an invalid state
    % (E.G. crashed), so we must guard against errors issued by these
    % commands. Such errors indicate there was no cached memory to release
    % in the first place.
    try %#ok<TRYNC> 
        if parallel.internal.gpu.isAnyDeviceSelected
            releaseCachedMemory(gpuDevice);
        end
    end

    % Key-value store per-worker state. 
    parallel.internal.pool.ThreadsKeyValueStoreAdapter.cleanupWorkerLogicalState();

    % Clean up and remote data for this pool
    spmdlang.ValueStore.clear();
    
    % Clean up Constant data for this pool
    parallel.internal.constant.remoteClearAll();
end
