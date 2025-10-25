%ThreadPool class for parallel.ThreadPool objects
% ThreadPool objects can be constructed by using parpool('threads')
%
% ThreadPool methods:
%    parfeval      - Run function on a ThreadPool worker
%    parfevalOnAll - Run function on all ThreadPool workers
%
% For compatibility with other pools, the following methods are also supported.
% The methods do not have any useful effect when you use them with ThreadPool.
%    addAttachedFiles      - Has no effect for ThreadPool
%    listAutoAttachedFiles - Always returns nothing for ThreadPool
%    ticBytes              - Has no effect for ThreadPool
%    tocBytes              - Always reports NaN bytes transferred for ThreadPool
%    updateAttachedFiles   - Has no effect for ThreadPool
%
% ThreadPool properties:
%    NumWorkers  - Number of threads comprising this pool
% 
% See also parpool, parallel.threads.FevalFuture

% Copyright 2018-2019 The Mathworks, Inc.

%{
%properties
    %
    %NumWorkers - Number of threads comprising this pool
    %    (read-only)
    %
    %NumWorkers;
%end
%}
