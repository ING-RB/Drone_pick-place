function f = parfeval(varargin)
%PARFEVAL Execute function on worker in parallel pool
%   F = PARFEVAL(FCN, NUMOUT, IN1, IN2, ...) requests the execution of the
%   function FCN on a worker contained in the current parallel pool, requesting NUMOUT
%   output arguments and supplying IN1, IN2, ... as input arguments. The
%   evaluation of FCN occurs asynchronously. F is an FevalFuture, from which the
%   results can be obtained when the worker has completed evaluating FCN. The
%   evaluation of FCN always proceeds unless you explicitly cancel execution by
%   calling cancel(F). To request multiple function evaluations, you must call
%   PARFEVAL multiple times.
%
%   F = PARFEVAL(P, FCN, NUMOUT, IN1, IN2, ...) requests execution on a parallel
%   pool worker taken from the parallel pool P.
%
%   Examples:
%   Submit a single request and retrieve the outputs
%   % request a call to magic(10) on a worker
%   f = parfeval(@magic, 1, 10);
%   % At this point, MATLAB is free to perform other calculations.
%   % When the outputs of f are needed, use fetchOutputs to retrieve them.
%   % fetchOutputs blocks MATLAB until the results are available and
%   % retrieval is complete.
%   value = fetchOutputs(f);
%
%   Submit multiple requests and retrieve the outputs when they are ready
%   % To request multiple evaluations, we use a loop.
%   for idx = 1:10
%     % calculate each magic square from 1:10
%     f(idx) = parfeval(@magic, 1, idx);
%   end
%   % Collect the results as they become ready
%   magicResults = cell(1, 10);
%   for idx = 1:10
%      % fetchNext blocks until more results are available, and
%      % returns the index into f that is now complete, as well
%      % as the value computed by f.
%      [completedIdx, value] = fetchNext(f);
%      magicResults{completedIdx} = value;
%      fprintf('Got result with index: %d.\n', completedIdx);
%   end
%
%   See also parallel.FevalFuture.fetchNext,
%            parallel.FevalFuture.fetchOutputs,
%            parallel.FevalFuture.wait,
%            parallel.FevalFuture.cancel,
%            parallel.FevalFuture,
%            parfevalOnAll,
%            parallel.Pool.parfeval,
%            parallel.Pool.parfevalOnAll,
%            parallel.Future.afterEach,
%            parallel.Future.afterAll.

% Copyright 2013-2021 The MathWorks, Inc.

try
    f = parfevalMethodInvoker(@parfeval, varargin{:});
catch E
    throw(E);
end

end
