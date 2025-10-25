classdef ToolboxOptions
%MATLAB.ADDONS.TOOLBOX.TOOLBOXOPTIONS  Options for packaging toolbox
%
%    OPTS = MATLAB.ADDONS.TOOLBOX.TOOLBOXOPTIONS(PROJECTFILE)
%        creates a TOOLBOXOPTIONS object OPTS using the information
%        contained in PROJECTFILE. Specify PROJECTFILE as a relative or
%        absolute path to the toolbox project file (*.prj). OPTS is a
%        scalar matlab.addons.toolbox.ToolboxOptions object containing the
%        toolbox package options. OPTS is passed as an input to the
%        matlab.addons.toolbox.packageToolbox function.
%
%    OPTS = MATLAB.ADDONS.TOOLBOX.TOOLBOXOPTIONS(TOOLBOXFOLDER,IDENTIFIER)
%        creates a TOOLBOXOPTIONS object OPTS using the folder
%        TOOLBOXFOLDER and the unique identifier IDENTIFIER. TOOLBOXFOLDER
%        is a row character vector or a string scalar containing the path
%        to the folder being packaged as a toolbox. IDENTIFIER is a row
%        character vector or a string scalar containing the unique
%        identifier for the toolbox.
%
%    OPTS = MATLAB.ADDONS.TOOLBOX.TOOLBOXOPTIONS(TOOLBOXFOLDER,IDENTIFIER,NAME,VALUE)
%        specifies additional options using one or more name-value
%        arguments.
%
%
%    NAME-VALUE ARGUMENTS:
%
%    - ToolboxName (Row char vector or string scalar)
%        Name of the toolbox
%
%    - ToolboxVersion (Row char vector or string scalar)
%        Version number of the toolbox.
%
%    - Description (Row char vector or string scalar)
%        Detailed description of the toolbox.
%
%    - Summary (Row char vector or string scalar)
%        Summary description of the toolbox.
%
%    - AuthorName (Row char vector or string scalar)
%        Name of toolbox author.
%
%    - AuthorEmail (Row char vector or string scalar)
%        Email address of the toolbox author.
%
%    - AuthorCompany (Row char vector or string scalar)
%        Name of company that created the toolbox.
%
%    - ToolboxImageFile (Row char vector or string scalar)
%        Path to an image file used as the toolbox image.
%
%    - ToolboxFiles (Row char vector, string vector, or cellstr vector)
%        List of files to be packaged in the toolbox. Unless specified,
%        this list will contain all files under the TOOLBOXFOLDER.
%
%    - ToolboxMatlabPath (Row char vector, string vector, or cellstr vector)
%        List of folders to be added to the MATLAB path when the toolbox
%        is installed. Folders must contain at least one file from
%        ToolboxFiles to be valid toolbox path folders.
%
%    - AppGalleryFiles (Row char vector, string vector, or cellstr vector)
%        List of MATLAB executable files (.m, .mex, .mlx, .mlapp, .p) to be
%        added to the MATLAB App Gallery when the toolbox is installed.
%        Files must be included in the ToolboxFiles when the toolbox is
%        packaged.
%
%    - ToolboxGettingStartedGuide (Row char vector or string scalar)
%        Path to a MATLAB code file (.m, .mlx) to be opened at the end of
%        toolbox installation.  File must be included in the ToolboxFiles
%        when the toolbox is packaged.
%
%    - OutputFile (Row char vector or string scalar)
%        Path to the output toolbox file, specified as a relative or
%        absolute path. If the file does not have the extension .mltbx, it
%        will be appended automatically.
%
%    - MaximumMatlabRelease (Row char vector or string scalar)
%        Latest MATLAB release the toolbox is compatible with,
%        specified using the format 'RXXXXx', for example, 'R2022b'. If
%        there is no maximum restriction, specify the MaximumMatlabRelease
%        as empty ([]).
%
%    - MinimumMatlabRelease (Row char vector or string scalar)
%        Earliest MATLAB release the toolbox is compatible with,
%        specified using the format 'RXXXXx', for example, 'R2022b'. If
%        there is no minimum restriction, specify the MinimumMatlabRelease
%        as empty ([]).
%
%    - SupportedPlatforms (Scalar struct)
%        Compatibility flags for each platform that MATLAB supports.
%
%    - ToolboxJavaPath (Row char vector, string vector, or cellstr vector)
%        List of JAR files to be added to the Java classpath when the
%        toolbox is installed.
%
%    - RequiredAddons (Row struct vector)
%        List of required add-ons to be downloaded and installed during
%        toolbox installation.
%
%    - RequiredAdditionalSoftware (Row struct vector)
%        List of additional software packages to be downloaded during
%        toolbox installation.
%
%
%    EXAMPLES:
%
%    % Create a basic TOOLBOXOPTIONS object
%    opts = MATLAB.ADDONS.TOOLBOX.TOOLBOXOPTIONS( ...
%        pwd,'com-mathworks-guilayout')
%
%    % Create a TOOLBOXOPTIONS object with additional options specified as
%    % name-value arguments.
%    opts = MATLAB.ADDONS.TOOLBOX.TOOLBOXOPTIONS( ...
%        pwd,'com-mathworks-guilayout', ...
%        'ToolboxName', 'GUI Layout Toolbox', ...
%        'ToolboxVersion', '4.0');
%
%    % Create a TOOLBOXOPTIONS object with additional options specified
%    % using dot notation.
%    opts = MATLAB.ADDONS.TOOLBOX.TOOLBOXOPTIONS( ...
%        pwd,'com-mathworks-guilayout');
%    opts.ToolboxName = 'GUI Layout Toolbox';
%    opts.ToolboxVersion = '4.0';
%
%    See also matlab.addons.toolbox.packageToolbox, matlab.addons.install

