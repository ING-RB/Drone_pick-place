function packageFromOptions(toolboxOptions)

    arguments
        toolboxOptions matlab.addons.toolbox.ToolboxOptions
    end

    %error out if root is empty, we need it
    if (isempty(toolboxOptions.ToolboxFolder) || ~exist(toolboxOptions.ToolboxFolder,'dir'))
        %error message will eventually need to adapt to non prj-based projects
        error(message('MATLAB:toolbox_packaging:packaging:ToolboxRootNotFound',toolboxOptions.ToolboxFolder));
    end
    if isempty(toolboxOptions.ToolboxFiles)
        error(message("MATLAB:toolbox_packaging:packaging:NoToolboxFiles"));
    end

    tempFile = strcat(tempname, '.mltbx');
    cleanup = onCleanup(@()cleanUpTempFile(tempFile));

    %create the basic toolbox. Data will be added afterwards
    addonProperties.name = char(toolboxOptions.ToolboxName);
    addonProperties.version = char(toolboxOptions.ToolboxVersion);
    addonProperties.authorName = char(toolboxOptions.AuthorName);
    addonProperties.authorContact = char(toolboxOptions.AuthorEmail);
    addonProperties.authorOrganization = char(toolboxOptions.AuthorCompany);
    addonProperties.summary = char(toolboxOptions.Summary);
    addonProperties.description = char(toolboxOptions.Description);
    addonProperties.GUID = char(toolboxOptions.Identifier);
    addonProperties.type = 'MATLAB Toolbox';
    mlAddonCreate(tempFile, addonProperties);

    % Add mlappinstall files to the OPC metadata
    appInstallList = cellstr(toolboxOptions.ToolboxFiles(matches(toolboxOptions.ToolboxFiles, wildcardPattern + ".mlappinstall")));
    if ~isempty(appInstallList)
        mlAddonSetAppInstallList(tempFile, formatMLAPPINSTALLsForOPC(appInstallList, toolboxOptions.ToolboxFolder));
    end

    % find all toolbox files, format, then add to package
    toolboxFiles = cellstr(toolboxOptions.ToolboxFiles);

    % Identify files that were included in the toolboxFiles that no longer
    % exist.  Warn on those, error if the resulting set of toolbox files is
    % empty
    nonExistantFileIdx = logical(cellfun(@(x) ~exist(x, 'file'), toolboxFiles, 'UniformOutput', true));
    if all(nonExistantFileIdx)
        % No files to package - error
        error(message("MATLAB:toolbox_packaging:packaging:NoFilesExist"));
    elseif any(nonExistantFileIdx)
        warningFilesString = join(string(toolboxFiles(nonExistantFileIdx)),newline);
        warning(message("MATLAB:toolbox_packaging:packaging:FilesDoNotExistWarning", warningFilesString));
    end
    toolboxFiles = toolboxFiles(~nonExistantFileIdx);

    formattedToolboxFiles = cellfun(@(x)formatForOPCFileList(x, char(toolboxOptions.ToolboxFolder)), toolboxFiles, 'UniformOutput', false);

    % APP GALLERY
    % Create the desktoptoolset.xml file based on the files identified as
    % app entry points.  The file will be written to temp and put into the
    % file list in the OPC container to be zipped up.  The temp file will
    % then be deleted at the end of the workflow
    if ~exist(fullfile(toolboxOptions.ToolboxFolder, 'DesktopToolset.xml'),'file') && ...
        ~isempty(toolboxOptions.AppGalleryFiles)
        % Only create a desktop toolset on the fly if there isn't one in
        % the toolbox root already
        desktopToolsetFile = fullfile(tempname, 'DesktopToolset.xml');
        writeDesktopToolset(cellstr(toolboxOptions.AppGalleryFiles), desktopToolsetFile);
        % Add an oncleanup
        toolboxFiles{end+1} = desktopToolsetFile;
        formattedToolboxFiles{end+1} = 'DesktopToolset.xml';
    end

    % toolboxFiles contains both files and folders so split it here before
    % putting the lists into the OPC
    fileIndices = cellfun(@(x) isfile(x), toolboxFiles, "UniformOutput", true);
    % dir of empty folder gives back only "." and "..", this numel == 2
    emptyFolderIndices = cellfun(@(x) (isfolder(x) && numel(dir(x)) == 2), toolboxFiles, "UniformOutput", true);

    mlAddonAddFiles(tempFile, toolboxFiles(fileIndices), formattedToolboxFiles(fileIndices));

    mlAddonAddFolders(tempFile, formattedToolboxFiles(emptyFolderIndices));
    
    %SCREENSHOT
    screenshotPath = char(toolboxOptions.ToolboxImageFile);
    if(~isempty(screenshotPath))
        mlAddonSetScreenshot(tempFile, screenshotPath);
    end

    %MATLAB PATH
    matlabPaths = formatAllPathsForOPC(toolboxOptions.ToolboxMatlabPath, char(toolboxOptions.ToolboxFolder));
    if ~isempty(matlabPaths)
        mltbxConfiguration.matlabPaths = matlabPaths;
    end

    %JAVA CLASS PATH
    javaPaths = formatAllPathsForOPC(toolboxOptions.ToolboxJavaPath, char(toolboxOptions.ToolboxFolder));
    if ~isempty(matlabPaths)
        mltbxConfiguration.javaClassPaths = javaPaths;
    end

    tbxRootForPrune = strcat(char(toolboxOptions.ToolboxFolder), filesep);

    %DOCUMENTATION
    toolboxFilesCellStr = cellstr(toolboxOptions.ToolboxFiles);
    docPath = toolboxFilesCellStr(matches(toolboxFilesCellStr, wildcardPattern + "info.xml"));
    % TODO: Need to be robust to finding multiple info.xml files
    if ~isempty(docPath)
        mltbxConfiguration.infoXMLPath = formatSlahesForOPCPackage(pruneRootForOPCPackage(docPath{1}, tbxRootForPrune));
    end

    %GETTING STARTED GUIDE
    gsgPath = char(toolboxOptions.ToolboxGettingStartedGuide);
    if ~isempty(gsgPath)
        mltbxConfiguration.gettingStartedDocPath = formatSlahesForOPCPackage(pruneRootForOPCPackage(gsgPath, tbxRootForPrune));
    end

    if exist('mltbxConfiguration','var')
        mlAddonSetConfiguration(tempFile, mltbxConfiguration);
    end

    %SYSTEM REQUIREMENTS
    platforms.win = logicalToStr(toolboxOptions.SupportedPlatforms.Win64);
    platforms.linux = logicalToStr(toolboxOptions.SupportedPlatforms.Glnxa64);
    platforms.mac = logicalToStr(toolboxOptions.SupportedPlatforms.Maci64); % TODO: Maca64
    platforms.MATLABOnline = logicalToStr(toolboxOptions.SupportedPlatforms.MatlabOnline);
    mltbxSysRequirements.platformCompatibility = platforms;

    startRelease = char(toolboxOptions.MinimumMatlabRelease);
    if isempty(startRelease)
        startRelease = 'R2014b';
    end
    releaseCompatibilityStruct.start = startRelease;
    endRelease = char(toolboxOptions.MaximumMatlabRelease);
    if isempty(endRelease)
        endRelease = 'latest';
    end
    releaseCompatibilityStruct.end = endRelease;

    mltbxSysRequirements.releaseCompatibility = releaseCompatibilityStruct;
    mltbxSysRequirements.addonDependency = transformAddonDependencies(toolboxOptions.RequiredAddons);

    mlAddonSetSystemRequirements(tempFile, mltbxSysRequirements);

    if ~isempty(toolboxOptions.RequiredAdditionalSoftware)
        instructionSetFiles = {};
        for i=1:length(toolboxOptions.RequiredAdditionalSoftware)
            thisSoftware = toolboxOptions.RequiredAdditionalSoftware(i);
            % write the files
            instructionSetFiles{i} = writeInstructionSet(...
                char(thisSoftware.Name), ...
                char(thisSoftware.Platform), ...
                char(thisSoftware.DownloadURL), ...
                char(thisSoftware.LicenseURL)); %#ok<AGROW>
        end
        cellfun(@(x) mlAddonAddInstructionSet(tempFile, x), instructionSetFiles);
    end

    for j=1:length(toolboxOptions.RequiredAdditionalSoftware)
        instructionSetCleanup(j) = onCleanup(@()delete(instructionSetFiles{j})); %#ok<AGROW>
    end

    %SIGN TOOLBOX's SYSTEM REQUIREMENTS
    mlAddonSign(tempFile);

    % Reached the end without errors, move tempfile to outptutDir
    % Ensure the parent folder of OutputFile exists first
    outputParent = fileparts(toolboxOptions.OutputFile);
    if ~exist(outputParent, 'dir')
        mkdir(outputParent);
    end
    movefile(tempFile, toolboxOptions.OutputFile);
