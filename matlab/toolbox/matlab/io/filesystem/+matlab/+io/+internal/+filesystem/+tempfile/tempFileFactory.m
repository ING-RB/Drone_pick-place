function tempObj = tempFileFactory(path, varargin)
% Get an appropriate TempFile interface for a given file path.
import matlab.io.internal.filesystem.tempfile.*

opts = getOptsFromArgs(varargin);
[path,opts] = resolveInputPath(path,opts);

if TempCompressed.isSupportedExtension(path)
    tempObj = TempCompressed(path,opts);
    return;
end

% do simpler dispatch if not using options, and path can be converted to VFS.
if ~usingWebOptions(path,opts)
    nested = path2nested(path);
    if isfile(nested)
        % If we can find the file using the full nested syntax, then we can
        % copy it directly with TempRemote using no intermediates.
        if isremote(nested)
            tempObj = TempRemote(nested, opts);
        else
            tempObj = LocalFileWrapper(nested, opts);
        end

        return;
    end
end

% Work from the outside in getting contents (zip, tar, etc.)
pos = findLastOccurrence(path, TempContainer.SupportedExtensions);

if isempty(pos)
    % We don't have to deal with contained files.
    if isremote(path)
        if usingWebOptions(path,opts)
            tempObj = TempHTTPWithWebOptions(path, opts);
        else
            tempObj = TempRemote(path,opts);
        end
    else % is localFile
        % If the file isn't otherwise handled, return a TempFile wrapper
        % that doesn't do anything but return the local path.
        tempObj = LocalFileWrapper(path,opts);
    end
else
    [container,contents] = breakPathAtPos(path,pos);
    tempObj = TempContainer(container, contents, opts);
end

end

function tf = usingWebOptions(path,opts)
tf = startsWith(path,"http",IgnoreCase=true) && opts.hasWebOptions();
end

function [container,contents] = breakPathAtPos(path,pos)
% Split the container and contents and create a TempContainer
container = extractBefore(path,pos);
contents = extractAfter(path,pos);
end

function tf = isremote(path)
tf = matlab.io.internal.filesystem.tempfile.TempRemote.isremote(path);
end

function pos = findLastOccurrence(str, values)
% Create a regexp pattern for each value to be checked e.g. "xyz|abc".
pat = join(replace(values,'.','\.') + "/", '|');

[pos, matches] = regexpi(str, pat, 'start', 'match');
if ~isempty(pos)
    pos = pos(end) + strlength(matches{end}) - 1;
end
end

function opts = getOptsFromArgs(args)
import matlab.io.internal.filesystem.tempfile.*
if numel(args)==0
    opts = TempFileOptions();
    return
end

if isstruct(args{1})
    opts = TempFileOptions.fromArgsStruct(args{1});
elseif isa(args{1},"matlab.io.internal.filesystem.tempfile.TempFileOptions")
    opts = args{1};
else
    opts = TempFileOptions(args{:});
end

end

function [path,opts] = resolveInputPath(path,opts)
arguments
    path(1,1) string {mustBeNonzeroLengthText}
    opts(1,1) matlab.io.internal.filesystem.tempfile.TempFileOptions;
end
import matlab.io.internal.filesystem.tempfile.*;

persistent homedir
% We do some work to resolve the path, but for errors, we want to report
% exactly what the user gave us.
if ~opts.hasOriginalName()
    opts.OriginalName = path;
end

if ispc && ~matlab.io.internal.vfs.validators.hasIriPrefix(path)
    path = replace(path,"/","\");
end

if ~matlab.io.internal.filesystem.isAbsolutePathNoIO(path)
    % This is a relative or partial path. We need to find the root filename for containers and do some path resolution on that. Then patch it back into the rest of the container.
    containerExts = [TempContainer.SupportedExtensions];
    pathComponents = split(path,filesep);

    % Find the first instance of .zip, etc. If we don't find anything, then
    % we don't have any hope of resolving the path, just resolve the entire
    % path and hope for the best.
    firstContainerIdx = find(endsWith(pathComponents(:),containerExts),1);
    if ~isempty(firstContainerIdx)
        firstContainer = join(pathComponents(1:firstContainerIdx),filesep);
        resolvedRoot = getResolvedPath(firstContainer);
        path = join([resolvedRoot;pathComponents(firstContainerIdx+1:end)],filesep);
    else
        path = getResolvedPath(path);
    end
else
    if ~ispc && startsWith(path,"~")
        if isempty(homedir)
            homedir = matlab.io.internal.filesystem.resolvePath("~").ResolvedPath;
        end
        path = fullfile(homedir,extractAfter(path,"~"));
    end
end
path = LocalFileWrapper.getURLFromPath(path);
end
%   Copyright 2024 The MathWorks, Inc.

function path = getResolvedPath(path)
resolved = matlab.io.internal.filesystem.resolvePath(path);
if resolved.Type == "None"
    path = fullfile(pwd,path);
else
    path = resolved.ResolvedPath;
end
end
