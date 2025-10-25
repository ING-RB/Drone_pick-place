classdef MexTask < matlab.buildtool.Task
    % MexTask - Task to build a MEX file
    %
    %   The matlab.buildtool.tasks.MexTask class provides a task to compile and
    %   link source files into a binary MEX file.
    %
    %   MexTask properties:
    %       SourceFiles  - Source files to compile
    %       OutputFolder - Folder to contain the MEX file
    %       Filename     - Name of the MEX file to build
    %       MexFile      - Binary MEX file to build
    %       Options      - Options for customizing the build
    %
    %   MexTask methods:
    %       forEachFile - Create task group with MexTask instance for each file
    %       MexTask - Class constructor
    %
    %   Examples:
    %
    %       % Import the MexTask class
    %       import matlab.buildtool.tasks.MexTask
    %
    %       % Create a task to compile mymex.c into a MEX file and save the
    %       % resulting MEX file to the toolbox directory
    %       task = MexTask("mymex.c","toolbox");
    %
    %       % Create a task to build a MEX file with a specified name
    %       task = MexTask("mymex.c","toolbox",Filename="myoutput");
    %
    %       % Create a task to build a MEX file with a specified name from multiple 
    %       % source files
    %       task = MexTask(["gateway.c" "shared.c"],"toolbox",Filename="myoutput");
    %
    %       % Create a task to build a MEX file using the -R2018 API
    %       task = MexTask("mymex.c","toolbox",Options="-R2018a");
    %
    %       % Create a build plan
    %       plan = buildplan;
    %
    %       % Add the "mex" task to the plan
    %       plan("mex") = task;
    %
    %       % Run the "mex" task
    %       plan.run("mex");
    %
    %   See also MEX
    
    %   Copyright 2023-2024 The MathWorks, Inc.

    properties (TaskInput)
        % SourceFiles - Source files to compile
        %
        %   Source files to compile, specified as a string vector, character
        %   vector, cell vector of character vectors, or vector of 
        %   matlab.buildtool.io.FileCollection objects, and returned as a row
        %   vector of FileCollection objects.
        SourceFiles (1,:) matlab.buildtool.io.FileCollection
    end

    properties
        % OutputFolder - Folder to contain the MEX file
        %
        %   Folder to contain the MEX file, specified as a string scalar, 
        %   character vector, or matlab.buildtool.io.File object, and 
        %   returned as a matlab.buildtool.io.File object.
        OutputFolder matlab.buildtool.io.File {mustBeScalarOrEmpty}

        % Filename - Name of the MEX file to build
        %
        %   Name of the MEX file to build, specified as a string scalar or
        %   character vector, and returned as a string scalar.
        Filename (1,1) string {mustBeValidFilename}
    end

    properties (TaskOutput, Dependent, SetAccess = private)
        % MexFile - Binary MEX file to build
        %
        %   Binary MEX file to build, returned as a matlab.buildtool.io.File
        %   object.
        MexFile matlab.buildtool.io.File {mustBeScalarOrEmpty}
    end

    properties (TaskInput)
        % Options - Options for customizing the build
        %
        %   Options for customizing the build, specified as a string vector.
        %   The task supports the same release-specific API and build options
        %   that you can pass to the mex command when building a MEX file.
        %   For example, you can specify ["-R2018a" "-v"] to build a MEX file
        %   with the -R2018a API in verbose mode.
        Options (1,:) string {mustBeSupportedOption}
    end

    methods (Static)
        function group = forEachFile(sourceFiles, outputFolder, options)
            % forEachFile - Create task group with MexTask instance for each file
            %
            %   GROUP = matlab.buildtool.tasks.MexTask.forEachFile(SOURCEFILES,OUTPUTFOLDER)
            %   creates a task group containing a MexTask instance for each specified
            %   source file. The task group compiles and links the source files into
            %   binary MEX files and saves them to the specified output folder.
            %
            %   GROUP = matlab.buildtool.tasks.MexTask.forEachFile(_,Name=Value)
            %   specifies options using one or more of these name-value arguments:
            %
            %       * CommonSourceFiles - Source files common to all the MexTask
            %       instances in the group, specified as a string vector or
            %       FileCollection vector.
            %
            %       * Options - Options for customizing the mex build configuration,
            %       specified as a string vector.

            arguments
                sourceFiles (1,:) matlab.buildtool.io.FileCollection
                outputFolder (1,1) matlab.buildtool.io.File
                options.CommonSourceFiles (1,:) matlab.buildtool.io.FileCollection = matlab.buildtool.io.FileCollection.empty(1,0)
                options.Options (1,:) string {mustBeSupportedOption} = string.empty(1,0)
                options.Dependencies (1,:) string = string.empty(1,0)
                options.Description (1,1) string = getString(message("MATLAB:buildtool:MexTask:DefaultGroupDescription"))
            end
    
            import matlab.buildtool.TaskGroup;
            import matlab.buildtool.io.File;
            import matlab.buildtool.tasks.MexTask;
            
            files = File.empty();
            for f = sourceFiles(:)'
                files = [files File(f.paths(),BuildingTask=f.BuildingTask)]; %#ok<AGROW>
            end
    
            tasks = arrayfun(@(f)MexTask([f,options.CommonSourceFiles],outputFolder,Options=options.Options), files);
            tasks = [tasks MexTask.empty(1,0)];
    
            [~,names] = fileparts([tasks.Filename string.empty(1,0)]);
    
            group = TaskGroup(tasks, ...
                TaskNames=names, ...
                Dependencies=options.Dependencies, ...
                Description=options.Description);
        end
    end

    methods
        function task = MexTask(sourceFiles, outputFolder, options)
            % MexTask - Class constructor
            %
            %   TASK = matlab.buildtool.tasks.MexTask(SOURCE,OUTPUTFOLDER)
            %   creates a task to compile and link the source files in SOURCE
            %   into a binary MEX file. The task saves the resulting MEX file
            %   to OUTPUTFOLDER.
            %
            %   TASK = matlab.buildtool.tasks.MexTask(SOURCE,OUTPUTFOLDER,Name=Value)
            %   creates a task with additional options specified by one or more of
            %   these name-value arguments:
            %
            %       * Filename - Name of the MEX file to build, specified as
            %         a string scalar or character vector.
            %
            %       * Options  - Options for customizing the build, specified
            %         as a string vector. You can use this argument to
            %         specify the same release-specific API and build options
            %         that you pass to the mex command when building a MEX
            %         file. For example, specify Options=["-R2018a","-v"] to create
            %         a task to build a MEX file with the -R2018a API in verbose
            %         mode.
            %
            %   Examples:
            %
            %       % Import the MexTask class
            %       import matlab.buildtool.tasks.MexTask
            %
            %       % Create a task to compile mymex.c into a MEX file and save the
            %       % resulting MEX file to the toolbox directory
            %       task = MexTask("mymex.c","toolbox");
            %
            %       % Create a task to build a MEX file with a specified name
            %       task = MexTask("mymex.c","toolbox",Filename="myoutput");
            %
            %       % Create a task to build a MEX file with a specified name from multiple 
            %       % source files
            %       task = MexTask(["gateway.c" "shared.c"],"toolbox",Filename="myoutput");
            %
            %       % Create a task to build a MEX file using the -R2018 API
            %       task = MexTask("mymex.c","toolbox",Options="-R2018a");

            arguments
                sourceFiles (1,:) matlab.buildtool.io.FileCollection {mustBeNonempty}
                outputFolder (1,1) matlab.buildtool.io.File
                options.Filename (1,1) string {mustBeValidFilename} = defaultFilename(sourceFiles)
                options.Options (1,:) string {mustBeSupportedOption} = string.empty(1,0)
                options.Dependencies (1,:) string = string.empty(1,0)
                options.Description (1,1) string
            end

            task.SourceFiles = sourceFiles;
            task.OutputFolder = outputFolder;
            task.Description = defaultDescription(options.Filename);

            for prop = string(fieldnames(options))'
                task.(prop) = options.(prop);
            end
        end

        function mexFile = get.MexFile(task)
            import matlab.buildtool.io.File;
            mexFile = File(fullfile(task.OutputFolder.Path, task.Filename));
        end

        function task = set.Filename(task, name)
            [folder, file] = fileparts(name);
            task.Filename = fullfile(folder, file + "." +  mexext);
        end
    end

    methods (TaskAction, Sealed, Hidden)
        function buildMex(task, context)
            arguments
                task (1,1) matlab.buildtool.tasks.MexTask
                context (1,1) matlab.buildtool.TaskContext
            end

            import matlab.automation.Verbosity;

            source = task.SourceFiles.paths();

            opts = task.Options;
            if isfield(context.BuildOptions,"Verbosity") && ~isempty(context.BuildOptions.Verbosity)
                opts(ismember(lower(opts),["-v","-silent"])) = [];
                switch context.BuildOptions.Verbosity
                    case Verbosity.None
                        opts(end+1) = "-silent";
                    case Verbosity.Verbose
                        opts(end+1) = "-v";
                end
            end

            cmd = sprintf("mex %s -output %s %s", ...
                strjoin(quoteWrapIfNecessary(source)), ...
                quoteWrapIfNecessary(task.MexFile.Path), ...
                strjoin(quoteWrapIfNecessary(opts)));

            context.log(cmd);
            eval(cmd);
        end
    end
