function [files, filesizes] = sharedpathLookupLocal(location, includeSubfolders)
%sharedpathLookupLocal    Path lookup for local files

%   Copyright 2019-2024 The MathWorks, Inc.
if nargin < 2
    includeSubfolders = false;
end

if isunix
    wildcardPatterns = ["/**", "**/*", "*/"];
else
    % Windows supports both / and \ fileseps
    wildcardPatterns = [filesep + "**", "**" + filesep + "*", "*" + filesep, ...
        "/**", "**/*", "*/"];
end
iswildcard = ~isempty(location) && any(strfind(location, '*')) && ~any(endsWith(location, wildcardPatterns));
if iswildcard && includeSubfolders
    error(message('MATLAB:datastoreio:pathlookup:wildCardWithIncludeSubfolders', location));
end

RECURSE_STR = '/**/*';
if includeSubfolders
    locOrRecursiveLoc = fullfile(location, RECURSE_STR);
else
    locOrRecursiveLoc = location;
end
dirStruct = dir(locOrRecursiveLoc);
[files, filesizes] = filesExpander(dirStruct);

if iswildcard
	% this is required for the wildcard case because a path ending in "*"
	% will get the files under folders in the current location
    dirStruct2 = dir(fullfile(location,'/*'));
    [filesInSubfolders, filesizesForSubfolders] = filesExpander(dirStruct2);
    files = [files; filesInSubfolders];
    filesizes = [filesizes; filesizesForSubfolders];
end

if isempty(dirStruct) || isempty(files)
    % if empty, try to lookup MATLAB path.
    dirStruct = lookupMATLABPath(dirStruct, locOrRecursiveLoc, location, includeSubfolders);
    isfiles = not([dirStruct.isdir]);
    files = dirStruct(isfiles);
    filesizes = [files.bytes];
end

end

function [files, filesizes] = filesExpander(dirStruct)
    isfiles = not([dirStruct.isdir]);
    files = dirStruct(isfiles);
    filesizes = [files.bytes];
    filesizes = filesizes(:);
end

function dirStruct = lookupMATLABPath(dirStruct, locOrRecursiveLoc, location, ...
    paddedRecurseWildCard)
    if paddedRecurseWildCard
        % We need to use the original input in case we padded the string
        % with recurse wild card: /**/*
        locOrRecursiveLoc = location;
    end
    isexist = exist(locOrRecursiveLoc, 'file');
    switch isexist
        case 7
            if isempty(dirStruct)
                % if the dirStruct itself is empty then there are no directories
                % found. exist outputs 7 when the current directory name is provided
                % as an input.
                noFilesError(locOrRecursiveLoc);
            end
            % Output of dir is not empty (. and ..)
            error(message('MATLAB:datastoreio:pathlookup:emptyFolder',locOrRecursiveLoc));
        case 2
            dirStruct = dir(locOrRecursiveLoc);
            if ~isempty(dirStruct)
                return;
            end
            % try to look it up as a partial path
            files = which('-all',locOrRecursiveLoc);
            % reduce to one file if many
            if numel(files) >= 1
                files = files(1);
                dirStruct = dir(files{1});
                return;
            end
    end
    noFilesError(locOrRecursiveLoc);
end

function noFilesError(pth)
    error(message('MATLAB:datastoreio:pathlookup:fileNotFound',pth));
end
