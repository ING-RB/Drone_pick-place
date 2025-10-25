function out = tocBytes(aPool, previousState)
% tocBytes Read how many bytes have been transferred since calling ticBytes
%
%     Use the ticBytes and tocBytes functions together to measure how much
%     data is transferred to and from the workers in a parallel pool while
%     executing parallel language constructs and functions, such as parfor.
%
%     tocBytes(P) without an output argument displays the total number of
%     bytes transferred to and from each of the workers in a parallel pool P
%     since the most recent execution of ticBytes.
%
%     bytes = tocBytes(P) returns a matrix of size numWorkers x 2 containing
%     the bytes transferred to and from each of the workers in the parallel
%     pool P.
%
%     tocBytes(P, startState) displays the total number of bytes transferred
%     in the parallel pool P since the ticBytes command that generated
%     startState.
%
%     Example: Measure the amount of data transferred while running a simple
%              parfor loop on a Parallel Computing Toolbox parallel pool.
%
%         a = 0;
%         b = rand(100);
%         startS = ticBytes(gcp);
%         parfor i = 1:100
%             a = a + sum(b(:, i));
%         end
%         tocBytes(gcp, startS)
%
%     See also ticBytes, gcp.

%   Copyright 2016-2023 The MathWorks, Inc.

if numel(aPool) > 1
    % If a pool is provided, it must be a scalar pool.
    error(message("MATLAB:parallel:pool:ScalarPoolRequired", "tocBytes"));
end
if nargin == 1
    previousState = parallel.Pool.hEmptyPoolPreviousTicBytesResult;
    % Have we been given a previous state? If it is empty then we need to throw
    % an error.
    if isempty(previousState)
        error(message("MATLAB:parallel:pool:TicBytesNotCalled"));
    end
else
    if ~(isa(previousState, "parallel.pool.TicBytesResult") && isscalar(previousState))
        error(message("MATLAB:parallel:pool:TicBytesResultRequired"));
    end
end

% Ask the pool about it's current state
if isempty(aPool)
    currentState = parallel.pool.TicBytesResult.createForEmptyPool();
else
    issueUnsupportedWarning();
    currentState = parallel.pool.TicBytesResult.createForUnsupportedPool();
end

% Compute how many bytes have been transferred between the current
% state and the previous state. Note that the opaque state object
% will throw errors if the pools are different.
if nargout == 0
    dispMinus(currentState, previousState);
else
    out = currentState - previousState;
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function issueUnsupportedWarning()
% Issue a warning that ticBytes/tocBytes is not supported.
parallel.internal.warningNoBackTrace(message("MATLAB:parallel:pool:UnsupportedTicBytesTocBytes"));
end
