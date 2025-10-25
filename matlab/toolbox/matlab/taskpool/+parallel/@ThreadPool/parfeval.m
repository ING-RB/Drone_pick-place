%parfeval Execute function on thread in ThreadPool
%F = parfeval(P, FCN, NUMOUT, IN1, IN2, ...) requests the execution of the
%    function FCN on a thread contained in the threads pool P, requesting NUMOUT
%    output arguments and supplying IN1, IN2, ... as input arguments. The
%    evaluation of FCN occurs asynchronously. F is a FevalFuture, from which the
%    results can be obtained when the thread has completed evaluating FCN. The
%    evaluation of FCN always proceeds unless you explicitly cancel execution by
%    calling cancel(F). To request multiple function evaluations, you must call
%    PARFEVAL multiple times.
% 
%    Examples:
%    Submit a single request and retrieve the outputs
%    % request a call to magic(10) on a thread
%    P = parpool('threads');
%    f = parfeval(P, @magic, 1, 10);
%    % At this point, MATLAB is free to perform other calculations.
%    % When the outputs of f are needed, use fetchOutputs to retrieve them.
%    % fetchOutputs blocks MATLAB until the results are available and
%    % retrieval is complete.
%    value = fetchOutputs(f);
% 
%    Submit multiple requests and retrieve the outputs when they are ready
%    % To request multiple evaluations, we use a loop.
%    for idx = 1:10
%      % calculate each magic square from 1:10
%      f(idx) = parfeval(@magic, 1, idx);
%    end
%    % Collect the results as they become ready
%    magicResults = cell(1, 10);
%    for idx = 1:10
%       % fetchNext blocks until more results are available, and
%       % returns the index into f that is now complete, as well
%       % as the value computed by f.
%       [completedIdx, value] = fetchNext(f);
%       magicResults{completedIdx} = value;
%       fprintf('Got result with index: %d.\n', completedIdx);
%    end
%
% See also parallel.ThreadPool, 
%          parallel.ThreadPool/parfevalOnAll,
%          parallel.threads.FevalFuture, 
%          parallel.threads.FevalFuture/fetchOutputs, 
%          parallel.threads.FevalFuture/fetchNext
%          parallel.threads.FevalFuture/wait, 
%          parallel.threads.FevalFuture/cancel

% Copyright 2018-2019 The Mathworks, Inc.
