function filename = getFilenameFromParentName(parentName)
% This function is undocumented and may change in a future release.

% Return a relative filename (with no extension) for a parent name that
% possibly contains namespaces.

% Copyright 2015-2023 The MathWorks, Inc.

dotIndex = strfind(parentName, ".");
if isempty(dotIndex)
    filename = parentName;
else
    lastDotIndex = dotIndex(end);
    namespaces = extractBefore(parentName, lastDotIndex);
    namespaces = strrep(namespaces, ".", filesep + "+");
    filename = "+" + namespaces + filesep + extractAfter(parentName, lastDotIndex);
end

gtIndex = strfind(filename, ">");
if ~isempty(gtIndex)
    filename = strtrim(extractBefore(filename, gtIndex(1)));
end

filename = char(filename);
end

