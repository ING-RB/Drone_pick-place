function [nestedurl,isnested] = path2nested(path)
arguments
    path(1,1) string
end

% Get full path if not already an IRI or
path = matlab.io.internal.filesystem.getFullURL(path);

% If there are no .zip entries, then don't bother.
if ~contains(path,".zip/")
    isnested = false;
    nestedurl = path;
    return
end

% If the full converted path is a file according to VFS, then all the
% interior zip segements were valid zip files and we can just return
% the string. Otherwise, we need to check the interior paths to see if
% they are at least files.
nestedurl = fastReplace(path);
if isfile(nestedurl)
    isnested = true;
    return
end

% Already checked we have at least 1 .zip path segment, so we can just
% break up the string into those parts, then reassemble it.
zipSegments = extractZipSegments(path);

% Checks that each level of nesting actually represents a real file, if
% not, then we don't treat that as a real level of nesting, and assume it's
% a folder. If that folder doesn't exist, something will fall over later.
nestedurl = accurateReplace(zipSegments);

isnested = (nestedurl == path);
end

% Converts the two pieces into a single nested segment
function nestedURL = createNestedURL(inner,outer)
nestedURL = compose("zip:%s!/%s",inner,outer);
end

% Do only string replacements to get the full nested URL
function str = fastReplace(str)
% For each .zip/ folder, prepend a zip: schema.
str = repmat('zip:',1,count(str,".zip/")) ...
      + replace(str,".zip/",".zip!/");
end

% Breaks up the path when there is a ".zip" at the end of the path segment
function segments = extractZipSegments(path)
path_components = split(path,"/");
zips = path_components.endsWith(".zip","IgnoreCase",true)';

archive_paths = [unique([0, find(zips)]), numel(path_components)];
segments = strings(numel(archive_paths)-1,1);
for ii = 1:numel(segments)
    range = unique(archive_paths(ii:ii+1));
    segments(ii) = join(path_components(range(1)+1:range(2)),"/");
end
end

% Check each interim path component for existince before turning into a
% nested component. If a .zip path segement isn't a file, it might be a
% folder, or it might not exist, but in either case, we don't want to treat
% that as a real .zip file. Mostly, this is done so the errors down the
% line make more sense.
function nestedurl = accurateReplace(zipSegments)
nestedurl = zipSegments(1);
for ii = 2:numel(zipSegments)
    % If the nested file exists and is a file, we assume it's a valid zip
    % file. Otherwise, this will error down the line, but that's okay.
    if isfile(nestedurl)
        nestedurl = createNestedURL(nestedurl,zipSegments(ii));
    else
        % In the rare case that someone named a folder something.zip
        % Or it doesn't exist at all, and that's okay.
        nestedurl = fullfile(nestedurl,zipSegments(ii));
    end
end
end

%   Copyright 2024 The MathWorks, Inc.
