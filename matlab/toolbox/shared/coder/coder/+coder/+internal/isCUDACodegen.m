function result = isCUDACodegen(ctx)
% Returns true if it is generating CUDA code

%   Copyright 2022 The MathWorks, Inc.

    result = false;
    if ~isa(ctx, 'coder.BuildConfig')
        return;
    end
    gpuConfig = ctx.getConfigProp('GpuConfig');
    if ~isempty(gpuConfig)
        result = gpuConfig.Enabled && gpuConfig.isCUDACodegen();
    elseif strcmpi(ctx.CodeGenTarget, 'sfun')
        result = strcmpi(ctx.getConfigProp('GPUAcceleration'), 'on');
    elseif strcmpi(ctx.CodeGenTarget, 'rtw')
        result = strcmpi(ctx.getConfigProp('GenerateGPUCode'), 'CUDA');
    end
end
