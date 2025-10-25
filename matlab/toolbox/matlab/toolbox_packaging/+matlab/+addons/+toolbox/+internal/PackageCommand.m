classdef PackageCommand < handle
    %PackageCommand Utility functions for creating an mltbx file
    
    properties (Access = private)
        tempFile
        mltbxFile
        rootFolder
        reader
    end
    
    methods
        function obj = PackageCommand(toolboxProjectReader)
            obj.reader = toolboxProjectReader;
            obj.rootFolder = toolboxProjectReader.getRoot();
            
            %error out if root is empty, we need it
            if (isempty(obj.rootFolder) || ~exist(obj.rootFolder,'dir'))
                %error message will eventually need to adapt to non prj-based projects
                rootMessage = message('MATLAB:toolbox_packaging:packaging:ToolboxRootNotFound',obj.rootFolder).getString;
                error(message('MATLAB:toolbox_packaging:packaging:PackagingError',obj.reader.getProjectPath(), rootMessage));
            end
            obj.mltbxFile = obj.getArtifactLocation();
        end
        
        function setPackageName(obj, outputName)
            obj.mltbxFile = outputName;
        end
        
        function mltbxFile = getPackageFile(obj)
            mltbxFile = obj.mltbxFile;
        end
        
        function package(obj)
            obj.tempFile = strcat(tempname, '.mltbx');
            cleanup = onCleanup(@()cleanUpTempFile(obj));%todo create function, and set breakpoitn to debug
            
            %create the basic toolbox. Data will eb added afterwards
            addonProperties = obj.constructAddonProperties();
            mlAddonCreate(obj.tempFile, addonProperties);
            
            %create and add instruction sets
            obj.createInstructionSetFiles();
            
            %create and add examples data
            %republish examples if project wants to
            tbxExamples = obj.reader.getExamples();
            %obj.publishExamplesIfNeeded(tbxExamples);
            mlAddonSetExamples(obj.tempFile, tbxExamples);
            
            %add apps list to the toolbox
            appInstallList = obj.reader.getIncludedApps();
            mlAddonSetAppInstallList(obj.tempFile, appInstallList);
            
            %find all toolbox files, format, then add to package
            rootToRemove = strcat(obj.rootFolder,filesep);
            toolboxFiles = obj.reader.getFileList();
            formattedToolboxFiles = cell(size(toolboxFiles));
            for i=1:numel(toolboxFiles)
                originalFilePath = toolboxFiles(i,:);
                formattedPathForPackage = erase(originalFilePath, lineBoundary + rootToRemove);
                formattedPathForPackage = obj.formatSlahesForOPCPackage(formattedPathForPackage);
                formattedToolboxFiles(i) = formattedPathForPackage;
            end
            mlAddonAddFiles(obj.tempFile, toolboxFiles, formattedToolboxFiles);
            
            %now add all the folders, ensures empty ones will be present
            toolboxFolders = obj.reader.getFolderList();
            formattedToolboxFolders = cell(size(toolboxFolders));
            for i=1:numel(toolboxFolders)
                originalFolder = toolboxFolders(i,:);
                formattedFolder = erase(originalFolder, lineBoundary + rootToRemove);
                formattedFolder = obj.formatSlahesForOPCPackage(formattedFolder);
                formattedToolboxFolders(i) = formattedFolder;
            end
            mlAddonAddFolders(obj.tempFile, formattedToolboxFolders)
            
            %SCREENSHOT
            screenshotPath = obj.reader.getScreenshotPath();
            if(~isempty(screenshotPath))
                mlAddonSetScreenshot(obj.tempFile, screenshotPath);
            end
            
            %MATLAB PATH
            matlabPaths = obj.reader.getMATLABPaths();
            matlabPaths = cellfun(@(x) obj.formatSlahesForOPCPackage(x), matlabPaths, 'UniformOutput', 0 );
            mltbxConfiguration.matlabPaths = matlabPaths;
            
            %JAVA CLASS PATH
            javaPaths = obj.reader.getJavaClassPaths();    
            javaPaths = cellfun(@(x) obj.formatSlahesForOPCPackage(x), javaPaths, 'UniformOutput', 0 );
            mltbxConfiguration.javaClassPaths = javaPaths;
            
            %DOCUMENTATION
            docPath = obj.reader.getDocumentationPath();
            mltbxConfiguration.infoXMLPath = obj.formatSlahesForOPCPackage(docPath);
            
            %GETTING STARTED GUIDE
            gsgPath = obj.reader.getGettingStartedGuide();
            mltbxConfiguration.gettingStartedDocPath = obj.formatSlahesForOPCPackage(gsgPath);
            
            %INSTALL MAP
            installMapPath = obj.reader.getInstallMapPath();
            mltbxConfiguration.installMapPath = installMapPath;
            
            mlAddonSetConfiguration(obj.tempFile, mltbxConfiguration);
            
            %SYSTEM REQUIREMENTS
            mltbxSysRequirements.productDependency = obj.reader.getRequiredProducts();
            mltbxSysRequirements.platformCompatibility = obj.reader.getPlatformCompatibility();
            mltbxSysRequirements.releaseCompatibility = obj.reader.getReleaseCompatibility();
            mltbxSysRequirements.addonDependency = obj.reader.getRequiredAddons();
            mlAddonSetSystemRequirements(obj.tempFile, mltbxSysRequirements)
            
            %SIGN TOOLBOX's SYSTEM REQUIREMENTS
            mlAddonSign(obj.tempFile);
            
            %Reached the end without errors, move tempfile to outptutDir
            movefile(obj.tempFile, obj.mltbxFile);
        end
        
    end
    
    methods(Static)

        function path = formatSlahesForOPCPackage(path)
            if ispc
                %mostly for external files
                path = strrep(path, ':', '__');
                path = strrep(path, '\\', '');
                
                %change slashes for OPC
                path = strrep(path,'\','/');
            end
        end
        
        function outputLocation = generateInstructionSet(entry, validName, fileName, url)
            builderObj = matlab.addons.toolbox.internal.InstructionSetBuilder('extract');
            builderObj.DownloadUrl = url;
            builderObj.Archive = validName;
            builderObj.DisplayName = entry.name;
            builderObj.LicenseUrl = entry.license;
            builderObj.DestinationFolderName = validName;
            
            builderObj.create(tempdir, fileName);
            outputLocation = fullfile(tempdir, fileName);
        end
        
        function instructionSetName = getInstructionSetName(validName, platformSuffix)
            instructionSetName = strcat(validName, '_', platformSuffix, '.xml');
        end
        
    end
    
    methods(Access = private)
        function cleanUpTempFile(obj)
            if exist(obj.tempFile,'file')
                delete(obj.tempFile)
            end
        end
        
        function addonProperties = constructAddonProperties(obj)
            addonProperties.name = obj.reader.getName();
            addonProperties.version = obj.reader.getVersion();
            
            author = obj.reader.getAuthor();
            addonProperties.authorName = author.name;
            addonProperties.authorContact = author.contact;
            addonProperties.authorOrganization = author.organization;
            
            addonProperties.summary = obj.reader.getSummary();
            addonProperties.description = obj.reader.getDescription();
            addonProperties.GUID = obj.reader.getGuid();
            addonProperties.type = 'MATLAB Toolbox';
        end
        
        %the output location should be right beside the project
        %this replicates existing behavior in Java
        function artifactName = getArtifactLocation(obj)
            projectLocation  = obj.reader.getProjectPath();
            name  = obj.reader.getName();
            [location, ~, ~] = fileparts(projectLocation);
            ext = '.mltbx';
            artifactName = fullfile(location,strcat(name, ext));
        end
        
        function instructionSetFiles = createInstructionSetFiles(obj)
            additionalSoftware = obj.reader.getRequiredAdditionalSoftware();
            if(~isempty(additionalSoftware))
                
                instructionSetFiles = cell(1,0);
                for entry = additionalSoftware
                    if(entry.name~="" && entry.license~="")
                        
                        validFileName =  matlab.lang.makeValidName(entry.name);
                        if(strcmp(entry.winURL, entry.linuxURL) && strcmp(entry.winURL, entry.macURL))
                            instructionSetFiles{end + 1} = obj.generateInstructionSet(entry,validFileName,...
                                obj.getInstructionSetName(validFileName, 'common'), entry.winURL);
                        else
                            if(~isempty(entry.winURL))
                                instructionSetFiles{end + 1} = obj.generateInstructionSet(entry,validFileName,...
                                    obj.getInstructionSetName(validFileName, 'win64'), entry.winURL);
                            end
                            if(~isempty(entry.linuxURL))
                                instructionSetFiles{end + 1} = obj.generateInstructionSet(entry,validFileName,...
                                    obj.getInstructionSetName(validFileName, 'glnxa64'), entry.linuxURL);
                            end
                            if(~isempty(entry.macURL))
                                % Cover both maci64 and maca64 assuming the
                                % software is the same for both for now
                                instructionSetFiles{end + 1} = obj.generateInstructionSet(entry,validFileName,...
                                    obj.getInstructionSetName(validFileName, 'maca64'), entry.macURL);
                                instructionSetFiles{end + 1} = obj.generateInstructionSet(entry,validFileName,...
                                    obj.getInstructionSetName(validFileName, 'maci64'), entry.macURL);
                            end
                        end
                    end
                end
                cellfun(@(x) mlAddonAddInstructionSet(obj.tempFile, x), instructionSetFiles);
            end
        end
        
        function publishExamplesIfNeeded(obj, tbxExamples)
            doPublish = obj.reader.doPublishExamplesOnPackage();
            %NOTE, it seems toolbox pacakigng tool does not honor
            %categories from custom demos.xml files
            %Thus, thus assumes there is only one category
            if(doPublish)
                
                allTbxExamples = cell(1,0);
                for i = 1: size(tbxExamples.examples,2)
                    allTbxExamples{end+1} = tbxExamples.examples(i).main; %#ok<AGROW>
                end
                %no beep, and won't pollute the command window
                originalStatus = beep;
                beep off;
                evalc('matlab.addons.toolbox.internal.publishExamples(allTbxExamples)');
                beep(originalStatus);
            end
        end
        
    end
    
end

