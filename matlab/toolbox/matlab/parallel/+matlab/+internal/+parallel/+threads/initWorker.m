function initWorker(parentStreamIdxVector, workerIdx, maxWorkerIdx)
% Function to initialize all internal worker-side state for a thread-based parallel pool.
% This includes:
%  1. Default RNG
%  2. Default GPU device selection (only if PCT is licensed and installed)

%   Copyright 2021-2022 The MathWorks, Inc.

% It is assumed this worker is a thread-pool worker and not a process-pool worker.
assert(parallel.internal.pool.isPoolThreadWorker());

% FID
matlab.io.internal.setFileMgrOffset((double(workerIdx) * 10000) - 2);

% RNG
streamIdxVector = [parentStreamIdxVector, workerIdx];
[cpuStream, gpuStream] = matlab.internal.parallel.createWorkerRandStream(streamIdxVector);

% Set the default RNG for the CPU and force the global RNG back to the default.
matlab.internal.math.setDefaultRandStream(cpuStream);
RandStream.restoreDefaultGlobalStream();

% GPU device selection
if matlab.internal.parallel.isPCTLicensed ...
        && matlab.internal.parallel.isPCTInstalled
    parallel.internal.pool.gpuDeviceSelection(gpuStream, workerIdx, maxWorkerIdx)
end

end