end

function relativePath = pruneRootForOPCPackage(path, toolboxFolder)
    arguments
        path char
        toolboxFolder char
    end
    relativePath = strrep(path, toolboxFolder, '');
    relativePath = strrep(relativePath,'\','/');
end

function path = formatSlahesForOPCPackage(path)
    if ispc
        %mostly for external files
        path = strrep(path, ':', '__');
        path = strrep(path, '\\', '');

        %change slashes for OPC
        path = strrep(path,'\','/');
    end
end

function cleanUpTempFile(tempFile)
    if exist(tempFile,'file')
        delete(tempFile)
    end
end

function includedApps = formatMLAPPINSTALLsForOPC(appFiles, toolboxFolder)

    if ~isempty(appFiles)
        includedApps = struct('name', [], 'guid', [], 'relativePath', [],  'installByDefault', []);
        for i = 1:length(appFiles)
            info = mlappinfo(appFiles{i});

            relativePath = strrep(appFiles{i}, toolboxFolder, '');
            relativePath = strrep(relativePath,'\','/');

            includedApps(i) = struct('name', char(info.name), ...
                'guid', char(info.GUID), ...
                'relativePath', char(relativePath), ...
                'installByDefault', 'true');

        end
    end
end

function requiredAddons = transformAddonDependencies(requiredAddons)

    if ~isempty(requiredAddons)
        for i=1:length(requiredAddons)
            [checksum, checksumVersion] = getChecksumForAddon(requiredAddons(i));
            requiredAddons(i).checksum = checksum;
            requiredAddons(i).checksumVersion = checksumVersion;
            % Field names for the options object are upper camel case, but
            % the fields for the OPC API are all lower, values also need to
            % be char
            requiredAddons(i).name = char(requiredAddons(i).Name);
            requiredAddons(i).downloadURL = char(requiredAddons(i).DownloadURL);
            requiredAddons(i).latestVersion = char(requiredAddons(i).LatestVersion);
            requiredAddons(i).earliestVersion = char(requiredAddons(i).EarliestVersion);
            requiredAddons(i).identifier = char(requiredAddons(i).Identifier);
        end
    end
end

function [checksum, checksumVersion] = getChecksumForAddon(addon)
    checksumVersion = '';
    url = char(addon.DownloadURL);
    if strlength(url) == 0
        [~, url, checksumVersion] = matlab.addons.repositories.SearchableAddonsRepositoryLocator.getAddOnDownloadURL(...
            char(addon.Name), char(addon.Identifier), char(addon.EarliestVersion), char(addon.LatestVersion));
    end

    outfilename = matlab.internal.addons.metadata.ToolboxConfigurationReader.getFileFromURL(url);
    %get checksum
    checksum = mlAddonComputeHash(outfilename);

    %delete the copied file
    delete(outfilename);
end

% The name of the instruction set file uses the convention  "<name>_<arch>.xml"
% to allow execution of platform specific commands.  _common is used for
% instruction sets to be used on all platforms
function outputLocation = writeInstructionSet(name, platform, url, licenseUrl)
    arguments
        name char
        platform char
        url char
        licenseUrl char
    end
    builderObj = matlab.addons.toolbox.internal.InstructionSetBuilder('extract');
    validName = matlab.lang.makeValidName(name);
    fileName = strcat(validName, '_', platform, '.xml');
    builderObj.DownloadUrl = url;
    builderObj.Archive = validName;
    builderObj.DisplayName = name;
    builderObj.LicenseUrl = licenseUrl;
    builderObj.DestinationFolderName = validName;

    outputFolder = tempdir;
    outputLocation = fullfile(outputFolder, fileName);
    builderObj.create(outputFolder, fileName);
end

function str = logicalToStr(logicalIn)
    if logicalIn
        str = 'true';
    else
        str = 'false';
    end
end

function writeDesktopToolset(apps, outputFile)

    % Ensure the output folder exists
    outputFolder = fileparts(outputFile);
    if ~exist(outputFolder,'dir')
        mkdir(outputFolder)
    end

    s.idAttribute = "user_apps_toolset";
    s.templateAttribute = "false";

    for i=1:length(apps)
        [~, appName, appExt] = fileparts(apps{i});
        if strcmp(appExt, '.mlapp')
            deserializer = appdesigner.internal.serialization.MLAPPDeserializer(apps{i}, {});
            appData = deserializer.getAppMetadata();
        else
            appData.Name = appName;
            appData.Uuid = char(matlab.lang.internal.uuid);
            appData.Summary = '';
            appData.Description = '';
        end

        [~, appFileName, appFileExt] = fileparts(apps{i});
        appFile = strcat(appFileName, appFileExt);
        thisTool.app_file_pathAttribute = appFile;
        thisTool.handler_classAttribute = "com.mathworks.deployment.desktop.toolstrip.ToolboxToolSetExtensionHandler";
        thisTool.idAttribute = strcat(appData.Uuid,":",appFile);
        thisTool.labelAttribute = appData.Name;
        thisTool.quick_access_eligibleAttribute = "false";
        thisTool.toolset_idAttribute = "user_apps_toolset";
        thisTool.callback = appFileName;
        thisTool.summary = appData.Summary;
        thisTool.description = appData.Description;

        iconStruct(1).filenameAttribute = "matlab_app_generic_icon_24";
        iconStruct(2).filenameAttribute = "matlab_app_generic_icon_16";
        iconStruct(1).idAttribute = "app";
        thisTool.icon = iconStruct;

        parent_tool.idAttribute = "my_apps";
        parent_tool.toolset_idAttribute = "apps_toolset";
        thisTool.parent_tool = parent_tool;

        toolStruct(i) = thisTool; %#ok<AGROW>
    end

    s.tool = toolStruct;
    writestruct(s, outputFile, "StructNodeName", "toolset");

end

function formattedToolboxFile = formatForOPCFileList(originalFilePath, rootToRemove)
    formattedPathForPackage = erase(originalFilePath, lineBoundary + rootToRemove);
    formattedPathForPackage = formatSlahesForOPCPackage(formattedPathForPackage);
    formattedToolboxFile = formattedPathForPackage;
end

function pathsOut = formatAllPathsForOPC(pathsIn, tbxFolder)
    pathsOut = cellstr(pathsIn);
    if ~isempty(pathsOut)
        formattedPaths = cellstr(formatForOPCFileList(pathsOut, tbxFolder));

        % Toolbox root should be expressed as '/'
        ind = cellfun(@(x)strlength(x)==0, formattedPaths, 'UniformOutput', true);
        if ind ~= 0
            formattedPaths{ind} = '/';
        end

        pathsOut = cellfun(@(x) formatSlahesForOPCPackage(x), formattedPaths, 'UniformOutput', 0 );  
    end
end
