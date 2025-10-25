function [sharedMemory] = getGpuSharedMemory(ctx)
%

%   Copyright 2019-2024 The MathWorks, Inc.

    cfg = coder.gpu.getGpuConfig(ctx);
    if ~isempty(cfg)
        sharedMemory = cfg.SharedMemorySize;
    else
        defaultConfig = coder.GpuCodeConfig;
        sharedMemory = defaultConfig.SharedMemorySize;
    end
end
