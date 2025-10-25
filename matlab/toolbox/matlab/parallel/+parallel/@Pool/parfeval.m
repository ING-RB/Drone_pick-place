function f = parfeval(aPool, varargin)
%PARFEVAL Execute function on worker in parallel pool
%   F = PARFEVAL(P, FCN, NUMOUT, IN1, IN2, ...) requests the execution of the
%   function FCN on a worker contained in the parallel pool P, requesting NUMOUT
%   output arguments and supplying IN1, IN2, ... as input arguments. The
%   evaluation of FCN occurs asynchronously. F is an FevalFuture, from which the
%   results can be obtained when the worker has completed evaluating FCN. The
%   evaluation of FCN always proceeds unless you explicitly cancel execution by
%   calling cancel(F). To request multiple function evaluations, you must call
%   PARFEVAL multiple times.
%
%   Examples:
%   Submit a single request with Parallel Computing Toolbox and retrieve
%   the outputs

%   p = gcp(); % get the currently open parallel.Pool instance
%   % request a call to magic(10) on a worker
%   f = parfeval(p, @magic, 1, 10);
%   % At this point, MATLAB is free to perform other calculations.
%   % When the outputs of f are needed, use fetchOutputs to retrieve them.
%   % fetchOutputs blocks MATLAB until the results are available and
%   % retrieval is complete.
%   value = fetchOutputs(f);
%
%   Submit multiple requests with Parallel Computing Toolbox and retrieve
%   the outputs when they are ready
%
%   p = gcp();
%   % To request multiple evaluations, we use a loop.
%   for idx = 1:10
%     % calculate each magic square from 1:10
%     f(idx) = parfeval(p, @magic, 1, idx);
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
%   See also parallel.Pool.parfevalOnAll,
%            parfeval, parfevalOnAll,
%            parallel.FevalFuture,
%            parallel.FevalFuture.fetchNext,
%            parallel.FevalFuture.fetchOutputs.

%   Copyright 2013-2024 The MathWorks, Inc.

if ~isa(aPool, "parallel.Pool")
    varargin = [{aPool}, varargin];
    aPool = parallel.internal.parpool.getOrCreateCurrentPool();
end

if isempty(aPool)
    aPool = matlab.internal.serialPool();
end

if ~isscalar(aPool)
    parallel.internal.fevalqueue.parfevalError(aPool, 'parfeval');
end

f = parfeval(aPool, varargin{:});

end
