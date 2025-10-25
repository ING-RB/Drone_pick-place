function varargout = tar(tarFilename,files,varargin)

narginchk(2,3);
nargoutchk(0,1);

[tarFilename,files,varargin{1:nargin-2}] = convertStringsToChars(tarFilename,files,varargin{:});

% Parse arguments
[files, rootDir, tarFilename, compressFcn] =  ...
    matlab.io.internal.archive.parseArchiveInputs(mfilename, tarFilename, files, varargin{:});

% Create the archive
try
    entries = matlab.io.internal.archive.getArchiveEntries(files, rootDir, mfilename, true);
    matlab.io.internal.archive.checkDuplicateEntries(entries, mfilename);
    entries = matlab.io.internal.archive.filterOutArchiveFile(entries, tarFilename, mfilename);
    matlab.io.internal.archive.checkEmptyEntries(entries, mfilename);
    if isempty(compressFcn)
        files = matlab.io.internal.archive.core.builtin.createArchive(tarFilename,{entries.file},{entries.entry},mfilename);
    else
        files = matlab.io.internal.archive.core.builtin.createArchive(tarFilename,{entries.file},{entries.entry},'tgz');
    end
catch exception
    throw(exception);
end

if nargout == 1
    varargout{1} = files;
end

% Copyright 2004-2024 The MathWorks, Inc.
