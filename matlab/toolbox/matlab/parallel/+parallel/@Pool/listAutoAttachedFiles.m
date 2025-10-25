function listAutoAttachedFiles(aPool)
%LISTAUTOATTACHEDFILES List files that are automatically attached to the parallel pool
%   listAutoAttachedFiles(pool) lists the files that have
%   already been attached to the parallel pool following a dependency
%   analysis. The dependency analysis will run if a PARFOR or SPMD block
%   errors due to an undefined function. At that point any files, functions
%   or scripts needed by the PARFOR or SPMD block will be attempted to be
%   attached
%
%   Example:
%   % list files automatically attached to pool, myPool.
%   listAutoAttachedFiles(myPool);
%
%   See also parallel.Pool/updateAttachedFiles,
%   parallel.Pool/addAttachedFiles, parallel.Pool/delete

%   Copyright 2013-2020 The MathWorks, Inc.

% For pools where attaching files is not required/supported, we simply
% perform the standard error checking and no-op.
validateattributes(aPool, {'parallel.Pool'}, {'nonempty', 'scalar'}, mfilename, 'pool', 1);
m = message('MATLAB:parallel:pool:NoAutoAttachedFiles');
disp(m.getString());
end
