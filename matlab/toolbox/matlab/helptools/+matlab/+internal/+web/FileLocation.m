classdef FileLocation 

    properties (SetAccess = immutable)
        Uri matlab.net.URI;
        FilePath string;
        FileExists (1,1) logical;
        RelativePathToMissingFile (1,1) logical
    end

    methods
        function obj = FileLocation(location)
            relativePath = false;
            if ~nargin
                obj.Uri = matlab.net.URI.empty;
            elseif ~isa(location, "matlab.net.URI")
                [obj.Uri, obj.FilePath] = getUriForPath(location);
                if ~isempty(obj.Uri) && isempty(obj.FilePath)
                    simpleUri = makeSimpleUri(location);
                    relativePath = ~simpleUri.Absolute;
                end
            elseif location.Absolute
                obj.Uri = location;
            else
                relpath = join(location.Path, filesep);
                [obj.Uri, obj.FilePath] = getUriForPath(relpath);
                obj.Uri.Query = location.Query;
                obj.Uri.Fragment = location.Fragment;
                relativePath = true;
            end

            if isempty(obj.FilePath)
                obj.FilePath = getFilePathFromUri(obj);
            end
            obj.FileExists = ~isempty(obj.FilePath) && (isfile(obj.FilePath) || isfolder(obj.FilePath));
            obj.RelativePathToMissingFile = ~obj.FileExists && relativePath;
        end

        function relativeUri = getRelativeUriFrom(obj, folder)
            relativeUri = matlab.net.URI.empty;
            if isempty(obj.Uri)
                return;
            end
            if ~isa(folder, "matlab.internal.web.FileLocation")
                folder = matlab.internal.web.FileLocation(folder);
            end

            % The folder and obj variables both contain FileLocation instances. 
            % Compare their FilePaths, since FilePath will be canonicalized, 
            % whereas Uri may not be.
            if startsWith(obj.FilePath, folder.FilePath)
                relPath = extractAfter(obj.FilePath, folder.FilePath);
                relParts = split(relPath, filesep);
                relParts(relParts == "") = [];
                relativeUri = matlab.net.URI;
                relativeUri.Path = reshape(relParts, 1, numel(relParts));
                relativeUri.Query = obj.Uri.Query;
                relativeUri.Fragment = obj.Uri.Fragment;
            end
        end
    end

    methods (Access = private)
        function path = getFilePathFromUri(obj)
            if isempty(obj.Uri)
                path = string.empty;
                return;
            end

            pathParts = obj.Uri.Path;
            if ispc
                pathParts = correctWindowsPath(pathParts);
            end
            
            path = join(pathParts, filesep);
            if ~isfile(path) && ~isfolder(path)
                % Perhaps the path is encoded.
                decoded = matlab.net.internal.urldecode(path);
                if isfile(decoded) || isfolder(decoded)
                    path = decoded;
                end
            end

            path = canonicalizeFilePath(path);
        end
    end
end

function [uri, existingFile] = getUriForPath(pathstring)
    % Returns the URI to use for the file. If the file exists, the
    % existingFile output argument will contain the path to the file.

    arguments
        pathstring (1,1) string = string.empty
    end
    
    uris = createCandidateUris(pathstring);
    if isempty(uris)
        uri = matlab.net.URI.empty;
        existingFile = string.empty;
        return;
    end

    % Always reconstruct the path from the URI. This ensures that
    % query parameters and fragments are handled correctly.
    [uri, existingFile] = getBestUri(uris);
    if ~isempty(uri)
        return;
    else
        uri = uris(1);
        existingFile = string.empty;
    end

    if ~uri.Absolute
        fromPwd = fullfile(pwd, uri.Path{:});
        uri = makeUriForFilePath(fromPwd, [], uri.Query, uri.Fragment);
        if isfile(fromPwd) || isfolder(fromPwd)
            existingFile = fromPwd;
        end
    end
end

