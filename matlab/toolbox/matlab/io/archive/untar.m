function varargout = untar(tarFilename, varargin)

narginchk(1,2);
nargoutchk(0,1);

[tarFilename,varargin{1:nargin-1}] = convertStringsToChars(tarFilename,varargin{:});

% Argument parsing.
[tarFilename, outputDir, url, urlFilename, uncompressFcn] = ...
    matlab.io.internal.archive.parseUnArchiveInputs(mfilename, tarFilename, ...
    {'tgz', 'tar.gz', 'tar'},  ...
    'TARFILENAME', varargin{:});

% Extract TAR contents.
try

    if isscalar(tarFilename) && iscell(tarFilename)
        tarFilename = char(tarFilename);
    end
    files = matlab.io.internal.archive.core.builtin.extractArchive(tarFilename, outputDir, 'tgz');
catch ME
    cleanupTemporaryFile;
    rethrow(ME);
end

cleanupTemporaryFile;
if nargout == 1
    files = matlab.io.internal.archive.cleanupWindowsPathname(files);
    varargout{1} = files;
end

%--------------------------------------------------------------------------
    function cleanupTemporaryFile
        if url && ~isempty(urlFilename) && exist(urlFilename,'file')
            delete(urlFilename);
        end
    end
end

%   Copyright 2004-2023 The MathWorks, Inc.

