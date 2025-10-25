function out = ticBytes(aPool)
% ticBytes Start counting bytes transferred within parallel pool
%
%     Use the ticBytes and tocBytes functions together to measure how much
%     data is transferred to and from the workers in a parallel pool while
%     executing parallel language constructs and functions, such as parfor.
%
%     ticBytes(P) saves the current number of bytes transferred to each worker
%     in the pool P, so that later tocBytes(P) can measure the amount of data
%     transferred to each worker between the two calls.
%
%     startState = ticBytes(P) saves the state to an output argument,
%     startState. Use the value of startState as an input argument for
%     a subsequent call to tocBytes.
%
%     Example: Measure the amount of data transferred while running a simple
%              parfor loop on a Parallel Computing Toolbox parallel pool.
%
%         a = 0;
%         b = rand(100);
%         ticBytes(gcp);
%         parfor i = 1:100
%             a = a + sum(b(:, i));
%         end
%         tocBytes(gcp)
%
%     See also tocBytes, gcp.

%   Copyright 2016-2022 The MathWorks, Inc.
if numel(aPool) > 1
    % If a pool is provided, it must be a scalar pool.
    error(message("MATLAB:parallel:pool:ScalarPoolRequired", "ticBytes"));
end
if isempty(aPool)
    currentState = parallel.pool.TicBytesResult.createForEmptyPool();
else
    currentState = parallel.pool.TicBytesResult.createForUnsupportedPool();
end
if nargout > 0
    % Output requested so return and DO NOT set the internally held
    % state
    out = currentState;
else
    parallel.Pool.hEmptyPoolPreviousTicBytesResult(currentState);
end
end
