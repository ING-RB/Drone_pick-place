function result = isOpenCLCodegen(ctx)
% Returns true if it is generating OpenCL code

%   Copyright 2022 The MathWorks, Inc.

    result = false;
    if ~isa(ctx, 'coder.BuildConfig')
        return;
    end
    gpuConfig = ctx.getConfigProp('GpuConfig');
    if ~isempty(gpuConfig)
        result = gpuConfig.Enabled && gpuConfig.isOpenCLCodegen();
    end
end
