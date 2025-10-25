function helpStr = getDefaultHelp(dirInfo, header, wantHyperlinks, helpCommand)
    dirInfo = removeIfShadowedByM(dirInfo, 'p', 'p');
    dirInfo = removeIfShadowedByM(dirInfo, 'mex', mexext);
    dirPath = dirInfo.path;
    dirInfo = rmfield(dirInfo, 'path');
    classes = dirInfo.classes;
    dirInfo.classes = append('@', classes);
    dirInfo.packages = append('+', dirInfo.packages);
    dirInfo = structfun(@(x)append(dirPath, filesep, x), dirInfo, 'UniformOutput', false);
    constructors = append(dirInfo.classes, filesep, classes, '.m');
    hasConstructors = isfile(constructors);
    dirInfo.classes(hasConstructors) = constructors(hasConstructors);
    allFields = struct2cell(dirInfo);
    allFields = vertcat(allFields{:});
    hp2 = matlab.internal.help.helpProcess(1,0);
    if wantHyperlinks
        hp2.specifyCommand(helpCommand);
    end
    hp2.getHelpForTopics(allFields, true);
    helpStr = hp2.helpStr;
    if helpStr ~= ""
        helpStr = append(header, newline, newline, helpStr);
    end
end

function dirInfo = removeIfShadowedByM(dirInfo, field, ext)
    files = replace(dirInfo.(field), append('.', ext), '.m');
    [~, i] = setdiff(files, dirInfo.m);
    dirInfo.(field) = dirInfo.(field)(i);
end

% Copyright 2022-2024 The MathWorks, Inc.
