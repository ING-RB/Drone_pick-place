function resolveInput(messagesModel, items)
%resolveInput resolves the input to its full file path and save it to the
%MF0 model

%   Copyright 2022-2024 The MathWorks, Inc.
    if feature("AppDesignerPlainTextFileFormat")
        validExtension = {'.m', '.mlx', '.mlapp', '.mapp'};
    else
        validExtension = {'.m', '.mlx', '.mlapp'};
    end
    resolvedPaths = matlab.codeanalyzer.internal.resolvePaths(items, validExtension);
    messagesModel.folders.clear();
    messagesModel.files.clear();
    for path = resolvedPaths
        if isfolder(path)
            messagesModel.folders.add(char(path))
        else
            messagesModel.files.add(char(path))
        end
    end
end
