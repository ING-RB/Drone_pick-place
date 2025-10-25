function iterations(numOfIterations)
%
%   CODER.GPU.ITERATIONS pragma can be used to specify the average number
%   of iterations (AVG_NUM_ITER) for a variable-bound for-loop that immediately
%   follows it. This value is used to provide hueristics towards making
%   parallelization decisions for imperfect loops. This pragma does not have
%   any effect on fixed-bound for-loops.
%
%   Example:
%
%   function [a, c] = testIter(b, N1)
%
%   coder.gpu.kernelfun();
%   a = coder.nullcopy(zeros(1, N1));
%   c = coder.nullcopy(b);
%
%   for i = 1:N1             % Loop1
%      a(i) = 1;
%
%      for j = 1:20          % Loop2
%          c(i,j) = 2 * b(i,j);
%      end
%   end
%
%   end
%
%   During code generation, loop hueristics will parallelize the inner
%   for-loop (Loop 2). We can use the CODER.GPU.ITERATIONS pragma to
%   parallelize the outer for-loop (Loop 1) by providing AVG_NUM_ITER.
%   Loop 1 is parallelized when AVG_NUM_ITER > 20 (Loop2 bound) regardless
%   of the value of N1.
%
%   function [a, c] = testIter(b, N1)
%
%   coder.gpu.kernelfun();
%   a = coder.nullcopy(zeros(1, N1));
%   c = coder.nullcopy(b);
%
%   coder.gpu.iterations(25) % AVG_NUM_ITER
%   for i = 1:N1             % Loop1
%      a(i) = 1;
%
%      for j = 1:20          % Loop2
%          c(i,j) = 2 * b(i,j);
%      end
%   end
%
%   end
%
%   This is a code generation function. It has no effect in MATLAB.
%
%   See also coder.gpu.kernelfun, coder.gpu.kernel, gpucoder.stencilKernel,
%   coder.gpu.constantMemory.


%#codegen
%   Copyright 2015-2024 The MathWorks, Inc.

    if (~coder.target('MATLAB'))
        coder.allowpcode('plain');
        coder.inline('always');
        coder.internal.assert(nargin == 1, 'gpucoder:common:IterationsPragmaOneInputArg');
        coder.gpu.internal.iterationsImpl(true, numOfIterations);
    end
end
