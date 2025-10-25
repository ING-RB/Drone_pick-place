function entries = cleanupWindowsPathname(entries)
% Replaces invalid characters in Windows filenames with underscores. If not
% on windows, the input cellstr entries is returned unchanged.
if ~ispc
   return;
end
driveRootPattern = regexpPattern("(^[a-zA-Z]*:\/)|(^[a-zA-Z]*:\\)");
invalidCharsPattern = characterListPattern(":*?""<>|");

afterDriveRoot = extractAfter(entries, driveRootPattern);
hasDriveRootIdx = ~ismissing(afterDriveRoot);
noDriveRootIdx = ~hasDriveRootIdx;
if any(hasDriveRootIdx)
    % don't replace the colon in the drive root with an underscore, i.e.
    % only the second colon in path "C:\path\to:file.txt" should be
    % replaced: "C:\path\to_file.txt"
    cleanedPathnames = replace(afterDriveRoot(hasDriveRootIdx), invalidCharsPattern, "_");
    driveRoot = extract(entries(hasDriveRootIdx), driveRootPattern);
    entries(hasDriveRootIdx) = strcat(driveRoot, cleanedPathnames);
end

if any(noDriveRootIdx)
    % these paths don't start with a drive root, i.e. //path/to:file or
    % relative\file:path.
    entries(noDriveRootIdx) = replace(entries(noDriveRootIdx), invalidCharsPattern, "_");
end
end
