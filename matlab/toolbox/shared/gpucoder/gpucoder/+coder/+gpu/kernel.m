function kernel(varargin)
%CODER.GPU.KERNEL specifies a for loop should be mapped to a GPU kernel
%   CODER.GPU.KERNEL(B, T) is a loop level pragma that must be placed
%   immediately before a for loop, and generates a kernel with the
%   dimensions specified by B and T. B[Bx,By,1] is an array that defines
%   the number of blocks in the grid along dimensions x and y (z not used).
%   T[Tx,Ty,Tz] is an array that defines the number of threads in the block
%   along dimensions x, y and z. The CODER.GPU.KERNEL pragma will generate
%   errors for invalid grid and block dimensions.
%
%   CODER.GPU.KERNEL(B, T, M, NAME) expects the same B and T arguments as
%   above, and allows the user to specify optional arguments M and NAME.
%   M is a positive integer specifying the minimum number of blocks per
%   streaming multiprocessor.  In some cases, increasing M can reduce the
%   register usage within a kernel and improve kernel occupancy.  A value
%   of -1 for M indicates that GPU Coder should use the default value of 1.
%   NAME is a character array containing the name that should be used for
%   the generated kernel.
%
%   Specifying the kernel pragma overrides all parallel loop analysis
%   checks, which allows loops where parallel loop analysis cannot prove
%   that all iterations are independent of each other to be parallelized.
%   It is the user's responsibility to ensure that the loop is actually
%   safe to parallelize.
%
%   Examples:
%
%   coder.gpu.kernel([16, 16, 1], [16, 16, 1])
%   for i = 1:256
%       for j = 1:256
%           ...
%       end
%   end
%   generates a 2D grid of 2D blocks. The kernel has 16x16 blocks and there
%   are 256 threads per block.
%
%   coder.gpu.kernel(8,512)
%   for i = 1:4096
%      ...
%   end
%   generates a 1D grid of 1D blocks. The kernel has 8 blocks and there are
%   512 threads per block.
%
%   This is a code generation function.  It has no effect in MATLAB.
%
%   See also coder.gpu.kernelfun, gpucoder.stencilKernel,
%   coder.gpu.constantMemory.

%#codegen
%   Copyright 2015-2024 The MathWorks, Inc.

end
