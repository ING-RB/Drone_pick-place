function updateAttachedFiles(aPool)
%UPDATEATTACHEDFILES Updates changed files that are attached to a parallel pool
%   UPDATEATTACHEDFILES(pool) checks all the attached files of the parallel
%   pool to see if they have changed, and replicates any changes to each of
%   the workers in the pool.
%
%   Example:
%   % update files attached to the pool, myPool.
%   updateAttachedFiles(myPool);
%
%   See also parallel.Pool/addAttachedFiles,
%   parallel.Pool/listAutoAttachedFiles, parallel.Pool/delete

%   Copyright 2013-2020 The MathWorks, Inc.

% For pools where attaching files is not required/supported, we simply
% perform the standard error checking and no-op.
validateattributes(aPool, {'parallel.Pool'}, {'nonempty', 'scalar'}, mfilename, 'pool', 1);
end
