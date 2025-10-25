function [fileName, foundTarget, fileType] = extractFile(dirInfo, targetName, isCaseSensitive, ext)
    fileTypes = fieldnames(dirInfo);
    if nargin < 4 || ext == ""
        fileTypes = setdiff(fileTypes, {'path', 'm', 'classes', 'packages'}, 'stable');
        fileTypes{fileTypes=="mat"} = 'm';
    else
        fileTypes = fileTypes(strcmpi(fileTypes, extractAfter(ext, 1)));
        fileName = '';
        foundTarget = false;
        fileType = '';
    end
    for i = 1:numel(fileTypes)
        [fileName, foundTarget, fileType] = extractField(dirInfo, fileTypes{i}, targetName, isCaseSensitive);
        if foundTarget
            return;
        end
    end
end

function [fileName, foundTarget, fileType] = extractField(dirInfo, field, targetName, isCaseSensitive)
    fileIndex = matlab.lang.internal.introspective.casedStrCmp(isCaseSensitive, dirInfo.(field), append(targetName, '.', field));
    foundTarget = any(fileIndex);
    if foundTarget
        [~, fileName, fileType] = fileparts(dirInfo.(field){fileIndex});
    else
        fileName = '';
        fileType = '';
    end
end

%   Copyright 2008-2024 The MathWorks, Inc.
