classdef (Abstract) AppSharingStrategy < handle
    %APPSHARINGSTRATEGY Abstract class for ways an
    % App Designer app can be shared. Subclasses should
    % not be constructed directly but handed out by the
    % AppSharingStrategyFactory.
 
    % Copyright 2017-2024 MathWorks, Inc.
 
    properties (Access = protected)
        service
    end
 
    methods
        function share(obj, appFullFileName)
            % Removing the Java desktop version of share        
            obj.showProjectWebUI(appFullFileName);  
        end
    end
 
    methods (Abstract, Access = protected)
        [projectFullFile, projectKey] = createProjectWithUniqueFileName(obj, filteredAppName, appFullFile)
        projectKey = openProject(obj, projectFullFile)
        populateProjectFields(obj, projectKey, appMetaData, imgFullFile)
        projectFullFile = saveAndCloseProject(obj, projectKey)
        showProject(obj, projectFullFile)
    end
 
    methods (Access = private)
 
        function mostRecentPrjFullFileName = getMostRecentProjectFile(obj, appFullFile)
            % Find most recent .prj file in the same directory as the .mlapp file,
            % which has the Main File field set to the specified mlapp file.
 
            % Find all .prj files in the same directory as the .mlapp file
            % Returns struct array with name and datenum (double) fields
 
            [appFilePath, ~] = fileparts(appFullFile);
            prjFiles = dir(fullfile(appFilePath, '*.prj'));
 
            mostRecentPrjFullFileName = [];
            mostRecentPrjFileDatenum = 0;
            for file = prjFiles'
                if file.isdir
                    continue;
                end
                try
                    prjFullFileName = fullfile(appFilePath, file.name);
                    if obj.service.doesProjectContainMainFile(prjFullFileName, appFullFile)
                        if file.datenum > mostRecentPrjFileDatenum
                            mostRecentPrjFullFileName = fullfile(appFilePath, file.name);
                            mostRecentPrjFileDatenum = file.datenum;
                        end
                    end
                catch ex
                    % Unknown error using packaging API -> return generic PackageError
                    if isa(obj.service, 'com.mathworks.toolbox.apps.services.AppsPackagingService')
                        error(message('MATLAB:appdesigner:appdesigner:PackageAppFailed', appFullFile));
                    else
                        error(message('MATLAB:appdesigner:appdesigner:CompileAppFailed', appFullFile));
                    end
 
                end
            end
        end
    end
 
    methods (Access = public)
        function result = getFilteredAppName(obj, name)
            invalidChars = obj.getInvalidCharactersForAppName();
 
            if isempty(name)
                result = '';
            else
                result = '';
                for i = 1:length(name)
                    if ~contains(invalidChars,name(i)) && isASCII(name(i))
                        result = [result name(i)]; %#ok<AGROW>
                    end
                end
            end
            result = strtrim(result);
            if strlength(result) == 0
                result = 'App';
            end
 
            function value = isASCII(char)
                value = (double(char) < 128);
            end
 
        end
 
    end
 
    methods (Abstract, Static, Access = protected)
        service = getProjectService()
        invalidCharacters = getInvalidCharactersForAppName()
    end
end
