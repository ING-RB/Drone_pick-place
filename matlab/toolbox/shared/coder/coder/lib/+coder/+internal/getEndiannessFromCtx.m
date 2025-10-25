function out = getEndiannessFromCtx(ctx)
%MATLAB Code Generation Private Function

%   Copyright 2022 The MathWorks, Inc.

if ctx.HardwareImplementation.ProdEqTarget
    out = ctx.HardwareImplementation.ProdEndianess;
else
    out = ctx.HardwareImplementation.TargetEndianess;
end


end