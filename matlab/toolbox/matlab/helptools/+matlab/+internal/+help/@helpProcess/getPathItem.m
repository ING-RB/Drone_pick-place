function [qualifyingPath, pathItem] = getPathItem(hp)
    [qualifyingPath, pathItem, ext] = fileparts(hp.fullTopic);
    if ~hp.isDir
        hp.isContents = strcmp(pathItem, 'Contents') && strcmp(ext,'.m') && ~matlab.lang.internal.introspective.containers.isClassDirectory(qualifyingPath);
        if hp.isContents
            hp.isDir = true;
            pathItem = matlab.lang.internal.introspective.minimizePath(qualifyingPath, true);
        elseif ext == ".mat"
            pathItem = append(pathItem, ext);
        end
    end
end

%   Copyright 2007-2023 The MathWorks, Inc.
