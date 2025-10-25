function device = resolveUseGPU(useGPU)
%resolveUseGPU Resolves a UseGPU request and returns a parallel.gpu.GPUDevice to use
%
%   Use matlab.internal.parallel.resolveUseGPU to validate the
%   customer-provided value for the name-value argument UseGPU. This
%   name-value argument enables GPU acceleration with Parallel Computing
%   Toolbox.
%
%   device = matlab.internal.parallel.resolveUseGPU(useGPU) returns an
%   empty 0x0 double or a parallel.gpu.GPUDevice object that represents the
%   selected GPU device. Specify useGPU as "on", "off", or "auto".
%
%   device = matlab.internal.parallel.resolveUseGPU("on") validates that
%   there is a parallel.gpu.GPUDevice available for computation and returns
%   it. If no parallel.gpu.GPUDevice is available, then the function
%   errors.
%
%   device = matlab.internal.parallel.resolveUseGPU("auto") validates and
%   returns a parallel.gpu.GPUDevice if it is available for computation.
%   Otherwise, it returns an empty 0x0 double. If there are any issues with
%   an existing GPU, then the function does not error.
%
%   device = matlab.internal.parallel.resolveUseGPU("off") returns an empty
%   0x0 double.
%
%
%   Example:
%
%   device = matlab.internal.parallel.resolveUseGPU("auto");
%   if isempty(device)
%       % Execute code on the CPU
%       result = rand(1e3);
%   else
%       % Execute code on the GPU
%       result = gpuArray.rand(1e3);
%   end
%
%
%   See also canUseGPU, gpuDevice, validateGPU.


%   Copyright 2024 The MathWorks, Inc.


useGPU = matlab.internal.parallel.validateUseGPUOption(useGPU);

% No request for GPU computation, return empty to represent serial
% execution.
if useGPU == "off"
    device = [];
    return
end

isGPUavailable = canUseGPU();

% Request for automatic GPU execution when no GPU is available. Silently
% fall back to serial execution.
if useGPU == "auto" && ~isGPUavailable
    device = [];
    return
end

% Request for GPU computation when at least one is available.
assert(useGPU == "on" || useGPU == "auto", "Expected UseGPU to be ""on"" or ""auto""");
if isGPUavailable
    % Return selected GPU device
    try
        % gpuDevice() will download the GPU libraries if needed.
        device = gpuDevice();
    catch err
        if useGPU == "auto"
            if err.identifier == "parallel:gpu:device:GpuLibsDownloadFailed"
                warnStruct = warning("off","backtrace"); % Do not display stack
                warning(message("MATLAB:parallel:gpu:InvalidGPUFallBack", err.message));
                warning(warnStruct);
            end
            device = [];
            return
        else
            ME = MException(message("MATLAB:parallel:gpu:BadGPUDevice"));
            ME = addCause(ME, err);
            throwAsCaller(ME);
        end
    end
    return
end

% Now, handle the case when a GPU was requested with "on" but no GPU is
% available and error.
assert(useGPU == "on" && ~isGPUavailable, "Expected UseGPU to be ""on"" with no GPU available");

% Check whether we have PCT installed and licensed.
if ~matlab.internal.parallel.isPCTLicensed()
    ME = MException(message("MATLAB:parallel:gpu:NoPCTLicense"));
    throwAsCaller(ME);
end
if ~matlab.internal.parallel.isPCTInstalled()
    ME = MException(message("MATLAB:parallel:gpu:NoPCTInstall"));
    throwAsCaller(ME);
end

% We also need to make sure that GPU support is installed during runtime of
% deployed applications. This is particularly important because there is a
% separate to PCT GPU addin for deployed applications.
if ~parallel.internal.general.isGPUSupportInstalled()
    ME = MException(message("MATLAB:parallel:gpu:NoGPUSupportInstalled"));
    throwAsCaller(ME);
end

% Check if there is a GPU available.
if ~parallel.internal.gpu.isAnyDeviceAvailable()
    ME = MException(message("MATLAB:parallel:gpu:NoGPUDeviceAvailable"));
    throwAsCaller(ME);
end

% If there is a GPU device available, try to select it.
try
    gpuDevice();
catch err
    ME = MException(message("MATLAB:parallel:gpu:BadGPUDevice"));
    ME = addCause(ME, err);
    throwAsCaller(ME);
end

% We should not reach this point in the validation.
ME = MException(message("MATLAB:parallel:gpu:UnexpectedError"));
throwAsCaller(ME);
end