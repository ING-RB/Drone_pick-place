function [cfg] = getGpuConfig(ctx)
%

%   Copyright 2016-2024 The MathWorks, Inc.

    cfg = [];

    if ((~isequal(ctx, [])) && (ctx.isCodeGenTarget({'mex', 'rtw'})))
        try
            cfg = ctx.getConfigProp('GpuConfig');
        catch
            % may error if ctx is Simulink context
            cfg = [];
        end
    end

end
