function [target] = getGpuTarget(ctx)
%

%   Copyright 2017-2022 The MathWorks, Inc.

    target = '';
    if ((~isequal(ctx, [])) && (ctx.isCodeGenTarget({'rtw'})))
        try
            cfgData = ctx.ConfigData;
            if isa(cfgData,'Simulink.ConfigSet') % Simulink
                target = ctx.getConfigProp('HardwareBoard');
            else % MATLAB
                hwInfo = cfgData.Hardware;
                if isempty(hwInfo)
                    target = '';
                else
                    target = cfgData.Hardware.Name;
                end
            end
        catch
        end
    end
end
