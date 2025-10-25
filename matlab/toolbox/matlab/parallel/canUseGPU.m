function ok = canUseGPU()
%canUseGPU  Verify that a supported GPU is available for use
%   tf = canUseGPU() returns true if the MATLAB installation
%   and environment can support GPU functionality. Returns false when there
%   is no available supported GPU, the driver is missing or not up-to-date,
%   or Parallel Computing Toolbox is not installed or licensed.
%
%   Example:
%       % Solve a linear system on the GPU if possible, otherwise use the
%       % CPU
%       N = 1000;
%       A = rand(N,N);
%       B = rand(N,1);
%       if canUseGPU()
%           A = gpuArray(A);
%       end
%       X = A \ B;
%
%   See also: gpuDeviceCount, gpuDevice, canUseParallelPool.

% Copyright 2012-2023 The MathWorks, Inc.

% If we have a GPU selected then we know the answer is true and can skip
% the more expensive queries.
persistent gpuAlreadySelected;
if ~isempty(gpuAlreadySelected) && gpuAlreadySelected
    ok = true;
    return
end

% Now check whether we have PCT and if so whether it can find a GPU to use
% We also need to make sure that GPU support is installed. This is particularly 
% important for deployed applications, since there is a separate to PCT GPU addin.
ok = matlab.internal.parallel.isPCTInstalled() ...
    && matlab.internal.parallel.isPCTLicensed() ...
    && parallel.internal.general.isGPUSupportInstalled() ...
    && parallel.internal.gpu.isAnyDeviceAvailable();


% First time through setup the persistent variable if the GPU libraries are
% available.
if ok && isempty(gpuAlreadySelected)
    % We know a GPU can be used, so add some callbacks so we know if it
    % gets selected/deselected.
    mgr = parallel.gpu.GPUDeviceManager.instance();
    addlistener(mgr, "DeviceSelected", @iDeviceSelected);
    addlistener(mgr, "DeviceDeselecting", @iDeviceDeselected);
    gpuAlreadySelected = parallel.internal.gpu.isAnyDeviceSelected;
end

    function iDeviceSelected(~,~)
        gpuAlreadySelected = true;
    end

    function iDeviceDeselected(~,~)
        gpuAlreadySelected = false;
    end

end

