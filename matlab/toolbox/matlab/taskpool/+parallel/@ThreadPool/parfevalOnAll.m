%parfevalOnAll Execute function on all threads in ThreadPool
%F = parfevalOnAll(P, FCN, NUMOUT, IN1, IN2, ...) requests the execution of the
%    function FCN on all threads contained in the ThreadPool P, requesting NUMOUT
%    output arguments and supplying IN1, IN2, ... as input arguments. The
%    evaluation of FCN occurs asynchronously. F is a FevalOnAllFuture, from which the
%    results can be obtained when all threads have completed executing FCN. 
% 
%    Examples:
%    Submit a single request and retrieve the outputs
%    % request a call to magic(10) on a thread
%    P = parpool('threads');
%    F = parfevalOnAll(@rand, 1, 2, 3);
%    value = fetchOutputs(F);
%    value is a 12 by 3 matrix if the pool has 6 threads.
%
% See also parallel.ThreadPool, 
%          parallel.ThreadPool/parfeval,
%          parallel.threads.FevalOnAllFuture, 
%          parallel.threads.FevalOnAllFuture/fetchOutputs, 
%          parallel.threads.FevalOnAllFuture/wait, 
%          parallel.threads.FevalOnAllFuture/cancel

% Copyright 2018-2019 The Mathworks, Inc.
