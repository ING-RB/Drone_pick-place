function extractHelpText(inputFullPath, outputDir)
    arguments
        inputFullPath {mustBeTextScalar}
        outputDir     {mustBeTextScalar}
    end

    [pathStr, fileName] = fileparts(inputFullPath);

    if pathStr == ""
        error(message('MATLAB:introspective:extractHelpText:HelpContainerFactoryInvalidFilePath', inputFullPath));
    end

    if ~isfile(inputFullPath)
        error(message('MATLAB:introspective:extractHelpText:FileNotFound'));
    end

    outputFile = fullfile(outputDir, append(fileName, '.m'));
    if isequal(outputFile, inputFullPath)
        error(message('MATLAB:introspective:extractHelpText:SameFile'));
    end

    if isfile(outputFile)
        s = warning('off', 'MATLAB:DELETE:Permission');
        cleanup = onCleanup(@()warning(s));
        delete(outputFile);
        if isfile(outputFile)
            error(message('MATLAB:introspective:extractHelpText:CannotDeleteFile'));
        end
    end

    helpContainer = matlab.lang.internal.introspective.containers.HelpContainerFactory.create(inputFullPath, 'onlyLocalHelp', true);
    helpContainer.exportToMFile(outputDir);
end

%   Copyright 2013-2024 The MathWorks, Inc.
