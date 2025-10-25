function [enabled] = getGpuEnabled(ctx)
%

%   Copyright 2016-2020 The MathWorks, Inc.

    cfg = coder.gpu.getGpuConfig(ctx);
    enabled = false;
    if ~isempty(cfg)
        enabled = cfg.Enabled;
    end
end
