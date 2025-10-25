classdef Project< matlab.mixin.CustomDisplay & dynamicprops
%Project Query and manage an open project
%    The matlab.project.Project allows a user to query the currently
%    loaded project, and to perform various operations upon it.
%    To get the matlab.project.Project object, use
%
%    project = currentProject;
%
%    The Project object can be used to:
%        Add and remove categories of labels
%        Add and remove files from the current project
%        Find files in the current project
%        List modified files identified by the source control system
%        Export (or archive) the current project.
%
%    Use methods(matlab.project.currentProject) to obtain a list of the
%    available operations for this class, each of which has their own
%    help. For example, try help matlab.project.Project.findFile

 
%   Copyright 2010-2024 The MathWorks, Inc.

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
            %    project = currentProject;
            %
            %    % Create a new file:
            %    filepath = fullfile(project.RootFolder, 'data.mat')
            %    save(filepath)
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
            %    filepath = fullfile(new_sub_folder_path, 'data_in_subfolder.mat')
            %    save(filepath)
            %
            %    % Add this new folder and child files to the project:
            %    projectFile = addFolderIncludingChildFiles(project, new_folder_path)
        end

        function out=addLabel(~) %#ok<STOUT>
            %addLabel  Attach a label to project files
            %
            %    Usage:
            %    label = addLabel(proj, files, labelDefinitionOrLabelName);
            %    label = addLabel(proj, files, labelDefinition, data);
            %
            %    label = addLabel(proj, files, categoryNameOrCategory, labelName)
            %    label = addLabel(proj, files, categoryNameOrCategory, labelName, data)
            %
            %    Example:
            %    proj = currentProject;
            %    % Get paths for project files
            %    filepaths = [fullfile(project.RootFolder, 'data.mat'),
            %               fullfile(project.RootFolder, 'script.m')];
            %    % Add this label to this file:
            %    addLabel(proj, filepaths, "Test")
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
            %    project = currentProject;
            %
            %    projectToReference = matlab.project.createProject();
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
            %    project = currentProject;
            %
            %    % Create a new file:
            %    filepath = fullfile(project.RootFolder, 'data.mat')
            %    save(filepath);
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
            %    project = currentProject;
            %
            %    % Executable MATLAB code to run as the project shuts down
            %    filepath = fullfile(project.RootFolder, 'fileToRun.m')
            %    % Create file to run
            %    fid = fopen(filepath,"w"); fprintf(fid, "disp('Running file')"), fclose(fid);
            %    % Add the file to the project
            %    addFile(project, filepath);
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
            %    project = currentProject;
            %
            %    % Create a new file:
            %    filepath = fullfile(project.RootFolder, 'data.mat')
            %    save(filepath)
            %
            %    % Add this new model to the project:
            %    projectFile = addFile(project, filepath)
            %
            %    % Automatically open the model when the project starts:
            %    startupFile = addStartupFile(project, filepath);
        end

        function out=close(~) %#ok<STOUT>
            %CLOSE   Close this project
            %
            %    Usage:
            %    CLOSE(project)
            %
            %    Example:
            %    project = currentProject;
            %    CLOSE(project)
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
            %matlab.project.Project/export - Export project to archive
            %   This MATLAB function exports the specified project to a new project
            % archive file named archiveName.
            %
            % Syntax
            %   export(proj,archiveName)
            %   export(proj,Name=Value)
            %
            % Input Arguments
            %   proj - Project
            %     matlab.project.Project object
            %   archiveName - Archive filename or path
            %     character vector | string scalar
            %
            % Name-Value Arguments
            %   ArchiveReferences - Option to include references in package
            %     true or 1 (default) | false or 0
            %   ExportProfile - Option to specify export profile name
            %     'none' (default)
            %   Files - Files to export
            %     string array | cell array of character vectors |
            %     array of ProjectFile objects
            %   IgnoreMissingFilesError - Option to allow exporting projects with
            %   missing files
            %     false or 0 (default) | true or 1
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
            %    project = currentProject;
            %    classificationCategory = findCategory(project, 'Classification')
        end

        function out=findFiles(~) %#ok<STOUT>
            %findFiles - Find project files by category or label name
            % This MATLAB function filters all project files and folders in the project
            %
            % Syntax
            %    projectFiles=findFiles(project)
            %    projectFiles=findFiles(project,files)
            %    projectFiles=findFiles(___,Name=Value)
            %
            % Input Arguments
            %   project - Project
            %     matlab.project.Project object
            %   files - Path of files
            %     string array | cell array of character vectors |
            %     array of ProjectFile objects
            %
            % Name-Value Arguments
            %   Category - Name of category
            %     character vector | string scalar | Category object
            %   Label - Name of label
            %     character vector | string scalar | LabelDefinition object
            %   IncludeReferences - Option to include referenced projects
            %     false or 0 (default) | true or 1
            %   OutputFormat - Output format
            %     "string" (default) | "ProjectFile"
            %
            % Output Arguments
            %   projectFiles - Project files
            %     string array (default) | ProjectFile object
            %
            % Example
            %   project = currentProject();
            %
            %   % find all files labeled Design in your project hierarchy
            %   allDesignFiles =
            %   findFiles(project,Label="Design",IncludeReferences=1);
        end

        function out=isLoaded(~) %#ok<STOUT>
            %isLoaded  Determine if this project is loaded
            %
            %    Usage:
            %    loaded = isLoaded(project)
            %
            %    Example:
            %    project = currentProject;
            %    loaded = isLoaded(project) % true
            %    close(project)
            %    loaded = isLoaded(project) % false
        end

        function out=listAllProjectReferences(~) %#ok<STOUT>
            %listAllProjectReferences  List all projects in the reference
            %    hierarchy of the current project.
            %
            %    allReferences = listAllProjectReferences(project) returns
            %    an array of Project Reference objects.
            %
            %    Example:
            %    project = currentProject;
            %    allReferences = listAllProjectReferences(project)
        end

        function out=listImpactedFiles(~) %#ok<STOUT>
            %listImpactedFiles Get files impacted by changes to specified
            %files
            %    impactedFiles = listImpactedFiles(project,files) returns a
            %    string array of project files that require any of the
            %    specified files to run.
            %
            %    project - Currently loaded project, specified as a
            %    matlab.project.Project object.
            %
            %    files - File paths, specified as a string array,
            %    cell array of character vectors, or a ProjectFile object
            %    array. Specify files as absolute file paths or paths
            %    relative to the project root folder. Files not within the
            %    project root folder are ignored.
            %
            %    Example:
            %    project = currentProject;
            %    file = project.Files(1) % Select the first file in the project
            %    impactedFiles = listImpactedFiles(project,file);
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
            %    project = currentProject;
            %    modifiedFiles = listModifiedFiles(project);
        end

        function out=listRequiredFiles(~) %#ok<STOUT>
            %listRequiredFiles Get files required by specified files
            %    requiredFiles = listRequiredFiles(project,files) returns a
            %    string array of files that are required by any of the
            %    specified files to run.
            %
            %    project - Currently loaded project, specified as a
            %    matlab.project.Project object.
            %
            %    files - File paths, specified as a string array,
            %    cell array of character vectors, or a ProjectFile object
            %    array. Specify files as absolute file paths or paths
            %    relative to the project root folder. Files not within the
            %    project root folder are ignored.
            %
            %    Example:
            %    project = currentProject;
            %    file = project.Files(1) % Select the first file in the project
            %    requiredFiles = listRequiredFiles(project,file);
        end

        function out=listShutdownIssues(~) %#ok<STOUT>
            %listShutdownIssues List issues encountered during a project startup
            %    Return an array of the project issues encountered
            %    during a project shutdown.
            %    By default, listShutdownIssues returns startup issues for the whole
            %    project hierarchy.
            %
            %    listShutdownIssues(proj,IncludeReferences=false)
            %    does not include shutdown issues for referenced projects.
            %
            %    listShutdownIssues(__,ID=id) returns the issues with the
            %    specified ID.
            %
            %    Usage:
            %    shutdownIssues = listShutdownIssues(project)
            %
            %    Example:
            %    proj = currentProject;
            %    shutdownIssues = listShutdownIssues(proj)
        end

        function out=listStartupIssues(~) %#ok<STOUT>
            %listStartupIssues List issues encountered during a project startup
            %    Return an array of the project issues encountered
            %    during a project startup.
            %    By default, listStartupIssues returns startup issues for the whole
            %    project hierarchy.
            %
            %    listStartupIssues(proj,IncludeReferences=false)
            %    does not include startup issues for referenced projects.
            %
            %    listStartupIssues(__,ID=id) returns the issues with the
            %    specified ID.
            %
            %    Usage:
            %    startupIssues = listStartupIssues(project)
            %
            %    Example:
            %    proj = currentProject;
            %    startupIssues = listStartupIssues(proj)
        end

        function out=refreshSourceControl(~) %#ok<STOUT>
            %refreshSourceControl Refresh the source control cache
            %    Refresh the project cache of source control
            %    information
            %
            %    Usage:
            %    refreshSourceControl(project)
            %
            %    Example:
            %    project = currentProject;
            %    refreshSourceControl(project);
        end

        function out=reload(~) %#ok<STOUT>
            %RELOAD  Reload this project
            %
            %    Usage:
            %    RELOAD(project)
            %
            %    Example:
            %    project = currentProject;
            %    close(project)
            %    RELOAD(project)
        end

        function out=removeCategory(~) %#ok<STOUT>
            %removeCategory  Remove a label category from the project
            %
            %    Usage:
            %    removeCategory(project, categoryName)
            %
            %    Example:
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
            %    project = currentProject;
            %    removeFile(project, ...
            %         fullfile(project.RootFolder, 'src', 'timesthree.c'))
        end

        function out=removeLabel(~) %#ok<STOUT>
            %removeLabel  Detach a label from project files
            %
            %    Usage:
            %    removeLabel(proj, files, labelName)
            %    removeLabel(proj, files, label)
            %    removeLabel(proj, files, categoryName, labelName)
            %    removeLabel(proj, files, category, labelName)
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
            %    project = currentProject;
            %
            %    projectToReference = matlab.project.createProject();
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
            %    project = currentProject;
            %
            %    % Create a new file:
            %    filepath = fullfile(project.RootFolder, 'data.mat')
            %    save(filepath)
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
            %    project = currentProject;
            %
            %    filepath = fullfile(project.RootFolder, 'fileToRun.m')
            %    % Create file to run
            %    fid = fopen(filepath,"w"); fprintf(fid, "disp('Running file')"), fclose(fid);
            %    % Add the file to the project
            %    addFile(project, filepath);
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
            %    project = currentProject;
            %
            %    % Create a new file:
            %    filepath = fullfile(project.RootFolder, 'data.mat')
            %    save(filepath)
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

        function out=runChecks(~) %#ok<STOUT>
            %runProjectChecks   Run all project checks
            %
            % Runs all the project checks. The check for derived files will
            % fail if the project dependency analysis has not been run.
            %    Usage:
            %    results = runChecks(project)
            %
            %    Example:
            %    project = currentProject;
            %    results = runChecks(project)
            %
            %    project = currentProject;
            %    project.updateDependencies;
            %    results = runChecks(project)
        end

        function out=updateDependencies(~) %#ok<STOUT>
            %updateDependencies Update the project dependency graph
            %    Run a dependency analysis to update the known
            %    dependencies between project files. Access the
            %    dependency graph through the Dependencies property.
            %
            %    Usage:
            %    updateDependencies(project)
            %
            %    Example:
            %    project = currentProject;
            %    updateDependencies(project);
        end

    end
    properties
        % An array of the categories in this project
        Categories;

        % The type of files used by the project for storage
        DefinitionFilesType;

        % Dependencies between project files
        Dependencies;

        % The project description
        Description;

        % An array of the files in this project
        Files;

        % The name of this project
        Name;

        % An array of folders that the project puts on the MATLAB path
        % while the project is open
        ProjectPath;

        % An array of folders that contain referenced projects
        ProjectReferences;

        % Logical stating whether this project is read only
        ReadOnly;

        % The source control repository location
        RepositoryLocation;

        % The path to the root folder of this project
        RootFolder;

        % An array of the shortcuts in this project
        Shortcuts;

        % An array of the shutdown files in this project
        ShutdownFiles;

        % The name of the Source Control Integration
        SourceControlIntegration;

        % An array of the startup files in this project
        StartupFiles;

        % Is the project loaded as a top level project
        TopLevel;

    end
end
