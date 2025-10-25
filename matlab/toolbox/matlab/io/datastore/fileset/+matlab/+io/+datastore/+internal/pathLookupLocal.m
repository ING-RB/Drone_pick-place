function [files, filesizes] = pathLookupLocal(dirOrFile, includeSubfolders)
%PATHLOOKUPLOCAL Get file names and sizes resolved for a local input path.
%   FILES = pathLookup(PATH) returns the fully resolved file names for the
%   local or network path specified in PATH. This happens non-recursively
%   by default i.e. we do not look under subfolders while resolving. PATH
%   can be a single string denoting a path to a file or a folder. The path
%   can include wildcards.
%
%   FILES = pathLookup(PATH, INCLUDESUBFOLDERS) returns the fully resolved
%   file names for the local or network path specified in PATH taking
%   INCLUDESUBFOLDERS into account.
%   1) If a path refers to a single file, that file is added to the output.
%   2) If a path refers to a folder
%          i) all files in the specified folder are added to the output.
%         ii) if INCLUDESUBFOLDERS is false, subfolders are ignored.
%        iii) if INCLUDESUBFOLDERS is true, all files in all subfolders are
%             added.
%   3) If path refers to a wild card:
%          i) all files matching the pattern are added.
%         ii) if INCLUDESUBFOLDERS is false, folders that match the pattern
%              are looked up just for files.
%        iii) if INCLUDESUBFOLDERS is true, an error is thrown.
%
%   [FILES,FILESIZES] = pathLookupLocal(...) also returns the file sizes
%   for the resolved paths as an array of double values.
%
%   See also matlab.io.datastore.internal.pathLookup

%   Copyright 2015-2019, The MathWorks, Inc.

persistent fileseparator;
if isempty(fileseparator)
    fileseparator = filesep;
end
if ischar(dirOrFile)
    [files, filesizes] = matlab.io.datastore.internal.sharedpathLookupLocal(...
        dirOrFile, includeSubfolders);
    listing = {files.name}';
    pathStr = {files.folder}';
    files = cell(size(pathStr,1),1);
    for ii = 1 : size(pathStr,1)
    	files{ii} = [pathStr{ii}, fileseparator, listing{ii}];
    end
    filesizes = filesizes(:);
else
    error(message('MATLAB:virtualfileio:path:invalidFilesInput'));
end
end
