classdef AppDesignerDeployScriptBuilder < handle
    properties
        appPath
        requiredFiles
        appImages
        outputFolder
    end

    methods
        function obj = AppDesignerDeployScriptBuilder(appPath, requiredFiles, appImages)
            obj.appPath = appPath;
            obj.requiredFiles = requiredFiles;
            obj.appImages = appImages;
            [parentDir, appName, ~] = fileparts(appPath);
            obj.outputFolder = fullfile(parentDir,  'release');
        end

        function script = getBuildScript(obj, appDetails)
            script = "";
            buildCreateCommand = obj.getBuildCreateCommand();
            commonLines = obj.getCommonBuildLines();
            customLines = obj.getCustomBuildLines(appDetails);
            buildEndCommand = obj.getBuildEndCommand();            
            script = append(script, buildCreateCommand, commonLines, customLines, buildEndCommand, newline);
        end
        
        function commands = getCommonBuildLines(obj)
            commands = "";
            reqFiles = "";
            if (obj.requiredFiles ~= "") 
                reqFiles = append("buildOpts.AdditionalFiles = [""", strjoin(obj.requiredFiles, """, """), """];", newline);
            end
            outputDir = append("buildOpts.OutputDir = """, fullfile(obj.outputFolder,"build"), """;", newline);
            verbosity = append("buildOpts.Verbose = true;", newline);
            commands = append(commands, reqFiles, outputDir, verbosity, newline);
        end
    end
end