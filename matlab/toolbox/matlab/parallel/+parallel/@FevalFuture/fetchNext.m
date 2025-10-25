%fetchNext Fetch next available unread FevalFuture outputs
%   [idx,B1,B2,...,Bn] = fetchNext(F) waits for an unread
%   FevalFuture in the array of futures F to become 'finished',
%   and then returns the index of that future in F as IDX, as well
%   as returning the future's results in B1,B2,...,Bn. Before
%   this call, the property F(idx).Read is FALSE; after this
%   call, it will be TRUE.
%
%   [idx,B1,B2,...,Bn] = fetchNext(F, TIMEOUT) waits for
%   at most TIMEOUT seconds for a result to become available. If
%   the timeout expires before any result becomes available, then
%   all output arguments will be empty.
%
%   If there are no futures in F for which the property 'Read' is
%   FALSE, then an error is reported. You can check whether there
%   are any unread futures using "anyUnread = ~all([F.Read])".
%
%   If the element of F(idx) which has become finished encountered
%   an error during execution, that error will be thrown by
%   fetchNext. However, F(idx).Read will still become TRUE so that
%   any subsequent call to fetchNext can proceed.
%
%   Examples:
%   Request several function evaluations, and update
%   a progress bar while waiting for completion
%
%   N = 100;
%   for idx = N:-1:1
%       % Compute the rank of N magic squares
%       F(idx) = parfeval(@rank, 1, magic(idx));
%   end
%   % Build a waitbar to track progress
%   h = waitbar(0, 'Waiting for FevalFutures to complete...');
%   results = zeros(1, N);
%   for idx = 1:N
%       [completedIdx, thisResult] = fetchNext(F);
%       % store the result
%       results(completedIdx) = thisResult;
%       % update waitbar
%       waitbar(idx/N, h, sprintf('Latest result: %d', thisResult));
%   end
%   % Clean up
%   delete(h)
%
%   See also parfeval,
%            parallel.FevalFuture.fetchOutputs.

% Copyright 2013-2021 The MathWorks, Inc.
