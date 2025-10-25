function addAttachedFiles(aPool,files)
%ADDATTACHEDFILES Attach files to a parallel pool
%   ADDATTACHEDFILES(pool, myFiles) Attaches the files listed in myFiles
%   to the parallel pool. myFiles is a character vector, string, string array,
%   or a cell array of character vectors of file names. Each entry can specify
%   either absolute or relative files, folders, or a file on the MATLAB path.
%   These files are transferred to each worker and are treated exactly the
%   same as if they had been set at the time the pool was opened. Files
%   added first will come higher in the path.
%
%   Examples:
%   % attach the file 'myFunction1.m' to a pool, myPool.
%   addAttachedFiles(myPool, 'myFunction1.m');
%
%   % attach a cell array of files to a pool, myPool.
%   myFiles = {'myFunction1.m', 'myFunction2.m'};
%   addAttachedFiles(myPool, myFiles);
%
%   See also parallel.Pool/updateAttachedFiles,
%   parallel.Pool/listAutoAttachedFiles, parallel.Pool/delete

%   Copyright 2013-2022 The MathWorks, Inc.

% For pools where attaching files is not required/supported, we simply
% perform the standard error checking and no-op.
files = convertStringsToChars(files);
validateattributes(aPool, {'parallel.Pool'}, {'nonempty', 'scalar'}, mfilename, 'pool', 1);
validateattributes(files, {'cell','char'}, {}, mfilename, 'files', 2);
if ischar(files)
    files = {files};
end
if ~iscellstr(files) %#ok<ISCLSTR>
    error(message('MATLAB:parallel:pool:InvalidAttachFilesArgument'));
end
end
