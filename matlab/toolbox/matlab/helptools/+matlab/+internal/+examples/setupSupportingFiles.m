function metadata = setupSupportingFiles(metadata, workDir)
%

%   Copyright 2020-2023 The MathWorks, Inc.

    installed = matlab.internal.examples.isInstalled;

    zipWeb = [];
    if ~installed
        for i = 1:numel(metadata.project)
            project = metadata.project(i);
            if project.supported
                [filepath, name, ext] = fileparts(project.path);
                [componentDir, folder, ~] = fileparts(filepath);
                zipFile = strcat(name, ext);
                target = fullfile(fileparts(workDir), zipFile);
                matlab.internal.examples.copyFile(componentDir, folder, zipFile, target, false, false);
                zipWeb = [zipWeb, target];
                if isfield(project, "type") && strcmp(project.type,"main")
                    zipMain = target;
                end
            end
        end
    end

    for i = 1:numel(metadata.project)
        project = metadata.project(i);
        if project.supported
            if isfield(project, "type") && strcmp(project.type,"main")
                [~, projectName, ~] = fileparts(project.path);
                projectRoot = fullfile(workDir,projectName);
                if ~isfolder(projectRoot) 
                    if installed
                        zipMain = project.path;
                    end
                    if strlength(project.cmSystem)
                        [filepath,name,~] = fileparts(workDir);
                        RepositoryLocation = fullfile(filepath,"repositories",name);
                        projectRoot = matlab.internal.project.example.setup(zipMain,workDir, ...
                                      SourceControl=string(project.cmSystem), ...
                                      RepositoryLocation=RepositoryLocation);
                    else
                        projectRoot = matlab.internal.project.example.setup(zipMain,workDir);
                    end
                end
                metadata.project(i).root = projectRoot;
            end
        end
    end

    for i = 1:numel(zipWeb)
        delete(zipWeb(i));
    end

    for iFiles = 1:numel(metadata.files)
        f = metadata.files{iFiles};
        target = fullfile(workDir, f.filename);
        pattern = [".m", ".mdl", ".mlx", ".slx", ".sfx", ".sldd", ".mlapp"];
        folder = "data";
        if endsWith(f.filename, pattern)
            folder = "main";
            if ~isempty(f.mexFunction)
                [~, name, ~] = fileparts(f.filename);
                mexname = name + "_"  + f.mexFunction + "." + mexext;
                matlab.internal.examples.copyFile(f.componentDir, folder, mexname, fullfile(workDir, mexname), false, true);
            end
        end
        matlab.internal.examples.copyFile(f.componentDir, folder, f.filename, target, false, false);
    end

    for iDirs = 1:numel(metadata.dirs)
        subdir = metadata.dirs{iDirs};
        target = fullfile(workDir, subdir.dirname);
        matlab.internal.examples.copyFile(subdir.componentDir, "data", subdir.dirname, target, true, false);
    end

    metadata.workDir = workDir;   
end
