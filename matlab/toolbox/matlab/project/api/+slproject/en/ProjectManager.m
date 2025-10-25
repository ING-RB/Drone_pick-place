classdef ProjectManager< matlab.mixin.CustomDisplay
%ProjectManager  Query and manage a project
%    To query the currently loaded project, and to perform
%    various operations upon it, get a project object:
%
%    project = currentProject;
%
%    The project object can be used to:
%        Add and remove categories of labels
%        Add and remove files from the current project
%        Find files in the current project
%        List modified files identified by the source control system
%        Export (or archive) the current project.
%
%    Use methods(project) to obtain a list of the
%    available operations.

 
%   Copyright 2010-2023 The MathWorks, Inc.

    methods
        function out=addFile(~) %#ok<STOUT>
            %addFile  Add a file to this project
            %    Add a file to the current project. The file must be
            %    contained within the project root folder.
            %
            %    Usage:
            %    projectFile = addFile(project, file)
            %
            %    Example:
            %    openExample("simulink/AirframeProjectExample")
            %    project = currentProject;
            %
            %    % Create a new file:
            %    filepath = fullfile(project.RootFolder, 'new_model.slx')
            %    new_system('new_model');
            %    save_system('new_model', filepath)
            %
            %    % Add this new model to the project:
            %    projectFile = addFile(project, filepath)
        end

        function out=addFolderIncludingChildFiles(~) %#ok<STOUT>
            %addFolderIncludingChildFiles Add folder to this project
            %    Add a folder and all child files to the current project.
            %    The folder must be contained within the project root
            %    folder.
            %
            %    Usage:
            %    projectFolder = addFolderIncludingChildFiles(project, folder)
            %
            %    Example:
            %    openExample("simulink/AirframeProjectExample")
            %    project = currentProject;
            %
            %    % Create a new folder in the project folder:
            %    new_folder_path = fullfile(project.RootFolder, 'new_folder')
            %    mkdir(new_folder_path);
            %
            %    % Create a new folder in the previous folder:
            %    new_sub_folder_path = fullfile(new_folder_path, 'new_sub_folder')
            %    mkdir(new_sub_folder_path);
            %
            %    % Create a new file
            %    filepath = fullfile(new_sub_folder_path, 'new_model_in_subfolder.slx')
            %    new_system('new_model_in_subfolder');
            %    save_system('new_model_in_subfolder', filepath)
            %
            %    % Add this new folder and child files to the project:
            %    projectFile = addFolderIncludingChildFiles(project, new_folder_path)
        end

        function out=addPath(~) %#ok<STOUT>
            %addPath  Add a folder to the project path
            %    Add a folder to the current project path. The folder must
            %    be in the project.
            %
            %    Usage:
            %    projectPath = addPath(project, folder)
            %
            %    Example:
            %    openExample("simulink/AirframeProjectExample")
            %    project = currentProject;
            %
            %    % Create a new folder:
            %    folderpath = fullfile(project.RootFolder, 'folder')
            %    mkdir(folderpath);
            %
            %    % Add this new folder to the project:
            %    projectFile = addFile(project, folderpath)
            %
            %    % Add this new folder to the project path:
            %    projectPath = addPath(project, folderpath)
        end

        function out=addReference(~) %#ok<STOUT>
            %addReference  Add a project reference
            %    Add a project reference to the current project.
            %
            %    Usage:
            %    projectReference = addReference(project, folder)
            %    projectReference = addReference(project, folder, type)
            %
            %    type is an optional input that defines the type of
            %    reference to create. Valid options are 'relative' and
            %    'absolute'. The default is 'relative'.
            %
            %    Example:
            %    openExample("simulink/AirframeProjectExample")
            %    project = currentProject;
            %
            %    projectToReference = slproject.create();
            %
            %    reload(project);
            %    addReference(project, projectToReference, 'absolute');
        end

        function out=addShortcut(~) %#ok<STOUT>
            % addShortcut  Add a shortcut to this project
            %
            %    Usage:
            %    shortcut = addShortcut(project, file)
            %
            %    Example:
            %    openExample("simulink/AirframeProjectExample")
            %    project = currentProject;
            %
            %    % Create a new file:
            %    filepath = fullfile(project.RootFolder, 'new_model.slx')
            %    new_system('new_model');
            %    save_system('new_model', filepath)
            %
            %    % Add this new model to the project:
            %    projectFile = addFile(project, filepath)
            %
            %    % Add a new shortcut:
            %    shortcut = addShortcut(project, filepath);
        end

        function out=addShutdownFile(~) %#ok<STOUT>
            % addShutdownFile Add a shutdown file to this project
            %
            %    Usage:
            %    shutdownFile = addShutdownFile(project, file)
            %
            %    Example:
            %    openExample("simulink/AirframeProjectExample")
            %    project = currentProject;
            %
            %    % Executable MATLAB code to run as the project shuts down
            %    filepath = fullfile('utilities', 'rebuild_s_functions.m');
            %
            %    % Run the file automatically when the project shuts down
            %    shutdownFile = addShutdownFile(project, filepath);
        end

        function out=addStartupFile(~) %#ok<STOUT>
            % addStartupFile Add a startup file to this project
            %
            %    Usage:
            %    startupFile = addStartupFile(project, file)
            %
            %    Example:
            %    openExample("simulink/AirframeProjectExample")
            %    project = currentProject;
            %
            %    % Create a new file:
            %    filepath = fullfile(project.RootFolder, 'new_model.slx')
            %    new_system('new_model');
            %    save_system('new_model', filepath)
            %
            %    % Add this new model to the project:
            %    projectFile = addFile(project, filepath)
            %
            %    % Automatically open the model when the project starts:
            %    startupFile = addStartupFile(project, filepath);
        end

        function out=close(~) %#ok<STOUT>
            %close   Close this project
            %
            %    Usage:
            %    close(project)
            %
            %    Example:
            %    openExample("simulink/AirframeProjectExample")
            %    project = currentProject;
            %    close(project)
        end

        function out=createCategory(~) %#ok<STOUT>
            % createCategory  Create a category of labels in this project
            %
            %    Usage:
            %    category = createCategory(project, categoryName)
            %    category = createCategory(project, categoryName, dataType)
            %    category = createCategory(project, categoryName, dataType, 'single-valued')
            %
            %    categoryName is a string containing the name of the new
            %    category to create.
            %
            %    If the option string "single-valued" is used the new
            %    category will be a single valued category.
            %
            %    dataType is an optional input that defines the type of
            %    the data that can be associated with labels in this
            %    category. Valid options are 'double', 'logical',
            %    'char', 'string', 'integer' and 'none'. The default is
            %    'none'.
            %
            %    Example:
            %    openExample("simulink/AirframeProjectExample")
            %    project = currentProject;
            %
            %    % Add a new category:
            %    colorCategory = createCategory(project, 'color');
            %
            %    % Add a new category that can store string data within its
            %    % labels:
            %    fileOwners = createCategory(project, 'File Owners', 'char')
        end

        function out=export(~) %#ok<STOUT>
            %EXPORT  Export the project to a zip file
            %   EXPORT(proj,zipFileName) exports the project proj to a zip file
            %   specified  by zipFileName. The zip archive preserves the project files,
            %   structure labels, and shortcuts, and does not include any source
            %   control information. You can use the zip archive to send the project to
            %   customers, suppliers, or colleagues who do not have access to your
            %   source control repository. Recipients can create a new project from the
            %   zip archive by extracting the zip file and opening the .prj file.
            %
            %   EXPORT(proj,zipFileName,definitionType) exports the project using the
            %   specified definitionType for the project definition files, single or
            %   multiple. If you do not specify definitionType, the project's current
            %   setting is used. Use the definitionType export option if you want to
            %   change project definition file management from the type selected when
            %   the project was created. You can control project definition file
            %   management in the preferences.
        end

        function out=findCategory(~) %#ok<STOUT>
            %findCategory  Get a label category in this project
            %
            %    Usage:
            %    category = findCategory(project, categoryName)
            %
            %    If the category can not be found an empty array is
            %    returned.
            %
            %    Example:
            %    openExample("simulink/AirframeProjectExample")
            %    project = currentProject;
            %    classificationCategory = findCategory(project, 'Classification')
        end

        function out=findFiles(~) %#ok<STOUT>
            %findFiles  Find files from the project that match the options
            %
            %    Usage:
            %    findFiles(project, Label=Test, IncludeReferences=true)
            %
            %    Example:
            %    openExample("simulink/AirframeProjectExample")
            %    project = currentProject;
            %    findFiles(project, ...
            %         Label=Test, IncludeReferences=true)
        end

        function out=isLoaded(~) %#ok<STOUT>
            %isLoaded  Determine if this project is loaded
            %
            %    Usage:
            %    loaded = isLoaded(project)
            %
            %    Example:
            %    openExample("simulink/AirframeProjectExample")
            %    project = currentProject;
            %    loaded = isLoaded(project) % true
            %    close(project)
            %    loaded = isLoaded(project) % false
        end

        function out=listModifiedFiles(~) %#ok<STOUT>
            %listModifiedFiles List of modified files in the project
            %    Return an array of the project files which are listed in
            %    the modified files view of the project ui.
            %
            %    Usage:
            %    modifiedFiles = listModifiedFiles(project)
            %
            %    Example:
            %    openExample("simulink/AirframeProjectExample")
            %    project = currentProject;
            %    modifiedFiles = listModifiedFiles(project);
        end

        function out=listRequiredFiles(~) %#ok<STOUT>
            %listRequiredFiles Get a file's downstream dependencies
            %    Return the files that the specified file requires to run.
            %
            %    Usage:
            %    files = listRequiredFiles(project, file)
            %
            %    Where:
            %    file - Is a character vector that specifies the file
            %    relative to the project root, an absolute file path or an
            %    instance of an slproject.File object.
            %
            %    Example:
            %    openExample("simulink/AirframeProjectExample")
            %    project = currentProject;
            %    file = 'models/slproject_f14.slx'
            %    files = listRequiredFiles(project, file);
        end

        function out=refreshSourceControl(~) %#ok<STOUT>
            %refreshSourceControl Refresh the source control cache
            %    Refresh the project cache of source control information
            %
            %    Usage:
            %    refreshSourceControl(project)
            %
            %    Example:
            %    openExample("simulink/AirframeProjectExample")
            %    project = currentProject;
            %    refreshSourceControl(project);
        end

        function out=reload(~) %#ok<STOUT>
            %reload  Reload this project
            %
            %    Usage:
            %    reload(project)
            %
            %    Example:
            %    openExample("simulink/AirframeProjectExample")
            %    project = currentProject;
            %    close(project)
            %    reload(project)
        end

        function out=removeCategory(~) %#ok<STOUT>
            %removeCategory  Remove a label category from the project
            %
            %    Usage:
            %    removeCategory(project, categoryName)
            %
            %    Example:
            %    openExample("simulink/AirframeProjectExample")
            %    project = currentProject;
            %
            %    % Add a new category:
            %    colorCategory = createCategory(project, 'color');
            %
            %    % Remove it:
            %    removeCategory(project, 'color')
        end

        function out=removeFile(~) %#ok<STOUT>
            %removeFile  Remove a file from the project
            %
            %    Usage:
            %    removeFile(project, file)
            %
            %    Example:
            %    openExample("simulink/AirframeProjectExample")
            %    project = currentProject;
            %    removeFile(project, ...
            %         fullfile(project.RootFolder, 'src', 'timesthree.c'))
        end

        function out=removePath(~) %#ok<STOUT>
            %removePath  Remove a folder from the project path
            %    Remove a folder from the current project path. The folder
            %    must be in the project.
            %
            %    Usage:
            %    removePath(project, folder)
            %
            %    Example:
            %    openExample("simulink/AirframeProjectExample")
            %    project = currentProject;
            %
            %    % Create a new folder:
            %    folderpath = fullfile(project.RootFolder, 'folder')
            %    mkdir(folderpath);
            %
            %    % Add this new folder to the project:
            %    projectFile = addFile(project, folderpath)
            %
            %    % Add this new folder to the project path:
            %    projectPath = addPath(project, folderpath)
            %
            %    % Remove this new folder from the project path:
            %    removePath(project, folderpath)
        end

        function out=removeReference(~) %#ok<STOUT>
            %removeReference  Remove a project reference
            %    Remove a project reference from the current project.
            %
            %    Usage:
            %    removeReference(project, folder)
            %
            %    Example:
            %    openExample("simulink/AirframeProjectExample")
            %    project = currentProject;
            %
            %    projectToReference = slproject.create();
            %    reload(project);
            %    addReference(project, projectToReference);
            %
            %    removeReference(project, projectToReference);
        end

        function out=removeShortcut(~) %#ok<STOUT>
            %removeShortcut  Remove a shortcut to a project file
            %
            %    Usage:
            %    removeShortcut(project, shortcut)
            %
            %    Example:
            %    openExample("simulink/AirframeProjectExample")
            %    project = currentProject;
            %
            %    % Create a new file:
            %    filepath = fullfile(project.RootFolder, 'new_model.slx')
            %    new_system('new_model');
            %    save_system('new_model', filepath)
            %
            %    % Add this new model to the project:
            %    projectFile = addFile(project, filepath)
            %
            %    % Add a new shortcut:
            %    shortcut = addShortcut(project, filepath);
            %
            %    % Remove the shortcut:
            %    removeShortcut(project, shortcut);
        end

        function out=removeShutdownFile(~) %#ok<STOUT>
            %removeShutdownFile  Remove a shutdown file from this project
            %
            %    Usage:
            %    removeShutdownFile(project, startupFile)
            %
            %    Example:
            %    openExample("simulink/AirframeProjectExample")
            %    project = currentProject;
            %
            %    % Executable MATLAB code to run as the project shuts down
            %    filepath = fullfile('utilities', 'rebuild_s_functions.m');
            %
            %    % Run the file automatically when the project shuts down
            %    shutdownFile = addShutdownFile(project, filepath);
            %
            %    % Remove the startup file:
            %    removeShutdownFile(project, shutdownFile);
        end

        function out=removeStartupFile(~) %#ok<STOUT>
            %removeStartupFile  Remove a startup file from this project
            %
            %    Usage:
            %    removeStartupFile(project, startupFile)
            %
            %    Example:
            %    openExample("simulink/AirframeProjectExample")
            %    project = currentProject;
            %
            %    % Create a new file:
            %    filepath = fullfile(project.RootFolder, 'new_model.slx')
            %    new_system('new_model');
            %    save_system('new_model', filepath)
            %
            %    % Add this new model to the project:
            %    projectFile = addFile(project, filepath)
            %
            %    % Automatically open the model when the project starts:
            %    startupFile = addStartupFile(project, filepath);
            %
            %    % Remove the startup file:
            %    removeStartupFile(project, startupFile);
        end

    end
    properties
        % An array of the categories in this project
        Categories;

        % Dependencies between project files
        Dependencies;

        % An array of the files in this project
        Files;

        % Information about this project
        Information;

        % The name of this project
        Name;

        % An array of folders that the project puts on the MATLAB path
        % while the project is open.
        ProjectPath;

        % An array of folders that contain referenced projects.
        ProjectReferences;

        % The path to the root folder of this project
        RootFolder;

        % An array of the shortcuts in this project
        Shortcuts;

        % An array of the shutdown files in this project
        ShutdownFiles;

        % An array of the startup files in this project
        StartupFiles;

    end
end
