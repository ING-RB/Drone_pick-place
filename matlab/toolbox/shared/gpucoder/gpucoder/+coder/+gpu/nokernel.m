function nokernel()
%   CODER.GPU.NOKERNEL disables automatic kernel creation for the loop that follows it
%   CODER.GPU.NOKERNEL() is a loop level pragma that when placed immediately
%   before a for loop prevents the code generator from generating CUDA kernels
%   for the statements within the loop. This pragma does not require any input
%   parameters.
%
%   Examples:
%
%   coder.gpu.nokernel()
%   for i = 1:100
%       c[i] = b[i] * k;
%   end
%
%   This is a code generation function.  It has no effect in MATLAB.
%
%   See also coder.gpu.kernelfun, coder.gpu.kernel, gpucoder.stencilKernel,
%   coder.gpu.constantMemory.


%#codegen
%   Copyright 2015-2024 The MathWorks, Inc.

    if (~coder.target('MATLAB'))
        coder.allowpcode('plain');
        coder.inline('always');
        coder.gpu.internal.nokernelImpl(true);
    end
end
