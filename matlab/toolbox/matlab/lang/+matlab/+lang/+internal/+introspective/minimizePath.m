function minimalPath = minimizePath(qualifyingPath, isDir)
    pathParts = regexp(qualifyingPath, '^(?<qualifyingPath>[^@+]*)(?(qualifyingPath)[\\/])(?<pathItem>[^\\/]*)(?<pathTail>.*)', 'names', 'once');
    if isempty(pathParts) || pathParts.pathItem == ""
        minimalPath = qualifyingPath;
        return;
    end
    pathItem = pathParts.pathItem;
    qualifyingPath = pathParts.qualifyingPath;
    pathTail = pathParts.pathTail;
    if isDir
        if pathTail == "" && ~startsWith(pathItem, ["@", "+"])
            firstPath = @splitPath;
        else
            firstPath = @(q,p)whatPath(q,p,pathTail);
        end
    else
        firstPath = @(q,p)which(fullfile(q,p,pathTail));
    end
    expectedPath = string(firstPath(qualifyingPath, pathItem));
    minimalPath = '';
    while expectedPath ~= firstPath(minimalPath, pathItem)
        [qualifyingPath, pop] = fileparts(qualifyingPath);
        if pop == ""
            minimalPath = fullfile(qualifyingPath, minimalPath, pathItem, pathTail);
            return;
        end
        minimalPath = fullfile(pop, minimalPath);
    end
    minimalPath = fullfile(minimalPath, pathItem, pathTail);
end

function path = whatPath(qualifyingPath, pathItem, pathTail)
    dirInfo = matlab.lang.internal.introspective.hashedDirInfo(fullfile(qualifyingPath, pathItem, pathTail), true);
    if isscalar(dirInfo)
        path = dirInfo(1).path;
    else
        path = '';
    end
end

function p = splitPath(qualifyingPath, pathItem)
    allPaths = split(string(path), pathsep);
    candidates = allPaths.endsWith(append(qualifyingPath, filesep, pathItem));
    if nnz(candidates) == 1
        p = allPaths(candidates);
    else
        p = "";
    end
end

%   Copyright 2007-2024 The MathWorks, Inc.