end

function name = defaultFilename(sourceFiles)
paths = sourceFiles.paths();
if isempty(paths)
    error(message("MATLAB:buildtool:MexTask:FailedToDetermineOutput"))
end
[~,name] = fileparts(paths(1));
name = name+"."+mexext;
end

function desc = defaultDescription(filename)
[~,name] = fileparts(filename);
desc = getString(message("MATLAB:buildtool:MexTask:DefaultDescription", name));
end

function mustBeSupportedOption(options)
unsupportedOptions = ismember(lower(options), ["-c", "-client", "-setup", "-n", "-h", "-help"]);
if any(unsupportedOptions)
    unsupported = options(unsupportedOptions);
    error(message("MATLAB:buildtool:MexTask:UnsupportedOption", unsupported(1)));
end

unsupportedNameOptions = ismember(lower(options), ["-output", "-outdir"]);
if any(unsupportedNameOptions)
    unsupported = options(unsupportedNameOptions);
    error(message("MATLAB:buildtool:MexTask:NameOptionUnsupported", unsupported(1)));
end
end

function mustBeValidFilename(name)
[path,~,~] = fileparts(name);
if ~(path == "")
    error(message("MATLAB:buildtool:MexTask:InvalidFilename", name))
end
end

function str = quoteWrapIfNecessary(str)
tf = contains(str, [whitespacePattern(),"'"]);
str(tf) = strrep(str(tf), "'", "''");
str(tf) = "'" + str(tf) + "'";
end

% LocalWords:  mymex myoutput buildplan outdir OUTPUTFOLDER
