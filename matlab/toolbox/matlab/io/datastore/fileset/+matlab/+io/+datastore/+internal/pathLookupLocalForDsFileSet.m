function [files, filesizes] = pathLookupLocalForDsFileSet(dirOrFile, includeSubfolders)
%PATHLOOKUPLOCALFORDSFILESET Get file names and sizes resolved for a local input path for DsFileSet.
%   FILES = pathLookupLocalForDsFileSet(PATH) returns the fully resolved file names for the
%   local or network path specified in PATH. This happens non-recursively
%   by default i.e. we do not look under subfolders while resolving. PATH
%   can be a single string denoting a path to a file or a folder. The path
%   can include wildcards. This provides files in a compresssed form separated
%   by folders and a list of files each corresponding to each of the folder.
%
%   FILES = pathLookupLocalForDsFileSet(PATH, INCLUDESUBFOLDERS) returns the fully resolved
%   file names for the local or network path specified in PATH taking
%   INCLUDESUBFOLDERS into account.
%   This provides files in a compresssed form separated by folders and a list
%   of files each corresponding to each of the folder.
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
%   [FILES,FILESIZES] = pathLookupLocalForDsFileSet(...) also returns the file sizes
%   for the resolved paths as an array of double values.
%
%   See also matlab.io.datastore.internal.pathLookup

%   Copyright 2017-2019, The MathWorks, Inc.

persistent fileseparator;
if isempty(fileseparator)
    fileseparator = filesep;
end
if nargin == 1
    includeSubfolders = false;
end

[files, filesizes] = matlab.io.datastore.internal.sharedpathLookupLocal(...
    dirOrFile, includeSubfolders);
listing = {files.name};
pathStr = {files.folder};
listing = listing(:);
pathStr = pathStr(:);
if numel(filesizes) == 1
    files = [pathStr, {listing}];
    return;
end

% We need to group folders and the respective file names into cell array.
[folders, ~, groupIndices] = unique(pathStr, 'stable');
if numel(folders) == 1
    listing = {listing};
else
    listing = splitapply(@(x){vertcat(x)}, listing, groupIndices);
end
% A 2D cell containing the foldernames and file names.
% For a folder with 10 files, first element is the full folder name
% and the corresponding 2-Dim element is the list of 10 file names.
files = [folders, listing];
end
