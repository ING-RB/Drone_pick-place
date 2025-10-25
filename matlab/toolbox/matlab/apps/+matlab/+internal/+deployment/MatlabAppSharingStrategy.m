%

% Copyright 2017-2020 MathWorks, Inc.
classdef MatlabAppSharingStrategy < matlab.internal.deployment.AppSharingStrategy
    methods (Access = protected)
        function [projectFullFile, projectKey] = createProjectWithUniqueFileName(obj, filteredAppName, appFullFile)
            [appFilePath, appFileName] = fileparts(appFullFile);

            prjFileName = filteredAppName;

            if isempty(filteredAppName)
                prjFileName = appFileName;
            end

            originalPrjFileName = prjFileName;
            foundUniquePrjName = false;
            uniqueCounter = 0;
            while ~foundUniquePrjName
                try
                    % .createAppsProject throws exception if filename conflict encountered
                    projectKey = obj.service.createAppsProject(appFilePath, prjFileName);

                    % The packaging API will strip illegal characters out of .prj
                    % filename, so API must be queried to determine what was used.
                    actualPrjFullFileName = obj.service.getProjectFileLocation(projectKey);
                    foundUniquePrjName = true;
                catch ex
                    if (strcmp(ex.identifier,'MATLAB:Java:GenericException') && ...
                            isa(ex.ExceptionObject, 'com.mathworks.deployment.services.NameCollisionException'))
                        % Name conflict with another .prj file. Append '_<int>' to name.
                        % Loop until a unique filename is found (e.g. App1_3.prj').
                        uniqueCounter = uniqueCounter + 1;
                        prjFileName = [originalPrjFileName '_' num2str(uniqueCounter)];
                    elseif (strcmp(ex.identifier,'MATLAB:Java:GenericException') && ...
                            isa(ex.ExceptionObject, 'java.io.FileNotFoundException'))
                        error(message('MATLAB:appdesigner:appdesigner:PackageAppPackageFileNotFound', appFullFile));
                    elseif (strcmp(ex.identifier,'MATLAB:Java:GenericException') && ...
                            isa(ex.ExceptionObject, 'com.mathworks.deployment.services.ReadOnlyException'))
                        error(message('MATLAB:appdesigner:appdesigner:PackageAppFolderNotWritable', appFullFile));
                    else
                        % Unknown error using packaging API
                        error(message('MATLAB:appdesigner:appdesigner:PackageAppFailed', appFullFile));
                    end
                end
            end

            projectFullFile = actualPrjFullFileName;
            % Save the .mlappinstall to the same directory as the .mlapp file.
            obj.service.setOutputFolder(projectKey, appFilePath);

            % Specify the .mlapp as the main file
            obj.service.addMainFile(projectKey, appFullFile);
        end

        function projectKey = openProject(obj, projectFullFile)
            projectKey = obj.service.openAppsProject(projectFullFile);
        end

        function populateProjectFields(obj, projectKey, appMetaData, imgFullFile)
            if ~isempty(appMetaData.Summary)
                obj.service.setSummary(projectKey, appMetaData.Summary);
            end

            if ~isempty(appMetaData.Description)
                obj.service.setDescription(projectKey, appMetaData.Description);
            end

            if ~isempty(appMetaData.Author)
                obj.service.setAuthorName(projectKey, appMetaData.Author);
            end

            if ~isempty(appMetaData.Version)
                obj.service.setVersion(projectKey, appMetaData.Version);
            end

            if ~isempty(imgFullFile)
                obj.service.setSplashScreen(projectKey, imgFullFile);
            end
        end

        function projectFullFile = saveAndCloseProject(obj, projectKey)
            projectFullFile = obj.service.getProjectFileLocation(projectKey);
            obj.service.closeProject(projectKey);
        end

        function showProject(obj, projectFullFile)
            obj.service.openProjectInGUIandRunAnalysis(projectFullFile);
        end
    end

    methods (Access = public)
        function showProjectWebUI(obj, appFullFileName)
            try
                matlabAppWindow = matlab.internal.deployment.MatlabAppPreviewWindow(appFullFileName);
                matlabAppWindow.launch();
            catch ex
                matlab.internal.deployment.AppSharingUtils.handleCommonCompilerErrors(ex, appFullFileName);
            end
        end
    end

    methods (Static, Access = protected)
        function service = getProjectService()
            service = com.mathworks.toolbox.apps.services.AppsPackagingService;
        end

        function chars = getInvalidCharactersForAppName()
            % Spaces are allowed in MATLAB app names.
            chars = '<>\\\\/?*:|\"';
        end
    end
end
