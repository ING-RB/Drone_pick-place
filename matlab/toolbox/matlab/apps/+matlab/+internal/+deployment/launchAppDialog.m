function launchAppDialog(path, name, filename, matfilename, requiredFiles)
%LAUNCHAPPDIALOG helper function for opening the App Packager
%

%   Copyright 2020 The MathWorks, Inc.

    import com.mathworks.toolbox.apps.services.AppsPackagingService;

    if exist(fullfile(path, [name '.prj']), 'file')
        localDeleteFile(fullfile(path, [name '.prj']));
    end

    key = AppsPackagingService.createAppsProject(path, [name '.prj']);

    % The Packaging service will throw null pointer exceptions 
    % if the filenames are empty.

    % Add main file.
    if ~isempty(filename)
        AppsPackagingService.addMainFile(key, filename);
    end

    % Add resources.
    if ~isempty(matfilename)
        AppsPackagingService.addResourceFile(key, matfilename);
    end

    % Add Required Files.
    if ~isempty(requiredFiles)
        AppsPackagingService.addResourceFile(key, requiredFiles);
    end

    % Get the actual location of the prj.
    projectLocation = AppsPackagingService.getProjectFileLocation(key);

    % close project forces it to save and blocks on saving
    % It is part of the recommended workflow to close the project from
    % services before proceeding to edit the same project in the GUI
    AppsPackagingService.closeProject(key);

    % Open the app dialog.
    open(char(projectLocation))
end

function localDeleteFile(name)

    oldState = recycle;
    recycle('off');
    delete(name)
    recycle(oldState);
end