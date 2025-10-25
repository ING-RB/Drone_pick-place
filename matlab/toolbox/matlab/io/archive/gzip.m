function varargout = gzip(files, varargin)

narginchk(1,2);
nargoutchk(0,1);

[files,varargin{1:nargin-1}] = convertStringsToChars(files,varargin{:});

% rootDir is always ''
dirs = [{''},varargin];

% Check input arguments.

[files, rootDir, outputDir,dirCreated] = matlab.io.internal.archive.checkFilesDirInputs(mfilename, files, dirs{:});
try
    % Get entries
    entries = matlab.io.internal.archive.getArchiveEntries(files, rootDir, mfilename);
    matlab.io.internal.archive.checkEmptyEntries(entries, mfilename);
    names = matlab.io.internal.archive.core.builtin.compressgz({entries.file},outputDir);

    % Return the names if requested
    if nargout == 1
        varargout{1} = names;
    end
catch exception
    if ~isempty(dirCreated)
        rmdir(dirCreated, 's');
    end
    rethrow(exception);
end

% Copyright 2004-2023 The MathWorks, Inc.
