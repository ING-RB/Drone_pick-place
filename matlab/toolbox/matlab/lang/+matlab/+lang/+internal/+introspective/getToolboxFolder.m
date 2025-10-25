function toolboxFolder = getToolboxFolder(path, name)
    if path ~= ""
        toolboxFolder = getToolboxFolderFromPath(path);
    else
        toolboxFolder = getToolboxFolderFromBuiltin(name);
    end
end

function toolboxFolder = getToolboxFolderFromPath(path)
    persistent toolboxFolderPattern;
    if isempty(toolboxFolderPattern)
        escapedRoot = regexptranslate('escape', matlabroot);
        escapedSep  = regexptranslate('escape', filesep);
        escapedSkip = sprintf('%s[^%s]+%s', escapedSep, escapedSep, escapedSep);
        toolboxFolderPattern = append('^', escapedRoot, escapedSkip, '(?<toolbox>\w+)');
    end

    splitPath = regexp(path, toolboxFolderPattern, 'names');

    if isempty(splitPath)
        toolboxFolder = "";
    else
        toolboxFolder = splitPath.toolbox;
    end
end

function toolboxFolder = getToolboxFolderFromBuiltin(name)
    toolboxFolder = matlab.internal.builtins.getBuiltinFunctionToolboxLocation(name);
    if contains(toolboxFolder, filesep)
        toolboxFolder = extractBefore(toolboxFolder, filesep);
    end
end

%   Copyright 2008-2023 The MathWorks, Inc.
