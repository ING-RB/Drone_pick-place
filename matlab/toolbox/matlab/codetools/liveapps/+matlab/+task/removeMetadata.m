function removeMetadata(taskFile)
    %REMOVEMETADATA Remove custom live task's metadata for Live Editor
    %   REMOVEMETADATA(taskFile) removes the Live Editor metadata for the
    %   custom task specified by taskFile. This removes the task from the Live
    %   Editor gallery and auto completions.
    %
    %   See also matlab.task.configureMetadata

    %   Copyright 2021 The MathWorks, Inc.
    import matlab.internal.task.metadata.Constants

    narginchk(0, 1);
    
    narginchk(0, 1);

    if nargin == 0
        [taskFile, filePath] = uigetfile('*.m', string(message('rtc_addons:livetask:liveTasks:SelectFileHeader')));
        if isequal(taskFile, 0)
            return;
        end
        taskFile = [filePath taskFile];
    end

    try
        fullFileName = matlab.internal.task.metadata.getValidatedTaskFile(taskFile);
    catch exception
        throw(exception);
    end

    % Create and store Model from the provided taskFile
    model = matlab.internal.task.metadata.Model(fullFileName);
    if ~model.getModelValidity()
        error(message([Constants.MessageCatalogPrefix 'InvalidModelErrorMsg']));
    end

    model.deRegisterTask();
end
