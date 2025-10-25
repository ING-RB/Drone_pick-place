function preferReference = preferSingleSource(fullPath)
    arguments
        fullPath (1,1) string
    end
    preferReference = matlab.internal.help.useSingleSource;
    if ~matlab.io.internal.common.isAbsolutePath(fullPath)
        return;
    end
    if isfile(fullPath)
        [fullPath, fileName, ext] = fileparts(fullPath);
        fileName = append(fileName, replace(ext, ".", "_"));
    elseif isfolder(fullPath)
        fileName = "";
    else
        return;
    end
    [fullPath, implicit] = matlab.lang.internal.introspective.separateImplicitDirs(fullPath);
    optionsFile = fullfile(fullPath, "resources", "helpOptions.json");
    if ~isfile(optionsFile)
        return;
    end

    try
        helpOptions = jsondecode(fileread(optionsFile));
    catch
        return;
    end

    optionName = "preferSingleSource";

    preferReference = getFolderValue(helpOptions, optionName, preferReference);

    [helpOptions, preferReference] = iterateImplicitFolders(helpOptions, preferReference, optionName, implicit);
    if isempty(helpOptions)
        return;
    end

    if fileName ~= ""
        preferReference = getNestedValue(helpOptions, ["files", fileName, optionName], preferReference);
    end
end

function [helpOptions, preferReference] = iterateImplicitFolders(helpOptions, preferReference, optionName, implicit)
    if ~ismissing(implicit)
        folders = split(implicit, filesep);
        for folder = folders(:)'
            switch extractBefore(folder, 2)
            case "+"
                groupName = "namespaces";
            case "@"
                groupName = "classes";
            otherwise
                helpOptions = [];
                return;
            end
            groupValue = extractAfter(folder, 1);
            helpOptions = getNestedField(helpOptions, [groupName, groupValue]);
            if isempty(helpOptions)
                return;
            end
            preferReference = getFolderValue(helpOptions, optionName, preferReference);
        end
    end
end

function v = getFolderValue(s, optionName, v)
    v = getNestedValue(s, ["folder", optionName], v);
end

function v = getNestedValue(s, fields, v)
    arguments
        s      (1,1) struct
        fields (1,:) string
        v
    end
    s = getNestedField(s, fields);
    if ~isempty(s)
        v = s;
    end
end

function s = getNestedField(s, fields)
    arguments
        s      (1,1) struct
        fields (1,:) string
    end
    for field = fields
        if isfield(s, field)
            s = s.(field);
        else
            s = [];
            return;
        end
    end
end

%   Copyright 2023 The MathWorks, Inc.
