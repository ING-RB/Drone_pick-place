classdef PcodeTask < matlab.buildtool.Task
    % PcodeTask - Task to create P-code files
    %
    %   The matlab.buildtool.tasks.PcodeTask class provides a task to obfuscate
    %   the source code in .m files and folders.
    %
    %   PcodeTask properties:
    %       Source               - Names of source files and folders to obfuscate
    %       PcodeFiles           - P-code files to create
    %       OutputFolder         - Folder to contain the P-code files
    %       Algorithm            - Algorithm to use for obfuscating source files
    %       PreserveSourceFolder - Whether to include specified source
    %                              folders in the task output
    %
    %   PcodeTask methods:
    %       PcodeTask - Class constructor
    %
    %   Examples:
    %       
    %       % Import the PcodeTask class
    %       import matlab.buildtool.tasks.PcodeTask
    %
    %       % Create a task to obfuscate the contents of the src folder in place
    %       task = PcodeTask("src","src");
    %
    %       % Create a task to obfuscate a file in your current folder in place
    %       task = PcodeTask("myfile.m",pwd);
    %
    %       % Create a task to obfuscate the contents of the src folder and save 
    %       % the P-code files in the out folder while maintaining the folder structure
    %       task = PcodeTask("src","out");
    %
    %       % Create a task to obfuscate the contents of the src folder and
    %       % save the P-code files in the out folder without maintaining
    %       % the folder structure
    %       task = PcodeTask("src/**/*.m", "out");
    %
    %       % Create a task to obfuscate the files in the src folder using a
    %       % legacy obfuscation algorithm
    %       task = PcodeTask("src","out",Algorithm="R2007b");
    %
    %       % Use the task in a plan
    %       % -- buildfile.m
    %       function plan = buildfile()
    %
    %       plan = buildplan;
    %       plan("pcode") = PcodeTask("src/*.m","out");
    %
    %       % -- Run the task
    %       buildtool pcode
    %
    %   See also PCODE, BUILDTOOL
    
    %   Copyright 2023-2024 The MathWorks, Inc.

    properties
        % Source - Names of source files and folders to obfuscate
        % 
        %   Names of source files and folders to obfuscate, specified as a
        %   string array, or matlab.buildtool.io.FileCollection object array.
        %
        %   The names can include the * and ** wildcards. For example, if you
        %   specify the names as ["*.m" "special/myfile.m"], the task obfuscates
        %   all MATLAB .m source files in the current folder as well as "myfile.m"
        %   in the "special" subfolder.
        Source (1,:) matlab.buildtool.io.FileCollection

        % OutputFolder - Folder that contains P-code files
        %
        %   Folder that contains the P-code files, specified as a string scalar, 
        %   character vector, or matlab.buildtool.io.File object, and 
        %   returned as a matlab.buildtool.io.File object.
        %
        %   For source files specified with relative paths, the task
        %   places the P-code files in OutputFolder and maintains the 
        %   original folder structure. For source files specified with 
        %   absolute paths, the task places the P-code files directly 
        %   in OutputFolder and does not preserve the original folder
        %   structure. Supplying the path to the current folder
        %   obfuscates the source files in place.
        OutputFolder matlab.buildtool.io.File {mustBeScalarOrEmpty}
    end

    properties (TaskInput)
        % Algorithm - Algorithm to use for obfuscating source files
        %
        %   Algorithm to use for obfuscating source files,
        %   specified as "R2022a" or "R2007b". By default, the task uses 
        %   the enhanced "R2022a" algorithm.
        Algorithm (1,1) string {mustBeMember(Algorithm, ["R2007b", "R2022a"])} = "R2022a"

        % PreserveSourceFolder - Whether to include specified source folders in the task output
        %
        %   Whether to include specified source folders in the task output,
        %   specified as a numeric or logical 0 (false) or 1 (true). If the value is 
        %   true, the task includes the specified source folders in addition to 
        %   their contents in the output folder structure. By
        %   default, the task includes only the contents of the specified
        %   source folders in the output folder structure.
        PreserveSourceFolder (1,1) logical
    end

    properties (TaskInput, Dependent, SetAccess = private, Hidden)
        % SourceFiles - Source files to obfuscate
        % 
        %   Source files to obfuscate, returned as a row vector of
        %   matlab.buildtool.io.FileCollection objects.
        SourceFiles (1,:) matlab.buildtool.io.FileCollection
    end

    properties (TaskOutput, Dependent, SetAccess = private)
        % PcodeFiles - P-code files to create
        % 
        %   P-code files to create, returned as
        %   a row vector of matlab.buildtool.io.FileCollection objects.
        PcodeFiles (1,:) matlab.buildtool.io.FileCollection
    end

    methods
        function task = PcodeTask(source, outputFolder, options)
            % PcodeTask - Class constructor
            %
            %   TASK = matlab.buildtool.tasks.PcodeTask(SOURCE,OUTPUTFOLDER)
            %   constructs a task that creates P-code files in OUTPUTFOLDER for 
            %   each file or folder in SOURCE.
            %
            %   TASK = matlab.buildtool.tasks.PcodeTask(SOURCE,OUTPUTFOLDER,Name=Value)
            %   creates a task with additional options specified by one or more of
            %   these name-value arguments:
            %
            %       * Algorithm            - Algorithm to use for obfuscating source files
            %       * PreserveSourceFolder - Whether to include specified source folders in the task output
            %
            %   Examples:
            %       
            %       % Import the PcodeTask class
            %       import matlab.buildtool.tasks.PcodeTask
            %
            %       % Create a task to obfuscate the contents of the src folder in place
            %       task = PcodeTask("src",pwd);
            %
            %       % Create a task to obfuscate a file in your current folder in place
            %       task = PcodeTask("myfile.m",pwd);
            %
            %       % Create a task to obfuscate the contents of the src folder and save 
            %       % the P-code files in the out folder while maintaining the folder structure
            %       task = PcodeTask("src","out");
            %
            %       % Create a task to obfuscate the contents of the src folder and
            %       % save the P-code files in the out folder without maintaining
            %       % the folder structure
            %       task = PcodeTask("src/**/*.m","out");
            %
            %       % Create a task to obfuscate the files in the src folder using a
            %       % legacy obfuscation algorithm
            %       task = PcodeTask("src","out",Algorithm="R2007b");
            %
            %       % Create a task to obfuscate the files in the src
            %       % folder and also include "src" in the output folder structure
            %       task = PcodeTask("src","out",PreserveSourceFolder=true);
            %

            arguments
                source (1,:) matlab.buildtool.io.FileCollection
                outputFolder (1,1) matlab.buildtool.io.File
                options.Algorithm (1,1) string {mustBeMember(options.Algorithm, ["R2007b", "R2022a"])}
                options.PreserveSourceFolder (1,1) logical = false
                options.Description (1,1) string = getDefaultDescription()
                options.Dependencies (1,:) string = string.empty(1,0)
            end

            task.Source = source;
            task.OutputFolder = outputFolder;

            for prop = string(fieldnames(options))'
                task.(prop) = options.(prop);
            end
        end

        function files = get.SourceFiles(task)
            import matlab.io.internal.glob;

            files = task.Source;

            % Expand all folders to find MATLAB source files
            files = files.transform(@expandFolders, AllowResizing=true);
            function paths = expandFolders(paths)
                index = isfolder(paths);
                folders = paths(index);

                cArray = arrayfun(@(f)glob(fullfile(f, "**", "*.m"))', folders, UniformOutput=false);
                folderFiles = string([cArray{:}]);

                paths = [paths(~index) folderFiles];
            end
        end

        function files = get.PcodeFiles(task)
            import matlab.io.internal.glob;

            files = task.Source;

            files = files.transform(@pfiles, AllowResizing=true);
            function paths = pfiles(paths)
                indices = isfolder(paths);
            
                [~,files] = fileparts(paths(~indices));

                cArray = arrayfun(@expandFolder, paths(indices), UniformOutput=false);
                folderFiles = string([cArray{:}]);

                [folders,names] = fileparts(folderFiles);
                folderFiles = fullfile(folders,names);
            
                paths = fullfile(task.OutputFolder.Path, [files folderFiles]+".p");

                function fs = expandFolder(f)
                    [~, attrs] = fileattrib(f);
                    f = attrs.Name;

                    fs = glob(fullfile("**", "*.m"), RootFolder=f)';
                    if task.PreserveSourceFolder
                        [~, par] = fileparts(f);
                        fs = fullfile(par, fs);
                    end
                end
            end
        end
    end

    methods (TaskAction, Sealed, Hidden)
        function pcodeFiles(task, ~)
            src = task.SourceFiles.absolutePaths();
            pfiles = task.PcodeFiles.absolutePaths();

            indices = contains(src, "..");
            if any(indices)
                error(message("MATLAB:buildtool:PcodeTask:DotDotSource", src(find(indices, 1, "first"))));
            end
            
            [~, ~, ext] = fileparts(src);
            indices = ~strcmpi(ext, ".m");


            if any(indices)
                error(message("MATLAB:buildtool:PcodeTask:NonMSource", src(find(indices, 1, "first"))));
            end

            workingDir = pwd();
            tempDir = tempname();

            cleanup = onCleanup(@()returnFromTempDir(tempDir, workingDir));
            mkdir(tempDir);
            cd(tempDir);

            for i = 1:numel(src)
                pcode(src(i), "-" + task.Algorithm);
                 
                pfile = pFileLocation(src(i));

                d = fileparts(pfiles(i));
                if ~isfolder(d)
                    mkdir(d);
                end

                movefile(pfile, pfiles(i));
            end

            function returnFromTempDir(tempDir, workingDir)
                cd(workingDir);
                rmdir(tempDir, "s");
            end
        end
    end
end

%% ------------------------------------------------------------------------

function desc = getDefaultDescription()
desc = getString(message("MATLAB:buildtool:PcodeTask:DefaultDescription"));
end

function p = pFileLocation(srcFile)
    [path, name] = fileparts(srcFile);
    p = name + ".p";

    % Grabs folders off of the path that match the possibilities below
    % and prepends them to the path name since calling pcode on for example
    % "+namespace/+subspace/file.m" creates the P-code file at
    % "+namespace/+subspace/file.p" rather than the usual "./file.p". 
    % Mixed cases such as "+namespace/normal/file.m" result in the
    % normal behavior of creating the P-code file "./file.p"
    while isSpecialFolder(path)
        [path, name] = fileparts(path);
        p = fullfile(name, p);
    end

    function tf = isSpecialFolder(path)
        [~, n] = fileparts(path);
        tf = startsWith(n, ["+", "@"]) || n == "private";
    end
end

% LocalWords:  Pcode myfile buildfile buildplan SourceFiles OUTPUTFOLDER