function [found, relative] = findExistingFile(filepath, checkRelative)
    arguments
        filepath (1,1) string
        checkRelative (1,1) logical = true;
    end

    [found, relative] = checkFileSystem(filepath);
    if isempty(found) && checkRelative
        % Look for the file using which
        fromWhich = which(filepath);
        if ~isempty(fromWhich)
            found = string(fromWhich);
            relative = string.empty;
        end
    end

    % On Windows, a path that contains a single leading slash might
    % be hard for us to deal with. For paths with drive letters, we
    % might have something like /C:/folder/file.html. For UNC paths
    % we might be missing one of the two leading slashes.
    if isempty(found) && ispc
        leadingSlashes = extract(filepath, textBoundary("start") + asManyOfPattern("/"|"\"));
        if strlength(leadingSlashes) == 1
            % Add an extra leading slash to try a UNC path
            uncPath = leadingSlashes + filepath;
            [found, relative] = findExistingFile(uncPath, false);
        end
    end

    if ~isempty(found)
        % For files or folders that exist, we can make a canonical path.
        found = canonicalizeFilePath(found);
    end
end

function [uri, existingFile] = getBestUri(uris)
    uri = matlab.net.URI.empty;
    existingFile = string.empty;
    for curUri = uris
        filepath = join(curUri.Path, filesep);
        [found, relative] = findExistingFile(filepath, ~curUri.Absolute);
        if ~isempty(found)
            if isempty(relative)
                existingFile = found;
            end
            uri = makeUriForFilePath(found, relative, curUri.Query, curUri.Fragment);
            return;
        end
    end
end

function uris = createCandidateUris(pathstring)
    uris = matlab.net.URI.empty;

    pathstring = replace(pathstring, "\", "/");
    if startsWith(pathstring, "file:")
        if ispc
            filePattern = textBoundary("start") + "file:" + asManyOfPattern("/");
            pathstring = replace(pathstring, filePattern, "file:///");
        end
        uri = matlab.net.URI(pathstring);
    else
        % Make a first attempt at finding the file using the path
        % exactly as it was given to us.
        [found, relative] = findExistingFile(pathstring);
        if ~isempty(found)
            uris = makeUriForFilePath(found, relative);
            return;
        end
        
        uri = makeSimpleUri(pathstring);
        if isempty(uri)
            return;
        end
    end

    % The matlab.net.URI constructor assumes that strings are NOT
    % encoded, so we will often end up with a doubly-encoded string
    % here. The following line will decode the URI once, leaving
    % it in a valid encoded state. That is, if the URI is
    % doubly-encoded it will decode it once, but if it is only
    % singly-encoded it will leave it that way.
    decodedUri = matlab.net.URI(uri);
    decodedUri.EncodedPath = join(decodedUri.Path, "/");

    if decodedUri.EncodedPath == uri.EncodedPath
        uris = uri;
    else
        uris = [decodedUri, uri];
    end
end

function pathParts = correctWindowsPath(pathParts)
    if length(pathParts) >= 2 && pathParts(1) == "" && ...
        startsWith(pathParts(2), lettersPattern(1,1) + ":")
        pathParts(1) = [];
    end
end

function uri = makeSimpleUri(pathstring)
    if startsWith(pathstring, "/"|"\")
        uri = matlab.net.URI("file://" + pathstring);
    elseif ispc && startsWith(pathstring, lettersPattern(1,1) + ":")
        uri = matlab.net.URI("file:/" + pathstring);
    else
        try
            uri = matlab.net.URI(pathstring);
            if uri.Absolute && uri.Scheme ~= "file"
                % This isn't a URI for a file.
                uri = matlab.net.URI.empty;
                return;
            end
        catch
            uri = matlab.net.URI.empty;
        end
    end
end

function uri = makeUriForFilePath(found, relative, query, fragment)
    arguments
        found (1,1) string
        relative {mustBeScalarOrEmpty}
        query matlab.net.QueryParameter = matlab.net.QueryParameter.empty;
        fragment string = string.empty;
    end

    % Create a new absolute URI using the full path.
    uri = matlab.net.URI;
    uri.Scheme = "file";
    uri.Path = replace(found, "\", "/");
    uri.Query = query;
    uri.Fragment = fragment;

    % Use the matlab.net.URI constructor for the
    % relative portion of the path, to ensure that
    % query strings and fragments are handled correctly.
    if ~isempty(relative)
        relativeUri = matlab.net.URI(relative);
        uri = appendToPath(uri, relativeUri.Path);
        uri.Query = [uri.Query relativeUri.Query];
        if ~isempty(relativeUri.Fragment)
            uri.Fragment = relativeUri.Fragment;
        end
    end
end

function [found, relative] = checkFileSystem(fullpath)
    arguments
        fullpath (1,1) string
    end

    if ispc
        slashesPattern = asManyOfPattern("/"|"\");
        drivePattern = lettersPattern(1) + ":";
        if startsWith(fullpath, slashesPattern + drivePattern)
            fullpath = extractAfter(fullpath, slashesPattern);
        end
    end

    found = string.empty;
    relative = string.empty;

    % Walk up the file path to find a file or folder that exists.
    while ~(isfile(fullpath) || isfolder(fullpath))
        [folder, name, ext] = fileparts(fullpath);
        if name ~= "" && folder ~= fullpath && folder ~= filesep
            relative = join([name+ext relative], filesep);
            fullpath = folder;
        else
            % We're at the top of the file path and haven't found
            % the file.
            relative = join([folder relative], filesep);
            return;
        end
    end

    % If we get here, fullpath is a file or folder that exists.
    found = fullpath;
end

function filePath = canonicalizeFilePath(filePath)
    arguments
        filePath (1,1) string
    end

    curPath = filePath;
    while ~isfile(curPath) && ~isfolder(curPath)
        parent = fileparts(curPath);
        if parent == curPath || parent == ""
            % We never found an existing file.
            % Leave filePath as-is
            return;
        end
        curPath = parent;
    end

    % Use fileattrib to retrieve the canonical path to the existing file.
    [stat, attr] = fileattrib(curPath);
    if stat && ~isempty(attr) && isstruct(attr) && isfield(attr, "Name")
        filePath = fullfile(attr.Name, extractAfter(filePath, curPath));
    end
end

function uri = appendToPath(uri, path)
    uri.Path = reshape(uri.Path, 1, numel(uri.Path));
    uri.Path = [uri.Path reshape(path, 1, numel(path))];
end