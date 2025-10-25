function absolutePath = absolutePathForReading(filename, notFoundErrorID, permissionDeniedErrorID )
% Given a fileName, relative file path, or full file path, return
% the Full path (i.e. fullpath/fileName.ext) to the given file.
% the MATLAB path is searched first, using which

% Author: Nick Haddad
% Copyright 2016 The MathWorks, Inc.

% First check the MATLAB path for the file.
whichFileName = which(filename);
if ~strcmp(whichFileName, '')
    filename = whichFileName;
end

% File not on the matlab path, expand normally
filepath = multimedia.internal.io.FilePath(filename);

if (~filepath.Exists)
    throwAsCaller(MException(message(notFoundErrorID)));
end

if (~filepath.Readable)
    throwAsCaller(MException(message(permissionDeniedErrorID)));
end

% return the absolute file path
absolutePath = filepath.Absolute;

end

