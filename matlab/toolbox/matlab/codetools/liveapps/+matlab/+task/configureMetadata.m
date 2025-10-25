function configureMetadata(taskFile)
    %CONFIGUREMETADATA Configure custom live task's metadata for Live Editor
    %   CONFIGUREMETADATA(taskFile) launches a dialog to configure the
    %   metadata to display the task in the Live Editor gallery and auto
    %   completions. After specifying the metadata, a resources folder
    %   with the live task metadata file is created in the same directory
    %   as taskFile. When the folder containing taskFile and the resources
    %   folder containing the metadata file is on the MATLAB path, the task
    %   will appear in the Live Editor gallery and auto completions.
    %
    %   See also appdesigner.customcomponent.removeMetadata

    %   Copyright 2021 The MathWorks, Inc.

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

    matlab.internal.task.metadata.ConfigureMetadata(fullFileName);
end
