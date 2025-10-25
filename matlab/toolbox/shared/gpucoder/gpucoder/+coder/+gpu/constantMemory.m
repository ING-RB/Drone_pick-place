function constantMemory(var)

%   coder.gpu.constantMemory pragma for GPU coder constant memory
%   coder.gpu.constantMemory(VAR) is a pragma placed
%   within a parallelizable loop. If a kernel is generated for the loop,
%   this pragma loads VAR to a device constant memory variable and any
%   access to VAR within the kernel is replaced by access to the constant
%   memory variable.
%
%   The variable VAR must be read-only within the kernel, otherwise
%   a warning is thrown and the pragma is ignored.
%   Use this pragma for parameters that are uniformly read by all
%   iterations of the loop.
%
%   Examples:
%
%   coder.gpu.kernel();
%   for i = 1:256
%     for j = 1:256
%       coder.gpu.constantMemory(k);
%       a(i,j) = a(i,j) + k(1) + k(2) + k(3);
%     end
%   end
%
%   The variable k is copied to a device constant array variable const_k
%   and const_k is accessed in the generated kernel body.
%
%   This is a code generation function. It has no effect in MATLAB.
%
%   See also coder.gpu.kernel, coder.gpu.kernelfun, gpucoder.stencilKernel.

%   Copyright 2016-2024 The MathWorks, Inc.

%#codegen

    coder.gpu.internal.constantMemoryImpl(var, true);

end
