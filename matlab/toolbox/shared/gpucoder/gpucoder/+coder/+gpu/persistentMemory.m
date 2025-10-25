function persistentMemory(var)

%   coder.gpu.persistentMemory pragma for GPU coder persistent memory
%   coder.gpu.persistentMemory(VAR) is a pragma placed within a function
%   where VAR is defined as persistent variable. The VAR will allocated
%   on GPU as persistent memory if it is a fixed sized GPU Coder supported
%   type. It is not supported in Simulink code generation and simulation.
%
%   Example:
%
%   function output = foo(input)
%   coder.gpu.kernelfun();
%   persistent p;
%   if isempty(p)
%     p = zeros(1024,1);
%   end
%   coder.gpu.persistentMemory(p);
%   p = p + 1;
%   output = input + p;
%   end
%
%   This is a code generation function. It has no effect in MATLAB.
%
%   See also coder.gpu.constantMemory, coder.gpu.kernelfun, gpucoder.stencilKernel.

%   Copyright 2020-2024 The MathWorks, Inc.

%#codegen
    coder.allowpcode('plain');
    coder.gpu.internal.persistentMemoryImpl(var, true);

end
