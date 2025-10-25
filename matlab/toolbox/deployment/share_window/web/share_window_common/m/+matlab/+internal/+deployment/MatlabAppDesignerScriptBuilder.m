 classdef MatlabAppDesignerScriptBuilder < matlab.internal.deployment.AppDesignerDeployScriptBuilder
    methods
        function obj = MatlabAppDesignerScriptBuilder(appPath, requiredFiles, appImages)
            obj@matlab.internal.deployment.AppDesignerDeployScriptBuilder(appPath, requiredFiles, appImages);
        end
    end 
    methods
        function script = getPackageScript(obj, appDetails)
            script = "";
            requiredAddons = "";
            [parentDir, appName, ~] = fileparts(obj.appPath);
            toolboxOutputFileName = append(appName, ".mltbx");
            % get all discovered requirements via dependency analysis
            requiredFilesAppsAndAddons = matlab.codetools.requiredFilesAndProducts(obj.appPath, 'toponly');
            % isolate required addons from discovered requirements list
            [reqAddons, topLevelFiles] = matlab.internal.deployment.getRequiredAddonInfo(requiredFilesAppsAndAddons);

            % append custom requirements to discovered requirements
            if (obj.requiredFiles ~= "") 
                files = [topLevelFiles, obj.requiredFiles'];
            else
                files = topLevelFiles;
            end
            createPackageOpts = append("packageOpts=matlab.addons.toolbox.ToolboxOptions(""", parentDir,""", """, matlab.lang.internal.uuid(), ...
                                                                       """, ToolboxFiles={""", strjoin(files, """, """), """});", "", newline);
            % toolbox name is the same as the app name
            toolboxName = append("packageOpts.ToolboxName = """, appDetails.Name, """;", newline);
            version = append("packageOpts.ToolboxVersion = """, appDetails.Version, """;", newline);
            author = append("packageOpts.AuthorName = """, appDetails.Author, """;", newline);
            summary = append("packageOpts.Summary = """, appDetails.Summary, """;", newline);
            description = append("packageOpts.Description = """, appDetails.Description, """;", newline);
            % create toolbox file list
            appGalleryFiles = append("packageOpts.AppGalleryFiles = {""", strjoin({obj.appPath}, """, """), """};", newline);

            % if there are required addons, add them too
            if numel(reqAddons)
                addonString = obj.convertStructToString(reqAddons);
                if ~strcmp(addonString, "")
                    requiredAddons = append("packageOpts.RequiredAddons = ", obj.convertStructToString(reqAddons), newline);
                end
            end

            paths = obj.getMatlabPathFoldersFromFiles(files);
            matlabPaths = append("packageOpts.ToolboxMatlabPath = {""", strjoin(paths, """, """), """};", newline);

            outputFile = append("packageOpts.OutputFile = """, fullfile(parentDir, 'release', toolboxOutputFileName), """;", newline);

            packageCommand = "matlab.addons.toolbox.packageToolbox(packageOpts);";
            beginBuildMessage = "disp(string(message(""compiler_ui_common:messages:beginBuildMLAPP"")));";
            endBuildMessage = "disp(string(message(""compiler_ui_common:messages:endBuildMLAPP"")));";
            script = append(beginBuildMessage, script, createPackageOpts, toolboxName, version, author, summary, description, appGalleryFiles, requiredAddons, matlabPaths, outputFile, packageCommand, endBuildMessage);
        end

       function structString = convertStructToString(obj, arrayOfStructs)
           names = {};
           ids = {};
           earliestVersions = {};
           latestVersions = {};
           downloadURLs = {};
           structString = "";

           for i = 1:numel(arrayOfStructs)
               currentStruct = arrayOfStructs{i};
               if ~currentStruct.InRepository
                  continue;
               end
        
               names{end+1}= string(currentStruct.Name);
               ids{end+1}= currentStruct.Identifier;
               downloadURLs{end+1}= "";
        
               versions = currentStruct.AvailableVersions;
               sortedVersions = sort(versions);
               earliestVersions{end+1}= sortedVersions(1);
               latestVersions{end+1}= sortedVersions(end);
            end

           if ~isempty(names) 
                nameLine = append("""Name"", {""", strjoin(string(names), """, "), """}");
                idLine = append("""Identifier"", {""", strjoin(string(ids), """, "), """}");
                eVersionLine = append("""EarliestVersion"", {""", strjoin(string(earliestVersions), """, "), """}");
                lVersionLine = append("""LatestVersion"", {""", strjoin(string(latestVersions), """, "), """}");
                urlLine = append("""DownloadURL"", {""", strjoin(string(downloadURLs), """, "), """}");
                
                structString = append("struct(", nameLine, ', ', idLine, ', ', eVersionLine, ', ', lVersionLine, ', ', urlLine, ");");
           end
        end

        function foldersContainingToolboxFiles = getMatlabPathFoldersFromFiles(obj, files)
            foldersContainingToolboxFiles = [];
            for i=1:numel(files)
                parentFolder = fileparts(files{i});
                if ~ismember(parentFolder, foldersContainingToolboxFiles)
                    foldersContainingToolboxFiles = [foldersContainingToolboxFiles string(parentFolder)];
                end
            end
        end
    end
end

