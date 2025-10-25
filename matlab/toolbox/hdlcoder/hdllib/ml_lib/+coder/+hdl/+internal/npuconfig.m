function npuconfig(imgRows, imgCols, imgDepth, kernelRows, kernelCols, ...
    boundaryMethod, boundaryConstant, numStreamedInputs)
%CODER.HDL.INTERNAL.NPUCONFIG Specify hdl.npufun configuration
%
%   This is a code generation function. It has no effect in MATLAB.

%   Copyright 2024 The MathWorks, Inc.


%#codegen

coder.internal.prefer_const(imgRows);
coder.internal.prefer_const(imgCols);
coder.internal.prefer_const(imgDepth);
coder.internal.prefer_const(kernelRows);
coder.internal.prefer_const(kernelCols);
coder.internal.prefer_const(boundaryMethod);
coder.internal.prefer_const(boundaryConstant);
coder.internal.prefer_const(numStreamedInputs);

if coder.target('hdl')
    coder.ceval('__hdl_internal_npu_config', imgRows, imgCols, imgDepth, ...
        kernelRows, kernelCols, coder.const(boundaryMethod(:)), ...
        boundaryConstant, numStreamedInputs);
end

end

% LocalWords:  npufun npu
