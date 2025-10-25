function resolvedFolder = resolveFolderPossiblyOnPath(folder)
%

% Copyright 2022 The MathWorks, Inc.

[status, info] = fileattrib(folder);
if status
    % folder relative to PWD or absolute path
    resolvedFolder = info.Name;
else
    % folder on the path
    folderInfo = what(folder);
    resolvedFolder = folderInfo(1).path;
end
end

