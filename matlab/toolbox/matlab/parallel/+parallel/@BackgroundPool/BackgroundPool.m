%BackgroundPool class for the BackgroundPool object
% Use backgroundPool() to get the BackgroundPool object for the current
% MATLAB session.
%
% BackgroundPool methods:
%    parfeval      - Run function on a BackgroundPool worker
%    parfevalOnAll - Run function on all BackgroundPool workers
%
% For compatibility with other pools, the following methods are also supported.
% The methods do not have any useful effect when you use them with BackgroundPool.
%    addAttachedFiles      - Has no effect for BackgroundPool
%    listAutoAttachedFiles - Always returns nothing for BackgroundPool
%    ticBytes              - Has no effect for BackgroundPool
%    tocBytes              - Always reports NaN bytes transferred for BackgroundPool
%    updateAttachedFiles   - Has no effect for BackgroundPool
% 
% BackgroundPool properties:
%    NumWorkers  - Number of workers in the background pool
%
% See also backgroundPool, parfeval, parfevalOnAll

% Copyright 2021 The Mathworks, Inc.

%{
%properties
    %
    %NumWorkers - Number of workers in the background pool, returned as a finite positive integer scalar.
    %    (read-only)
    %
    %NumWorkers;
%end
%}
