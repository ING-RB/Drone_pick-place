function fs = makeFileSet(location, varargin)
%buildFileSet   builds a matlab.io.datastore.FileSet out of the
%   types we support across most datastores:
%
%     - filenames
%     - folder names
%     - mixed file names and folder names in an array
%     - paths with wildcards
%     - Remote URLs
%     - matlab.io.datastore.FileSet
%     - matlab.io.datastore.DsFileSet
%     - matlab.io.datastore.BlockedFileSet
%
%   N-V pairs like IncludeSubFolders, FileExtensions, and AlternateFileSystemRoots
%   can be supplied. These parameters will be ignored if the input is a
%   fileset-like class.

%   Copyright 2022 The MathWorks, Inc.

    import matlab.io.datastore.internal.fileset.ResolvedFileSetFactory;

    if isa(location, "matlab.io.datastore.DsFileSet")
        % Verify that any input DsFileSet is scalar. 
        matlab.io.datastore.internal.throwFileSetMustBeScalarError(location);
        files =  matlab.io.datastore.internal.getFileNamesFromFileSet(location);
        fs = matlab.io.datastore.FileSet(files);
    elseif isa(location, "matlab.io.datastore.FileSet")
        fs = location.copy();
        fs.reset();
    elseif isa(location, "matlab.io.datastore.BlockedFileSet")
        files = location.getFiles;
        fs = matlab.io.datastore.FileSet(files);
    else
        [varargin{:}] = convertStringsToChars(varargin{:});
        options = parseNameValues(varargin{:});
        [fs, ~, ~, ~] = ResolvedFileSetFactory.buildCompressed(location, options);
    end
end

function parsedStruct = parseNameValues(varargin)

    persistent inpP;
    if isempty(inpP)
        inpP = inputParser;
        addParameter(inpP, "IncludeSubfolders", false);
        addParameter(inpP, "FileExtensions", -1);
        addParameter(inpP, "AlternateFileSystemRoots", {});
    end
    parse(inpP, varargin{:});
    parsedStruct = inpP.Results;
    parsedStruct.UsingDefaults = inpP.UsingDefaults;
    if ~isa(parsedStruct.IncludeSubfolders,"logical") && ...
            ~isnumeric(parsedStruct.IncludeSubfolders)
        error(message("MATLAB:datastoreio:pathlookup:invalidIncludeSubfolders"));
    end
end