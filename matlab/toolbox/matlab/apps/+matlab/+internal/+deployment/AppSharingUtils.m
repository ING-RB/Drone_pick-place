classdef (Sealed, Abstract) AppSharingUtils
    %APPSHARINGUTILS Utility functions to assist in sharing a
    % web or desktop app.

    % Copyright 2017-2020 MathWorks, Inc.

    methods (Static)
        function handleCommonCompilerErrors(ex, prjFile)
            if (strcmp(ex.identifier,'MATLAB:Java:GenericException') && ...
                    isa(ex.ExceptionObject, 'java.io.FileNotFoundException'))
                error(message('MATLAB:appdesigner:appdesigner:CompileAppCompileFileNotFound', prjFile));
            elseif (strcmp(ex.identifier,'MATLAB:Java:GenericException') && ...
                    isa(ex.ExceptionObject, 'com.mathworks.deployment.services.ReadOnlyException'))
                error(message('MATLAB:appdesigner:appdesigner:CompileAppFolderNotWritable', prjFile));
            elseif (strcmp(ex.identifier,'compiler_ui:packagingDialog:ERROR_WRITING_LOG'))             
                openingTag=strcat('<a href="matlab:open(''', prjFile, ''')">');
                closingTag = '</a>';
                error(message('MATLAB:apps:errorcheck:LogFileIsNotWritable', openingTag, closingTag));
            else
                error(message('MATLAB:appdesigner:appdesigner:CompileAppFailed', prjFile));
            end
        end

        function newProjectName = removeNumbersFromStartOfProjectName(projectName)
            pattern = '^[0-9]+';
            newProjectName = projectName;
            [startIndex, endIndex] = regexp(newProjectName, pattern);
            newProjectName(startIndex:endIndex) = [];
        end

        function [projectName, projectKey] = createProjectWithUniqueFileName(filteredAppName, appFullFile, service)
            [appFilePath, appFileName] = fileparts(appFullFile);
            projectName = filteredAppName;

            % Set the .prj filename to be the same as the app's filename if the
            % filtered app name is empty
            if isempty(projectName)
                projectName = appFileName;
            end

            projectFullFile = fullfile(appFilePath, [projectName, '.prj']);
            originalProjectName = projectName;
            uniqueCounter = 0;
            foundUniqueProjectName = false;
            while ~foundUniqueProjectName
                try
                    % .createNewProject throws exception if filename conflict encountered
                    projectKey = service.createNewProject(appFilePath, [projectName, '.prj']);
                    service.save(projectKey);
                    foundUniqueProjectName = true;
                catch ex
                    if (strcmp(ex.identifier,'MATLAB:Java:GenericException') && ...
                            isa(ex.ExceptionObject, 'com.mathworks.deployment.services.NameCollisionException'))
                        % Name conflict with another .prj file. Append '_<int>' to name.
                        % Loop until a unique filename is found (e.g. App1_3.prj').
                        uniqueCounter = uniqueCounter + 1;
                        projectName = [originalProjectName '_' num2str(uniqueCounter)];
                    else
                        matlab.internal.deployment.AppSharingUtils.handleCommonCompilerErrors(ex, projectFullFile);
                    end
                end
            end
            
            % Appdesigner may allow file to be named without extension
            % This can happen when the save locaiton is path-visible
            % Thus we can use 'which' to get the extension (likely mlapp)
             [~,~,ext] = fileparts(appFullFile);
             if(isempty(ext))
                appFullFile = which(appFullFile);
             end
            service.addMainFile(projectKey, appFullFile);
        end

        function projectKey = openProject(service, projectFullFile)
            projectKey = service.openProject(projectFullFile);
        end

        function projectFullFile = saveAndCloseProject(service, projectKey)
            projectFullFile = service.getProjectFileLocation(projectKey);
            service.save(projectKey);
            service.closeProject(projectKey);
        end

        function showProject(service, projectFullFile)
            service.openProjectInGUIandRunAnalysis(projectFullFile);
        end

        function [assetsFolder, appHelperFolder, dependenciesList] = getSimulinkDashboardAssets(appFullFileName) 
            % R2024a support for Simulink Dashboard deployment
             % Initialize output variables
            assetsFolder = '';
            appHelperFolder = '';
            dependenciesList = '';
            fileReader = appdesigner.internal.serialization.FileReader(appFullFileName);
            appMetaData = fileReader.readAppMetadata();
            appName = strrep(appMetaData.Name,' ','_');

            % the appName_dependencies.mat file  is characteristic of deployed panels. 
            % checking for this file can confirm whether or not this is a deployed app
            if exist(fullfile(fileparts(appFullFileName), [appName '_dependencies.mat']), 'file') == 2
                assets = fullfile(fileparts(appFullFileName), [appName '_assets']);
                helper = fullfile(fileparts(appFullFileName),['+' appName]);
                dependencies = fullfile(fileparts(appFullFileName), [appName '_dependencies.mat']);
                if exist(assets, "dir")
                    assetsFolder = assets;
                end
                if exist(helper, "dir")
                    appHelperFolder = helper;
                end
                if exist(dependencies, "file")
                    list = matfile(dependencies);
                    dependenciesList = list.finalDepList;
                end
            end
        end

    end
end

