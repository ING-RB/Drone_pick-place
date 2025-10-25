function kernelfun()
%CODER.GPU.KERNELFUN specifies function should be mapped to GPU kernels
%   CODER.GPU.KERNELFUN() is a global level pragma that attempts to
%   map all the computation within this function on to the GPU. Loops
%   within this function are parallelized in to GPU kernels only if they
%   pass the parallel-loop analysis check. This analysis tries to prove
%   that every loop iteration is independent of every other loop iteration.
%   This pragma does not require input parameters and generates kernels
%   whose dimensions are computed automatically based on loop parameters.
%
%   Example:
%
%   For the following program, GPU coder creates a kernel for each of the
%   for-loops based on the loop bounds.
%
%   function [vout, sout1, sout2] = scalars(input1,input2,scale,factor)
%       CODER.GPU.KERNELFUN();
%       sout1 = 0;
%       sout2 = 1;
%       vout = coder.nullcopy(zeros(size(input1)));
%       for i=1:4096
%           vout(i) = input1(i) + input2(i);
%       end
%       for i=1:1024
%           sout1 = (input1(i)*scale) + sout1;
%       end
%       for i=1:512
%           sout2 = (input2(i)/factor) + sout2;
%       end
%   end
%
%   This is a code generation function.  It has no effect in MATLAB.
%
%   See also coder.gpu.kernel, gpucoder.stencilKernel,
%   coder.gpu.constantMemory.

%#codegen
%   Copyright 2015-2024 The MathWorks, Inc.
    if (~coder.target('MATLAB'))
        coder.allowpcode('plain');
        coder.inline('always');
        coder.gpu.internal.kernelfunImpl(true);
    end
end
