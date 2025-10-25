function [overqualifiedPath, actualName] = splitOverqualification(correctName, inputName, whichName)
    inputParts = splitPath(inputName);
    correctParts = splitPath(correctName);
    splitCount = numel(correctParts);
    overqualifiedPath = joinPath(whichName, inputParts(1:end-splitCount));
    if overqualifiedPath ~= "" && ~endsWith(overqualifiedPath(end), '/')
        overqualifiedPath = append(overqualifiedPath, '/');
    end
    if nargout > 1
        actualName = joinPath(correctName, inputParts(end-splitCount+1:end));
    end
end

function parts = splitPath(name)
    parts = regexp(name, '([\\/.]|^)[@+]?', 'split');
    parts(parts=="") = [];
end

function path = joinPath(fullPath, pathParts)
    path = sprintf('%s/', pathParts{:});
    path = matlab.lang.internal.introspective.extractCaseCorrectedName(fullPath, path);
end

%   Copyright 2007-2024 The MathWorks, Inc.
