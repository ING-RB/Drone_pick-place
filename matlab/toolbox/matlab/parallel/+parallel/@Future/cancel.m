%CANCEL Cancel a pending, queued, or running Future
%    CANCEL(F) stops the Futures F, that are currently in
%    state 'pending', 'queued', or 'running'. No action is taken
%    for Futures that are already in state 'finished'. Each
%    element of F that was not already in state 'finished' has
%    its state set to 'finished', and the Error property is set
%    to contain an MException indicating that execution was
%    cancelled.
%
%    Examples:
%    Run several functions until a satisfactory result is found
%    N = 100;
%    for idx = N:-1:1
%        F(idx) = parfeval(@rand, 1); % create a random scalar
%    end
%    result = NaN; % not found result yet.
%    for idx = 1:N
%        [~, thisResult] = fetchNext(F);
%        if thisResult > 0.99
%           result = thisResult;
%           % We have all the results we need, so break
%           break;
%        end
%    end
%    % We have the result we need, so cancel any still-running
%    % futures
%    cancel(F);
%
%    See also parfeval, parfevalOnAll,
%             parallel.FevalFuture.fetchNext,
%             parallel.FevalFuture.fetchOutputs.

% Copyright 2013-2021 The MathWorks, Inc.