%   Copyright 2022-2024 The MathWorks, Inc.
    properties
        AppGalleryFiles string = string.empty
        AuthorCompany string {mustBeTextScalar} = ""
        AuthorEmail string {mustBeTextScalar} = ""
        AuthorName string {mustBeTextScalar} = ""
        Description string {mustBeTextScalar} = ""
        OutputFile string {mustBeNonzeroLengthText} = "mytoolbox.mltbx"
        RequiredAdditionalSoftware struct = struct.empty
        RequiredAddons struct = struct.empty
        Summary string {mustBeTextScalar} = ""
        SupportedPlatforms = ...
            struct("Win64", true, "Glnxa64", true, "Maci64", true, "MatlabOnline", true)
        ToolboxGettingStartedGuide string {mustBeTextScalar} = ""
        ToolboxImageFile string {mustBeTextScalar} = ""
        ToolboxFiles string {mustBeNonzeroLengthText} = string.empty
        ToolboxJavaPath string = string.empty
        ToolboxMatlabPath string = string.empty
        ToolboxName string {mustBeNonzeroLengthText} = "My Toolbox"
        ToolboxVersion {mustBeTextScalar, mustBeNonzeroLengthText} = "1.0.0"
    end

    properties (Dependent)
        MinimumMatlabRelease (1,1) string
        MaximumMatlabRelease (1,1) string
    end

    properties (SetAccess = immutable)
        Identifier (1,1) string
        ToolboxFolder (1,1) string
    end

    properties (Access = private)
        MatlabReleaseTuple (2,1) string = ["", ""]
    end

    properties (Access = private, Constant)
        ADDITIONAL_SOFTWARE_FIELDS = ["Name","Platform","DownloadURL","LicenseURL"]
        ADDITIONAL_SOFTWARE_PLATFORM_FIELDS = ["win64","glnxa64","maca64","maci64"]
        DEFAULT_FILE_EXCLUSIONS = [ ...
                "**/resources/project/**/*"; ...
                "**/*.prj"; ...
                "**/.git/**/*"; ...
                "**/.svn/**/*"; ...
                "**/.buildtool/**/*"; ...
                "**/*.asv" ...
                ];
        PLATFORM_SUPPORTS_FIELDS = ["Win64","Glnxa64","Maci64","MatlabOnline"]
        REQUIRED_ADDONS_FIELDS = ["Name","Identifier","EarliestVersion","LatestVersion","DownloadURL"]
        SUPPORTED_GS_EXTENSIONS = [".m",".mlx"]
        SUPPORTED_APP_GALLERY_EXTENSIONS = [mexext("all").ext, ".m",".p",".mlx",".mlapp"]
        SUPPORTED_IMAGE_EXTENSIONS = [".jpg",".jpeg",".bmp",".png",".gif"]
    end

    methods
        function obj = ToolboxOptions(path, identifier, varargin)
            narginchk(1,inf);

            mustBeTextScalar(path)
            if strlength(path) == 0
                error(message("MATLAB:toolbox_packaging:packaging:ToolboxPathCannotBeEmpty"))
            end

            absolutePath = matlab.internal.deployment.makePathAbsolute(path);
            if nargin == 1
                % path must be a toolbox packaging PRJ file
                if isfolder(absolutePath)
                    error(message("MATLAB:toolbox_packaging:packaging:ToolboxIdentifierMissing"))
                end

                % Check if the PRJ is a Project containing a Toolbox
                % definition
                proj = [];
                config = [];
                try
                    proj = matlab.internal.project.api.makeProjectAvailable(absolutePath);
                    %if nargin == 2
                    config = compiler.project.internal.getSingleToolboxConfiguration(proj);
                    %else
                    %    config = compiler.project.getToolboxConfiguration(proj, taskName);
                    %end
                    
                catch e
                    % This was not a project PRJ, so proceed assuming it is
                    % a toolbox one

                    if strcmp(e.identifier, 'deployment:exception:NO_TOOLBOX_TASK')
                        throw e;
                    end
                    % if e.Identifier is NOTOOLBOXTASK then this was
                    % a project without a toolbox defined so we should
                    % rethrow that error.  Anything else should be
                    % swallowed because it was not a project.
                end

                if ~isempty(config)
                    obj.Identifier = config.Identifier;
                    if strlength(config.ToolboxFolder) == 0
                        error(message("MATLAB:toolbox_packaging:packaging:RootNotDefinedInPRJ", absolutePath))
                    end
                    obj.ToolboxFolder = fullfile(proj.RootFolder, config.ToolboxFolder);
                    obj = obj.initializeFromProject(proj, config);
                else

                    % Wasn't a project PRJ, try loading as a toolbox PRJ
    
                    prjStruct = matlab.addons.toolbox.ToolboxOptions.readPRJStruct(absolutePath);
    
                    if isstruct(prjStruct.fileset_rootdir)
                        obj.ToolboxFolder = prjStruct.fileset_rootdir.file;
                    else
                        % Root is not defined in PRJ, error
                       error(message("MATLAB:toolbox_packaging:packaging:RootNotDefinedInPRJ", absolutePath))
                    end
                    mustBeValidIdentifier(prjStruct.param_guid)
                    obj.Identifier = prjStruct.param_guid;
                    obj = obj.initializeFromPRJ(prjStruct);
                end
                
            else
                % path cannot be a PRJ file
                if isfile(absolutePath)
                    error(message("MATLAB:toolbox_packaging:packaging:ToolboxPRJAdditionalArguments"))
                end

                % Path is to the toolbox folder
                obj.ToolboxFolder = absolutePath;
                %error out if root is empty, we need it
                if ~exist(obj.ToolboxFolder,"dir")
                    %error message will eventually need to adapt to non prj-based projects
                    error(message("MATLAB:toolbox_packaging:packaging:ToolboxRootNotFound",obj.ToolboxFolder))
                end

                mustBeValidIdentifier(identifier)
                obj.Identifier = identifier;

                p = inputParser;
                allprops = properties(obj);
                for n = 1:numel(allprops)
                    addParameter(p,allprops{n},obj.(allprops{n}))
                end
                parse(p,varargin{:})
                changedprops = setdiff(allprops,p.UsingDefaults);

                if any(strcmp(changedprops,"Identifier"))
                    error(message("MATLAB:class:SetProhibited","Identifier",class(obj)))
                end
                if any(strcmp(changedprops,"ToolboxFolder"))
                    error(message("MATLAB:class:SetProhibited","ToolboxFolder",class(obj)))
                end
                if ~any(strcmp(changedprops,"ToolboxName"))
                    % We will derive the default toolbox name from the
                    % toolbox folder name
                    [~, name] = fileparts(obj.ToolboxFolder);
                    obj.ToolboxName = name;
                end 
                
                if any(strcmp(changedprops, "ToolboxFiles"))
                    % Apply the ToolboxFiles change now because many of the
                    % other N/V pairs depend on this being set first
                    obj.ToolboxFiles = p.Results.ToolboxFiles;
                else
                    % If an explicit list was not provided, then generate
                    % one by including all files under the root folder
                    fileList = deriveFilesFromRoot(obj);
                    obj.ToolboxFiles = fileList;

                    % Use the derived matlab path IFF ToolboxFiles is also
                    % derived
                    if ~any(strcmp(changedprops, "ToolboxMatlabPath"))
                        obj.ToolboxMatlabPath = pruneInvalidPathEntries(obj, deriveMatlabPathFromRoot(obj));
                    end
                end

                if ~any(strcmp(changedprops, "OutputFile"))
                    [parentFolder, mltbxName] = fileparts(obj.ToolboxFolder);
                    obj.OutputFile = fullfile(parentFolder, mltbxName);
                end

                if matlab.internal.feature("mpm") && exist(fullfile(path,"resources","mpackage.json"), 'file')
                    % Initialize various fields based off the content in
                    % the package definition when one exists
                    obj = obj.initializeFromPackageDefinition(changedprops);
                end

                % Apply all N/V pairs other than ToolboxFiles, which was
                % applied earlier
                for n = 1:numel(changedprops)
                    if ~strcmp("ToolboxFiles", changedprops{n})
                        obj.(changedprops{n}) = p.Results.(changedprops{n});
                    end
                end
            end
        end

        function obj = set.ToolboxImageFile(obj, screenshot)
            if strlength(screenshot) == 0
                obj.ToolboxImageFile = "";
            else
                mustBeFile(screenshot)
                [~,~,screenshotExtension] = fileparts(screenshot);
                if ~any(strcmpi(obj.SUPPORTED_IMAGE_EXTENSIONS, screenshotExtension))
                    error(message("MATLAB:toolbox_packaging:packaging:InvalidToolboxImageFileFormat", screenshot))
                end
                try
                    info = imfinfo(screenshot);
                catch
                    error(message("MATLAB:toolbox_packaging:packaging:InvalidToolboxImageFile", screenshot))
                end
                imFormat = info(1).Format;
                if isscalar(info) && strcmpi(imFormat,"gif")
                    error(message("MATLAB:toolbox_packaging:packaging:AnimatedGif"))
                end
                % Check the format again here because the extension may not
                % match the actual image format
                if ~any(strcmpi(obj.SUPPORTED_IMAGE_EXTENSIONS, strcat(".",imFormat)))
                    error(message("MATLAB:toolbox_packaging:packaging:InvalidToolboxImageFileFormat", screenshot))
                end
                obj.ToolboxImageFile = matlab.internal.deployment.makePathAbsolute(screenshot);
            end
        end

        function obj = set.ToolboxGettingStartedGuide(obj, gsGuide)
            if strlength(gsGuide) == 0
                obj.ToolboxGettingStartedGuide = "";
            else
                % Need to verify that the file can be opened in the editor
                [~,~,gsGuideExtension] = fileparts(gsGuide);
                if any(strcmpi(obj.SUPPORTED_GS_EXTENSIONS, gsGuideExtension))
                    obj.mustExistInPackageList(gsGuide)
                    obj.ToolboxGettingStartedGuide = matlab.internal.deployment.makePathAbsolute(gsGuide);
                else
                    error(message("MATLAB:toolbox_packaging:packaging:InvalidGettingStarted", gsGuide));
                end
            end
         end

        function minRelease = get.MinimumMatlabRelease(obj)
            minRelease = obj.MatlabReleaseTuple(1);
        end

        function maxRelease = get.MaximumMatlabRelease(obj)
            maxRelease = obj.MatlabReleaseTuple(2);
        end

        function obj = set.MaximumMatlabRelease(obj, maximumMatlabRelease)
            arguments
                obj (1,1) matlab.addons.toolbox.ToolboxOptions
                maximumMatlabRelease (1,1) string
            end

            if strlength(maximumMatlabRelease) == 0
                % Always valid to empty the string
                obj.MatlabReleaseTuple(2) = "";
            else
                % Must match a release string in the range of R2014b -
                % current release and be >= minimum release
                if ~isValidReleaseString(maximumMatlabRelease)
                    error(message("MATLAB:toolbox_packaging:packaging:InvalidReleaseString"));
                end

                newTuple = obj.MatlabReleaseTuple;
                newTuple(2) = strrep(lower(maximumMatlabRelease), "r", "R");
                if isValidReleaseTuple(newTuple)
                    obj.MatlabReleaseTuple = newTuple;
                else
                    if strlength(newTuple(1)) == 0
                        minReleaseForError = "R2014b";
                    else
                        minReleaseForError = newTuple(1);
                    end
                    error(message("MATLAB:toolbox_packaging:packaging:InvalidMaximumRelease",...
                        minReleaseForError, matlabRelease.Release));
                end
            end
        end

        function obj = set.MinimumMatlabRelease(obj, minimumMatlabRelease)
            arguments
                obj (1,1) matlab.addons.toolbox.ToolboxOptions
                minimumMatlabRelease (1,1) string
            end

            if strlength(minimumMatlabRelease) == 0
                obj.MatlabReleaseTuple(1) = "";
            else
                % Must match a release string in the range of R2014b -
                % current release and be <= maximum release
                if ~isValidReleaseString(minimumMatlabRelease)
                    error(message("MATLAB:toolbox_packaging:packaging:InvalidReleaseString"));
                end

                newTuple = obj.MatlabReleaseTuple;
                newTuple(1) = strrep(lower(minimumMatlabRelease), "r", "R");
                if isValidReleaseTuple(newTuple)
                    obj.MatlabReleaseTuple = newTuple;
                else
                    if strlength(newTuple(2)) == 0
                        maxReleaseForError = matlabRelease.Release;
                    else
                        maxReleaseForError = newTuple(2);
                    end
                    error(message("MATLAB:toolbox_packaging:packaging:InvalidMinimumRelease",...
                        maxReleaseForError));
                end
            end
        end

        function obj = set.ToolboxName(obj, toolboxName)
            toolboxName = strip(toolboxName);
            mustBeNonzeroLengthText(toolboxName);

            noBadToolboxNameCharacters(toolboxName,"ToolboxName");
            obj.ToolboxName = toolboxName;
        end

        function obj = set.OutputFile(obj, outputFile)

            noBadFolderCharacters(outputFile,"OutputDir");

            absolutePath = matlab.internal.deployment.makePathAbsolute(outputFile);
            [~,~,ext] = fileparts(absolutePath);
            if ~strcmpi(ext,".mltbx")
                absolutePath = strcat(absolutePath,".mltbx");
            end

            obj.OutputFile = absolutePath;
        end

        function obj = set.ToolboxVersion(obj, version)

            versionArray = split(version,".");
            if length(versionArray) < 2 || length(versionArray) > 4
                invalid = true;
            else
                versionDoubles = str2double(versionArray);
                % Only accept positive whole numbers
                invalid = any(or(isnan(versionDoubles), versionDoubles < 0)) || ...
                    ~isreal(versionDoubles);
            end
            if invalid
                error(message("MATLAB:toolbox_packaging:packaging:InvalidToolboxVersion",version))
            end
            obj.ToolboxVersion = string(version);
        end

        function obj = set.SupportedPlatforms(obj, platform)

            expectedFields = obj.PLATFORM_SUPPORTS_FIELDS;

            if ~isstruct(platform) || isempty(platform)
                error(message("MATLAB:toolbox_packaging:packaging:InvalidSupportedPlatforms"));
            end

            verifyRequiredFields("SupportedPlatforms", platform, expectedFields);

            try
                for i=1:length(expectedFields)
                    % Each field must be convertable to a scalar logical
                    thisValue = platform.(expectedFields(i));
                    mustBeNonempty(thisValue);
                    mustBeNumericOrLogical(thisValue);
                    platform.(expectedFields(i)) = logical(thisValue);
                end
            catch e
                error(message("MATLAB:toolbox_packaging:packaging:InvalidSupportedPlatforms"));
            end

            obj.SupportedPlatforms = removeExtraFieldsFromStruct("SupportedPlatforms", platform, expectedFields);

        end

        function obj = set.RequiredAdditionalSoftware(obj, RequiredAdditionalSoftware)

            if isempty(RequiredAdditionalSoftware)
                obj.RequiredAdditionalSoftware = struct.empty;
            else

                expectedFields = obj.ADDITIONAL_SOFTWARE_FIELDS;

                if ~isstruct(RequiredAdditionalSoftware)
                    error(message("MATLAB:toolbox_packaging:packaging:InvalidRequiredAdditionalSoftware"));
                end
                verifyRequiredFields("RequiredAdditionalSoftware", RequiredAdditionalSoftware, expectedFields);

                % Make it a column vector!
                RequiredAdditionalSoftware = RequiredAdditionalSoftware(:);

                try
                    for i=1:length(RequiredAdditionalSoftware)
                        % Each field must be char
                        for j=1:length(expectedFields)
                            thisField = RequiredAdditionalSoftware(i).(expectedFields(j));
                            mustBeNonzeroLengthText(thisField);
                            mustBeTextScalar(thisField);
                            RequiredAdditionalSoftware(i).(expectedFields(j)) = string(thisField);
                        end
                    end
                catch e
                    error(message("MATLAB:toolbox_packaging:packaging:InvalidRequiredAdditionalSoftware"));
                end
                allPlatforms = RequiredAdditionalSoftware.Platform;
                for i=1:length(allPlatforms)
                    if ~any(contains(obj.ADDITIONAL_SOFTWARE_PLATFORM_FIELDS, allPlatforms(i)))
                        error(message("MATLAB:toolbox_packaging:packaging:InvalidRequiredAdditionalSoftwarePlatform", allPlatforms{i}));
                    end
                end

                obj.RequiredAdditionalSoftware = removeExtraFieldsFromStruct( ...
                    "RequiredAdditionalSoftware", RequiredAdditionalSoftware, obj.ADDITIONAL_SOFTWARE_FIELDS);
            end
        end

        function obj = set.RequiredAddons(obj, requiredAddons)

            if isempty(requiredAddons)
                obj.RequiredAddons = struct.empty;
            else

                expectedFields = obj.REQUIRED_ADDONS_FIELDS;

                if ~isstruct(requiredAddons)
                    error(message("MATLAB:toolbox_packaging:packaging:InvalidRequiredAddons"));
                end

                verifyRequiredFields("RequiredAddons", requiredAddons, expectedFields);

                % Make it a column vector!
                requiredAddons = requiredAddons(:);

                try
                    for i=1:length(requiredAddons)
                        % Each field must be char
                        for j=1:length(expectedFields)
                            % downloadURL is allowed to be empty
                            thisVal = requiredAddons(i).(expectedFields(j));
                            if strcmp(expectedFields(j), "DownloadURL")
                                mustBeTextScalar(thisVal)
                            else
                                mustBeNonzeroLengthText(thisVal)
                                mustBeTextScalar(thisVal)
                            end
                            requiredAddons(i).(expectedFields(j)) = string(thisVal);
                        end
                    end
                catch e
                    error(message("MATLAB:toolbox_packaging:packaging:InvalidRequiredAddons"));
                end

                obj.RequiredAddons = removeExtraFieldsFromStruct(...
                    "requiredAddons", requiredAddons, obj.REQUIRED_ADDONS_FIELDS);
            end
        end

        function obj = set.ToolboxFiles(obj, ToolboxFiles)

            if isempty(ToolboxFiles)
                error(message("MATLAB:toolbox_packaging:packaging:ToolboxFolderCannotBeEmpty"))
            end

            sortedFiles = unique(arrayfun(@(x)matlab.internal.deployment.makePathAbsolute(x), ToolboxFiles));

            filesToSet = string.empty;

            for i=1:length(sortedFiles)
                if ~exist(sortedFiles(i),'file')
                    error(message("MATLAB:toolbox_packaging:packaging:FileMustExist", sortedFiles(i)))
                end

                if exist(sortedFiles(i),'dir')
                    % Expand this folder and include all of the files
                    % inside it
                    newFiles = getAllFilesUnderFolder(sortedFiles(i));
                    filesToSet = [filesToSet(:);newFiles(:)];
                else
                    filesToSet(end+1) = sortedFiles(i); %#ok<AGROW>
                end
            end

            obj.ToolboxFiles = unique(filesToSet(:));
        end

        function obj = set.AppGalleryFiles(obj, appGalleryFiles)
            if isempty(appGalleryFiles) || ...
                    (isstring(appGalleryFiles) && isscalar(appGalleryFiles) && strlength(appGalleryFiles) == 0)
                obj.AppGalleryFiles = string.empty;
                return
            end

            sortedFiles = unique(appGalleryFiles);

            % Must be a valid MATLAB file
            for i=1:length(sortedFiles)
                [~,~,ext] = fileparts(sortedFiles(i));
                if ~any(strcmpi(obj.SUPPORTED_APP_GALLERY_EXTENSIONS, ext))
                    error(message("MATLAB:toolbox_packaging:packaging:InvalidAppGalleryFile", sortedFiles(i)));
                end
                if ~exist(sortedFiles(i),'file')
                    error(message("MATLAB:toolbox_packaging:packaging:FileMustExist", sortedFiles(i)))
                end
                sortedFiles(i) = matlab.internal.deployment.makePathAbsolute(sortedFiles(i));
                obj.mustExistInPackageList(sortedFiles(i));
            end

            % Make it a column vector!
            obj.AppGalleryFiles = sortedFiles(:);
        end

        function obj = set.ToolboxJavaPath(obj, toolboxJavaPath)
            if isempty(toolboxJavaPath) || ...
                    (isstring(toolboxJavaPath) && isscalar(toolboxJavaPath) && strlength(toolboxJavaPath) == 0)
                obj.ToolboxJavaPath = string.empty;
                return
            end

            sortedFiles = unique(toolboxJavaPath);

            % Must be a valid JAR file
            for i=1:length(sortedFiles)
                [~,~,ext] = fileparts(sortedFiles(i));
                if ~any(strcmpi(".jar", ext))
                    error(message("MATLAB:toolbox_packaging:packaging:InvalidJARFile", sortedFiles(i)));
                end
                if ~exist(sortedFiles(i),'file')
                    error(message("MATLAB:toolbox_packaging:packaging:FileMustExist", sortedFiles(i)))
                end
                sortedFiles(i) = matlab.internal.deployment.makePathAbsolute(sortedFiles(i));
                obj.mustExistInPackageList(sortedFiles(i));
            end

            % Make it a column vector!
            obj.ToolboxJavaPath = sortedFiles(:);
        end

        function obj = set.ToolboxMatlabPath(obj, toolboxMatlabPath)

            if isempty(toolboxMatlabPath) || ...
                    (isstring(toolboxMatlabPath) && isscalar(toolboxMatlabPath) && strlength(toolboxMatlabPath) == 0)
                obj.ToolboxMatlabPath = string.empty;
                return
            end

            sortedFiles = unique(toolboxMatlabPath);
            absFiles = sortedFiles;

            % For each folder in cell str, there must be at least one file
            % inside it included in the ToolboxFiles
            % Alternatively, a package folder can exist in the MATLAB path
            % if there is a file inside that is being packaged
            for i=1:length(sortedFiles)
                mustNotBeReservedFolderName(sortedFiles(i));
                obj.mustExistInPackageListAsParentFolder(sortedFiles(i));
                absFiles(i) = matlab.internal.deployment.makePathAbsolute(sortedFiles(i));
            end

            % Make it a column vector!
            obj.ToolboxMatlabPath = absFiles(:);
        end

    end

    methods (Access = private, Static)

        % True if versionOne >= versionTwo
        % versions of the format [year][a|b]
        function isGOE = releaseIsGreaterOrEqual(versionOne, versionTwo)
            arguments
                versionOne char
                versionTwo char
            end

            if strcmpi(versionOne, versionTwo)
                isGOE = true;
            else

                versionOneLetter = versionOne(5);
                versionOneYear = str2double(versionOne(1:4));
                versionTwoYear = str2double(versionTwo(1:4));

                isGOE = versionOneYear > versionTwoYear || ...
                    (versionOneYear == versionTwoYear && strcmpi(versionOneLetter, "b"));
            end
        end

        % Uses readstruct in import the XML fdata from an old style deployment PRJ
        % and replaces all occurances of the PROJECT_ROOT macro
        function prjStruct = readPRJStruct(prjFileIn)

            [f, name, ext] = fileparts(prjFileIn);

            f = matlab.internal.deployment.makePathAbsolute(f);

            if strlength(ext) == 0
                % Name only so use '.prj'
                ext = ".prj";
            end
            prjFile = fullfile(f, strcat(name,ext));

            try
                prjStruct = readstruct(prjFile, "FileType", "xml", "DetectTypes", 0).configuration;
            catch
                % Unexpected PRJ format.  Perhaps not an XML, could be a
                % Projects one, etc.
                error(message("MATLAB:toolbox_packaging:packaging:NotValidToolboxPRJ"))
            end

            if ~strcmp(prjStruct.targetAttribute, "target.toolbox")
                error(message("MATLAB:toolbox_packaging:packaging:NotValidToolboxPRJ"))
            end

            % Remove the PROJECT_PATH macro from the struct
            projectRoot = fileparts(prjFile);
            if isempty(projectRoot)
                % The PRJ was passed in as a file name only, so the project root
                % should be "."
                projectRoot = ".";
            else
                projectRoot = string(projectRoot);
            end

            prjStruct = resolvePRJPathInStruct(prjStruct);

            % Replace all occurences of PROJECT_ROOT macro and unify filesep
            function pstruct = resolvePRJPathInStruct(pstruct)
                fields = fieldnames(pstruct);
                for j=1:length(pstruct)
                    for i=1:length(fields)
                        val = pstruct(j).(fields{i});
                        % Due to the structure of the PRJ and the behaviro of
                        % readstruct, sometimes these nested structs come across as
                        % sparse struct arrays.  In those cases there are a number
                        % of missing elements that we should just skip over
                        if ~isa(pstruct(j).(fields{i}),"missing")
                            if isstruct(val)
                                pstruct(j).(fields{i}) = resolvePRJPathInStruct(val);
                            else
                                % We need to make sure that we don't break the
                                % closing tag on XML since there are multiple
                                % places that we insert XML in as a param value

                                pstruct(j).(fields{i}) = ...
                                    strrep(strrep(strrep(strrep(strrep(val,"${MATLAB_ROOT}",matlabroot),"${PROJECT_ROOT}", projectRoot),"\",filesep),"/",filesep),"\>","/>");
                            end
                        end
                    end
                end
            end
        end
    end

    methods (Access = private)

        % Process the toolbox task (config)
        function obj = initializeFromProject(obj, proj, config)
            obj.ToolboxName = config.ToolboxName;

            % Need to derive files to package from dir
            obj.ToolboxFiles = deriveFilesFromRoot(obj);

            mp = deriveMatlabPathFromRoot(obj);

            % Remove paths that are in the exclusion list from the PRJ
            if ~isempty(config.ToolboxMatlabPathExclusions)
                theItems = config.ToolboxMatlabPathExclusions;
                theItems = strcat(obj.ToolboxFolder,theItems);
                for j=1:length(theItems)
                    thisPathEntry = matlab.internal.deployment.makePathAbsolute(theItems(j));
                    mp(strcmp(mp,thisPathEntry)) = [];
                end
            end

            obj.ToolboxMatlabPath = pruneInvalidPathEntries(obj, mp);

            obj.ToolboxVersion = config.ToolboxVersion;
            obj.AuthorName = config.AuthorName;
            obj.AuthorEmail = config.AuthorEmail;
            obj.AuthorCompany = config.AuthorOrganization;
            obj.Summary = config.Summary;
            obj.Description = config.Description;
            obj.OutputFile = fullfile(proj.RootFolder, config.OutputFolder, config.OutputFileName);
            obj.AppGalleryFiles = config.AppGalleryFileList;
            obj.ToolboxImageFile = config.ToolboxImageFile;
            obj.ToolboxGettingStartedGuide = config.GettingStartedGuide;
            if ~isempty(config.ToolboxJavaPath)
                obj.ToolboxJavaPath = fullfile(obj.ToolboxFolder, config.ToolboxJavaPath);
            end

            plat = config.SupportedPlatforms;
            obj.SupportedPlatforms = struct( ...
                "Win64", any(plat == deployment.toolbox.model.Platform.Windows), ...
                "Glnxa64", any(plat == deployment.toolbox.model.Platform.Linux), ...
                "Maci64", any(plat == deployment.toolbox.model.Platform.Mac), ...
                "MatlabOnline", any(plat == deployment.toolbox.model.Platform.MatlabOnline));

            obj.MinimumMatlabRelease = config.MinRelease;
            obj.MaximumMatlabRelease = config.MaxRelease;
    
            requiredAdditionalSoftware = config.RequiredAdditionalSoftware;

            % Have to explode the platform array for each 3p addon
            % into it's own copy of the 3p addon struct to conform
            % to toolbox options spec
            formattedRequiredAdditionSoftware = struct("Name", {}, "Platform", {}, "DownloadURL", {}, "LicenseURL", {});
            for rasIndex = 1:length(requiredAdditionalSoftware)
                currentRas = requiredAdditionalSoftware(rasIndex);

                % Also have to map our convention of Windows,
                % Linux, Mac to win64, glnxa64 and maci64+maca64
                platformMap = containers.Map();
                platformMap("Windows") = {"win64"};
                platformMap("Linux") = {"glnxa64"};
                platformMap("Mac") = {"maci64", "maca64"};
                for platformIdx = 1:length(currentRas.Platform)
                    formattedRequiredAdditionSoftware = [formattedRequiredAdditionSoftware, struct("Name", currentRas.Name, "Platform", platformMap(currentRas.Platform(platformIdx)), "DownloadURL", currentRas.DownloadURL, "LicenseURL", currentRas.LicenseURL)];
                end
            end

            obj.RequiredAdditionalSoftware = formattedRequiredAdditionSoftware;

            requiredAddons = config.RequiredAddons;

            indicesOfExcludedAddons = arrayfun(@(x) x.Exclude == 1, requiredAddons);
            requiredAddons(indicesOfExcludedAddons) = [];
            requiredAddons = rmfield(requiredAddons, "Exclude");

            for raIdx = 1:length(requiredAddons)
                if strcmp(requiredAddons(raIdx).EarliestVersion, "")
                    requiredAddons(raIdx).EarliestVersion = "Current";
                end
                if strcmp(requiredAddons(raIdx).LatestVersion, "")
                    requiredAddons(raIdx).LatestVersion = "Current";
                end
            end

            obj.RequiredAddons = requiredAddons;

        end

        function obj = initializeFromPackageDefinition(obj, changedprops)
            pkg = matlab.mpm.Package(obj.ToolboxFolder);

            % Identifier and the package ID must match
            if ~isequal(obj.Identifier, pkg.ID)
                error(message("MATLAB:toolbox_packaging:packaging:PackageIDError", obj.Identifier, pkg.ID));
            end

            % Package dependencies are not preserved in the ToolboxOptions
            if ~isempty(pkg.Dependencies)
                error(message("MATLAB:toolbox_packaging:packaging:PackageDependencyWarning"));
            end

            if ~any(strcmp(changedprops, "Description"))
                obj.Description = pkg.Description;
            end
            if ~any(strcmp(changedprops, "Summary"))
                obj.Summary = pkg.Summary;
            end
            if ~any(strcmp(changedprops, "ToolboxName"))
                obj.ToolboxName = pkg.DisplayName;
            end
            if ~any(strcmp(changedprops, "ToolboxVersion"))
                obj.ToolboxVersion = string(pkg.Version);
            end
            if ~any(strcmp(changedprops, "AuthorCompany"))
                obj.AuthorCompany = pkg.Provider.Organization;
            end
            if ~any(strcmp(changedprops, "AuthorName"))
                obj.AuthorName = pkg.Provider.Name;
            end
            if ~any(strcmp(changedprops, "AuthorEmail"))
                obj.AuthorEmail = pkg.Provider.Email;
            end
            if ~any(strcmp(changedprops, "ToolboxMatlabPath"))
                folders = pkg.Folders;
                obj.ToolboxMatlabPath = fullfile(obj.ToolboxFolder,[folders.Path]);
            end

        end

        function mustExistInPackageList(obj, fileToCheck)
            arguments
                obj matlab.addons.toolbox.ToolboxOptions
                fileToCheck string
            end
            mustBeNonzeroLengthText(fileToCheck)
            if ~exist(fileToCheck, "file")
                error(message("MATLAB:toolbox_packaging:packaging:FileMustExist", fileToCheck))
            end
            fileToCheck = matlab.internal.deployment.makePathAbsolute(fileToCheck);
            % Windows is case insensitive in the file system
            if ispc
                strcmpHandle = @strcmpi;
            else
                strcmpHandle = @strcmp;
            end
            if ~any(strcmpHandle(obj.ToolboxFiles,fileToCheck))
                error(message("MATLAB:toolbox_packaging:packaging:FileMissingFromToolboxFiles", fileToCheck))
            end
        end

        % Weed out path entries that do not contain any files that are
        % shipped with the toolbox
        function pathOut = pruneInvalidPathEntries(obj, pathIn)
            arguments
                obj matlab.addons.toolbox.ToolboxOptions
                pathIn (:,1) string
            end

            % At this point, verify that the matlabpath we are about to set
            % is does not contain folders with no packaged files
            pathOut = [];
            for idx = 1:length(pathIn)
                if obj.folderContainsFileInPackageList(pathIn(idx))
                    pathOut = [pathOut; pathIn(idx)]; %#ok<AGROW>
                end
            end
        end

        % Any matlabpath folder must be the parent of a file in ToolboxFiles
        function mustExistInPackageListAsParentFolder(obj, folderToCheck)
            arguments
                obj matlab.addons.toolbox.ToolboxOptions
                folderToCheck (1,1) string
            end

            if ~obj.folderContainsFileInPackageList(folderToCheck)
                error(message("MATLAB:toolbox_packaging:packaging:ParentFolderMissingFromToolboxFiles", folderToCheck))
            end
        end

        % Checks that the folder both contains something in the package
        % list or if it doesn't have a direct child it has a distant child
        % and is contained in the toolbox root
        function containsFile = folderContainsFileInPackageList(obj, folderToCheck)
            arguments
                obj matlab.addons.toolbox.ToolboxOptions
                folderToCheck string
            end

            mustBeFolder(folderToCheck);

            folderToCheck = matlab.internal.deployment.makePathAbsolute(folderToCheck);
            toolboxFolder = obj.ToolboxFolder;

            % Windows is case insensitive in the file system
            % Switching to contains instead of strcmp because it is valid
            % for a matlabpath to be added as a parent folder containing no
            % files itself now that empty folders are valid in an MLTBX
            if ispc
                strcmpHandle = @strcmpi;
            else
                strcmpHandle = @strcmp;
            end

            validParentPaths = obj.ToolboxFiles;
            for i=1:length(validParentPaths)
                validParentPaths(i) = getValidParentPathFolder(validParentPaths(i));
            end

            containsFile = any( ...
                or(strcmpHandle(validParentPaths,folderToCheck), ...
                    and(contains(validParentPaths, folderToCheck, 'IgnoreCase', ispc), ...
                        contains(folderToCheck, toolboxFolder, 'IgnoreCase', ispc) ...
                    ) ...
                ));

        end

        function fileList = deriveFilesFromRoot(obj)

            fileList = getAllFilesUnderFolder(obj.ToolboxFolder);

            % Additionally apply the exclusions that match the
            % handling with sharing from a MATLAB Project
            % Append this to the tbxignore list
            exclusions = obj.DEFAULT_FILE_EXCLUSIONS;
            excludedFilesArray = getToolboxIgnores(obj.ToolboxFolder);

            fileList = obj.applyExclusionFilter(fileList, [exclusions;excludedFilesArray]);

            if isempty(fileList)
                error(message("MATLAB:toolbox_packaging:packaging:ToolboxFolderCannotBeEmpty"))
            end
        end

        function toolboxMatlabPath = deriveMatlabPathFromRoot(obj)
            gp = genpath(obj.ToolboxFolder);
            toolboxMatlabPath = split(gp(1:end-1),pathsep);
        end

        function filesOut = applyExclusionFilter(obj, filesIn, exclusionRules)
            arguments
                obj matlab.addons.toolbox.ToolboxOptions
                filesIn (:,1) string
                exclusionRules (:,1) string
            end

            filesOut = filesIn;
            for idx = 1:length(exclusionRules)
                thisRule = exclusionRules(idx);

                if ~isempty(thisRule) && ~startsWith(thisRule, "%")
                    thisRule = fullfile(obj.ToolboxFolder, thisRule);

                    % If this lists a folder name only, assume it wants
                    % the entire folder removed, which is the same as
                    % saying <foldername>/**/*
                    if isfolder(thisRule)
                        thisRule = fullfile(thisRule,"**","*");
                    end

                    files = dir(thisRule);

                    for j = 1:length(files)
                        thisFile = fullfile(files(j).folder, files(j).name);
                        filesOut = filesOut(~strcmp(thisFile, filesOut));
                    end
                end
            end
        end

        function obj = initializeFromPRJ(obj, prjStruct)
            obj.ToolboxName = prjStruct.param_appname;
            obj.ToolboxVersion = prjStruct.param_version;

            % Need to derive files to package from dir
            obj.ToolboxFiles = deriveFilesFromRoot(obj);

            % Apply the exclusion rule if there is one
            if isfield(prjStruct, "param_exclude_filters") && ...
                ~strlength(prjStruct.param_exclude_filters)==0

                exclusionRules = strip(splitlines(prjStruct.param_exclude_filters));

                obj.ToolboxFiles = obj.applyExclusionFilter(obj.ToolboxFiles, exclusionRules);
            end

            mp = deriveMatlabPathFromRoot(obj);

            % Remove paths that are in the exclusion list from the PRJ
            if isfield(prjStruct, "param_matlabpath_excludes") && ...
                    isstruct(prjStruct.param_matlabpath_excludes)
                theItems = prjStruct.param_matlabpath_excludes.item;
                theItems = strcat(obj.ToolboxFolder,theItems);
                for j=1:length(theItems)
                    thisPathEntry = matlab.internal.deployment.makePathAbsolute(theItems(j));
                    mp(strcmp(mp,thisPathEntry)) = [];
                end
            end

            obj.ToolboxMatlabPath = pruneInvalidPathEntries(obj, mp);

            % Added additional files
            if isstruct(prjStruct.fileset_depfun_included)
                theFiles = cellstr(prjStruct.fileset_depfun_included.file);
                obj.ToolboxFiles = [obj.ToolboxFiles;theFiles];

                % Add the set of folders containing these additional files
                parentFolders = cellstr(fileparts(theFiles));
                obj.ToolboxMatlabPath = [obj.ToolboxMatlabPath;parentFolders];
            end

            obj.AuthorCompany = prjStruct.param_company;
            obj.AuthorEmail = prjStruct.param_email;
            obj.AuthorName = prjStruct.param_authnamewatermark;
            obj.Description = prjStruct.param_description;
            obj.Summary = prjStruct.param_summary;
            obj.ToolboxImageFile = prjStruct.param_screenshot;
            if isfield(prjStruct, "param_getting_started_guide")
                obj.ToolboxGettingStartedGuide = prjStruct.param_getting_started_guide;
            end
            obj.OutputFile = prjStruct.param_output;

            if isfield(prjStruct,"param_release_start") && ...
                    isfield(prjStruct,"param_release_end") && ...
                    isfield(prjStruct,"param_release_current_only")

                if strcmpi(prjStruct.param_release_current_only, "true")
                    obj.MinimumMatlabRelease = matlabRelease.Release;
                    obj.MaximumMatlabRelease = matlabRelease.Release;
                else
                    obj.MinimumMatlabRelease = prjStruct.param_release_start;
                    % The end release may be specified as "latest" which
                    % needs to be converted to empty
                    if strcmpi(prjStruct.param_release_end, "latest")
                        obj.MaximumMatlabRelease = "";
                    else
                        obj.MaximumMatlabRelease = prjStruct.param_release_end;
                    end
                end
            end
            if isfield(prjStruct,"param_compatiblity_windows") && ...
                    isfield(prjStruct,"param_compatiblity_linux") && ...
                    isfield(prjStruct,"param_compatiblity_macos") && ...
                    isfield(prjStruct,"param_compatiblity_matlabonline")

                obj.SupportedPlatforms = struct(...
                    "Win64", strcmp("true",(prjStruct.param_compatiblity_windows)), ...
                    "Glnxa64", strcmp("true",(prjStruct.param_compatiblity_linux)), ...
                    "Maci64", strcmp("true",(prjStruct.param_compatiblity_macos)), ...
                    "MatlabOnline", strcmp("true",(prjStruct.param_compatiblity_matlabonline)));
            end
            % Java classpath is left empty to allow user to define
            obj.ToolboxJavaPath = {};

            if isfield(prjStruct,"param_required_addons") && ...
                isstruct(prjStruct.param_required_addons)

                reqAddons = prjStruct.param_required_addons.requiredaddons;
                addonIndex = 1;
                for i=1:length(reqAddons.requiredAddOn)
                    thisAddon = reqAddons.requiredAddOn(i);
                    if strcmp(thisAddon.includeAttribute, "true")
                        if ~isfield(thisAddon,"downloadURLAttribute") || ...
                                ismissing(thisAddon.downloadURLAttribute)
                            downloadURL = '';
                        else
                            downloadURL = thisAddon.downloadURLAttribute;
                        end
                        % thisAddon.Text returns the name of the folder the
                        % add-on was installed into rather than the actual
                        % name of the add-on.  Try to query installedAddons
                        % for the right name.  If the add-on is no longer
                        % installed we'll fall back to the text
                        ad = matlab.addons.installedAddons;
                        if any(contains(string(ad.Identifier),thisAddon.idAttribute))
                            name = ad(contains(string(ad.Identifier), thisAddon.idAttribute),:).Name;
                        else
                            name = thisAddon.Text;
                        end
                        addonData = struct("Name", name, ...
                               "Identifier", thisAddon.idAttribute, ...
                               "EarliestVersion", thisAddon.earliestAttribute, ...
                               "LatestVersion", thisAddon.latestAttribute, ...
                               "DownloadURL", downloadURL);
                        if addonIndex == 1
                            obj.RequiredAddons = addonData;
                        else
                            obj.RequiredAddons(addonIndex) = addonData;
                        end
                        addonIndex = addonIndex + 1;
                    end
                end
            end

            if isfield(prjStruct,"param_additional_sw_names") && ...
                    isstruct(prjStruct.param_additional_sw_names) && ...
                    isfield(prjStruct,"param_additional_sw_licenses") && ...
                    isstruct(prjStruct.param_additional_sw_licenses) && ...
                    isfield(prjStruct,"param_additional_sw_win_url") && ...
                    isstruct(prjStruct.param_additional_sw_win_url) && ...
                    isfield(prjStruct,"param_additional_sw_mac_url") && ...
                    isstruct(prjStruct.param_additional_sw_mac_url) && ...
                    isfield(prjStruct,"param_additional_sw_linux_url") && ...
                    isstruct(prjStruct.param_additional_sw_linux_url)

                % Each platform is a different entry in the new struct
                % format.  Ignore the optimization of "common"
                RequiredAdditionalSoftwareStruct = initializeRequiredAdditionalSoftwareStruct("","","","");
                swIndex = 1;
                for i=1:length(prjStruct.param_additional_sw_names.item)
                    if ~isempty(char(prjStruct.param_additional_sw_win_url.item(i)))
                        RequiredAdditionalSoftwareStruct(swIndex) = initializeRequiredAdditionalSoftwareStruct( ...
                            prjStruct.param_additional_sw_names.item(i), ...
                            "win64", ...
                            strrep(prjStruct.param_additional_sw_win_url.item(i),'\\','//'), ...
                            strrep(prjStruct.param_additional_sw_licenses.item(i),'\\','//'));
                        swIndex = swIndex + 1;
                    end
                    if ~isempty(char(prjStruct.param_additional_sw_mac_url.item(i)))
                        RequiredAdditionalSoftwareStruct(swIndex) = initializeRequiredAdditionalSoftwareStruct( ...
                            prjStruct.param_additional_sw_names.item(i), ...
                            "maci64", ...
                            strrep(prjStruct.param_additional_sw_mac_url.item(i),'\\','//'), ...
                            strrep(prjStruct.param_additional_sw_licenses.item(i),'\\','//'));
                        swIndex = swIndex + 1;
                    end
                    if ~isempty(char(prjStruct.param_additional_sw_linux_url.item(i)))
                        RequiredAdditionalSoftwareStruct(swIndex) = initializeRequiredAdditionalSoftwareStruct( ...
                            prjStruct.param_additional_sw_names.item(i), ...
                            "glnxa64", ...
                            strrep(prjStruct.param_additional_sw_linux_url.item(i),'\\','//'), ...
                            strrep(prjStruct.param_additional_sw_licenses.item(i),'\\','//'));
                        swIndex = swIndex + 1;
                    end
                end
                obj.RequiredAdditionalSoftware = RequiredAdditionalSoftwareStruct;
            end
            if isfield(prjStruct,"param_registered_apps") && ...
                    isstruct(prjStruct.param_registered_apps)
                obj.AppGalleryFiles = cellstr(prjStruct.param_registered_apps.file);
            end
        end
    end
end

% Private functions
function RequiredAdditionalSoftwareStruct = initializeRequiredAdditionalSoftwareStruct(name, platform, downloadURL, licenseURL)
    arguments
        name string
        platform string
        downloadURL string
        licenseURL string
    end
    RequiredAdditionalSoftwareStruct = ...
        struct("Name", name, ...
               "Platform", platform, ...
               "DownloadURL", downloadURL, ...
               "LicenseURL", licenseURL);
end

% Must be of the format R####(a|b)
function isValid = isValidReleaseString(releaseString)
    mustBeNonzeroLengthText(releaseString);
    releaseStringChar = char(releaseString);

    if length(releaseStringChar) == 6
        year = str2double(releaseStringChar(2:5));

        isValid =  strcmpi(releaseStringChar(1), "r") && ...
            (strcmpi(releaseStringChar(6), "a") || strcmpi(releaseStringChar(6), "b")) && ...
            ~isnan(year);
    else
        isValid = false;
    end

end

% Checks if the minimum and maximum release strings are compatible
function isValid = isValidReleaseTuple(releaseTuple)

    maximumValidRelease = version("-release");
    minimumValidRelease = "2014b";

    % Pull values out of tuple and chop of the 'r'
    minimumRelease = char(releaseTuple(1));
    minEmpty = strlength(minimumRelease) == 0;
    maximumRelease = char(releaseTuple(2));
    maxEmpty = strlength(maximumRelease) == 0;

    if minEmpty
        minValid = true;
    else
        % Validate min
        minValid = matlab.addons.toolbox.ToolboxOptions.releaseIsGreaterOrEqual(maximumValidRelease, minimumRelease(2:end)) && ...
                    matlab.addons.toolbox.ToolboxOptions.releaseIsGreaterOrEqual(minimumRelease(2:end), minimumValidRelease) && ...
                    (maxEmpty || matlab.addons.toolbox.ToolboxOptions.releaseIsGreaterOrEqual(maximumRelease(2:end), minimumRelease(2:end)));
    end

    if maxEmpty
        maxValid = true;
    else
        % Validate max
        maxValid = matlab.addons.toolbox.ToolboxOptions.releaseIsGreaterOrEqual(maximumValidRelease, maximumRelease(2:end)) && ...
                    matlab.addons.toolbox.ToolboxOptions.releaseIsGreaterOrEqual(maximumRelease(2:end), minimumValidRelease) && ...
                    (minEmpty || matlab.addons.toolbox.ToolboxOptions.releaseIsGreaterOrEqual(maximumRelease(2:end), minimumRelease(2:end)));
    end

    isValid = minValid && maxValid;

end

function noBadFolderCharacters(newName,propname)
    arguments
        newName char
        propname string
    end

    if ispc
        % In the case where we are on Windows, make sure we are not going
        % to incorrectly identify the drive letter with a colon as a bad
        % folder character
        if strlength(newName) > 2 && strcmp(newName(2:3),":\")
            newName = newName(4:end);
        end
    end
    noBadToolboxNameCharacters(newName,propname)
end

function noBadToolboxNameCharacters(newName,propname)
    arguments
        newName char
        propname string
    end

    badCharacters = {'<','>',':','"','*','|','?','&'};
    % Additionally filter out offensive ascii values below 32 (space)
    newNameDouble = double(newName);

    if contains(newName,badCharacters) || any(newNameDouble < 32)
        error(message('MATLAB:toolbox_packaging:packaging:PropertyInvalidFilesystemCharacters',...
                        propname, newName));
    end
end

% The assumption coming into this routine is that the structIn has already
% been validated to contain the expected fields.  This is to trim off the
% excess
function structOut = removeExtraFieldsFromStruct(paramName, structIn, expectedFields)
    arguments
        paramName (1,1) string
        structIn (:,1) struct
        expectedFields (:,1) string
    end
    % Extra fields will be removed, so check if there are more than
    % the expected ones and if there are, we'll make a new struct
    % that is only those expected
    extraFields = setxor(fields(structIn), expectedFields);
    if isempty(extraFields)
        structOut = structIn;
    else
        structOut = rmfield(structIn,extraFields);
        s = "[" + join(string(extraFields),",") + "]";
        warning(message("MATLAB:toolbox_packaging:packaging:ExtraFieldWarning",paramName,s));
    end
end

function mustBeValidIdentifier(identifier)
    mustBeTextScalar(identifier)
    mustBeNonzeroLengthText(identifier)

    % Identifier must be alphanumeric and can contain hyphens
    if ~all(isstrprop(strrep(identifier,"-",""),"alphanum"))
        error(message("MATLAB:toolbox_packaging:packaging:InvalidIdentifier",identifier));
    end
end

function verifyRequiredFields(propName, newVal, expectedFields)
    arguments
        propName (1,1) string
        newVal (:,1) struct
        expectedFields (:,1) string
    end
    foundFieldIndices = isfield(newVal, expectedFields);
    if ~all(foundFieldIndices)
        missingFields = expectedFields(~foundFieldIndices);
        s = "[" + join(string(missingFields),",") + "]";
        error(message("MATLAB:toolbox_packaging:packaging:RequiredFieldMissing",s,propName));
    end
end

function allFiles = getAllFilesUnderFolder(folderIn)
    filesUnderRoot = dir(fullfile(folderIn,"**","*"));
    allFilesAndFolders = arrayfun(@(x) fullfile(x.folder,x.name),filesUnderRoot,"UniformOutput",0);

    % Weed out the '.' and '..' folders
    allFilesAndFolders = string(allFilesAndFolders(~or(...
        endsWith(allFilesAndFolders,strcat(filesep,"..")), ...
        endsWith(allFilesAndFolders,strcat(filesep,".")))));

    if isempty(allFilesAndFolders)
        % This was an empty folder to begin with and we need to record it
        allFiles = folderIn;
    else
        fileIndices = arrayfun(@(x) isfile(x), allFilesAndFolders);
        % dir of empty folder gives back only "." and "..", this numel == 2
        emptyFolderIndices = arrayfun(@(x) (isfolder(x) && numel(dir(x)) == 2), allFilesAndFolders);
        allFiles = allFilesAndFolders(or(fileIndices,emptyFolderIndices));
    end
end

% Get the MATLAB path folder for the given inputFile
function validMatlabPathFolder = getValidParentPathFolder(inputFile)
    [parentFolder, thisFileName] = fileparts(inputFile);

    if ~isfolder(inputFile) || (isfolder(inputFile) && ...
            (startsWith(thisFileName, "+") || startsWith(thisFileName, "@") || strcmp(thisFileName, "private")))
        validMatlabPathFolder = getValidParentPathFolder(parentFolder);
    else
        validMatlabPathFolder = inputFile;
    end
end

% Throw is private, + folder, or @ folder
function mustNotBeReservedFolderName(folderToCheck)
    arguments
        folderToCheck (1,1) string
    end

    [~, folderName] = fileparts(folderToCheck);
    if (startsWith(folderName, "+") || startsWith(folderName, "@") || strcmp(folderName, "private"))
        error(message("MATLAB:toolbox_packaging:packaging:NotValidPathFolder", folderToCheck))
    end
end

%{
function [excludedFilesArray] = getExcludedFiles(absoluteToolboxRoot)
    %GETEXCLUDEDFILES Summary of this function goes here
    %   Detailed explanation goes here
      excludedFilesArray = string.empty;
      ignoreFile = fullfile(absoluteToolboxRoot, '.tbxIgnore');
      if isfile(ignoreFile)
         files = readlines(ignoreFile);
         files(end + 1) = ".tbxIgnore";
         files = files(~strcmp(files, ""));
         excludedFiles = fullfile(absoluteToolboxRoot, files);
         %double up rule for folder and its contents
         excludedFiles = [excludedFiles; fullfile(excludedFiles(arrayfun(@(x) isfolder(x), excludedFiles)),"**","*")];
         for i= 1 : numel(excludedFiles)
            excludedFileRule = excludedFiles(i); 

            % if the rule refers to a 
            if isfolder(excludedFileRule)
                excludedFilesArray = [excludedFilesArray, excludedFileRule];
            else
                dirRes = dir(excludedFileRule);
                dirResFilePaths = string({dirRes.folder}) + filesep + string({dirRes.name});
                
                % remvoe the . and .. from results, as these are not
                % real folder/files useful for this purpose
                dirResFilePaths = string(dirResFilePaths(~or(...
                    endsWith(dirResFilePaths,strcat(filesep,"..")), ...
                    endsWith(dirResFilePaths,strcat(filesep,".")))));
                excludedFilesArray = [excludedFilesArray, dirResFilePaths];
            end
         end
         excludedFilesArray=unique(excludedFilesArray');
      end
end
%}


function excludedFilesArray = getToolboxIgnores(absoluteToolboxRoot)
    %GETEXCLUDEDFILES Summary of this function goes here
    %   Detailed explanation goes here
    excludedFilesArray = string.empty;
    ignoreFile = fullfile(absoluteToolboxRoot, "toolbox.ignore");
    if isfile(ignoreFile)
        files = readlines(ignoreFile);
        files(end + 1) = "toolbox.ignore";
        
        files = files(~strcmp(files, ""));
        % separate exclusion list from comments
        files = files(~startsWith(files, '%'));
        % find indices of all files beginning with \% (escape character for %)
        index = find(startsWith(files, '\%'));
        % if there are files beginning with \%, remove the \ from the beginning of each one
        if ~isempty(index) 
            files(index) = extractAfter(files(index), 1);
        end

        files = strtrim(files(:)); % Ensure this is a column and clean up whitespaces
        excludedFilesArray = files(~strcmp(files, ""));
    end
end