function files = getFilesForFoldersRecalculation(ds)
%getFilesForFoldersRecalculation lists the files that should be
%   used for calculating the folders property.
%
%   The returned list of files must be a fully-qualified
%   resolved list of valid filenames on disk or on an accessible
%   remote location.

%   Copyright 2019-2023 The MathWorks, Inc.

    hasGetFilesMethod = ismethod(ds, "getFiles");
    hasFilesProperty = isprop(ds, "Files");
    isFileSet = isa(ds, "matlab.io.datastore.internal.fileset.ResolvedFileSet");

    if isFileSet
        % Special case for the built-in ResolvedFileSet objects.
        resolvedFileList = ds.resolve();
        files = resolvedFileList.FileName;
    elseif hasGetFilesMethod
        % For convenience, use the getFiles method on the datastore if
        % it is defined.
        files = ds.getFiles();
    elseif hasFilesProperty
        % Fall back to using the Files property, if it is defined.
        files = ds.Files;
    else
        % Provide an error message suggesting that the getFiles method or
        % the Files property should be defined.
        error(message("MATLAB:io:datastore:write:write:UndefinedGetFilesMethod"));
    end

    % Normalize to a column cell vector of character arrays.
    files = matlab.io.datastore.internal.normalizeToCellstrColumnVector(files);

    % Error if the datatype is not supported for conversion to text.
    if ~iscellstr(files)
        error(message("MATLAB:io:datastore:write:write:InvalidFilesDatatype"));
    end
end
