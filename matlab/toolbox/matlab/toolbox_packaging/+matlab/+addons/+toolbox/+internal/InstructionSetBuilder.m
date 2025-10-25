% Class for constructing an Instruction Set for additional software


% Copyright 2015-2020 MathWorks, Inc.
classdef (Sealed) InstructionSetBuilder < matlab.mixin.SetGet
    
    properties
        DownloadUrl = 'http://##CHANGE_ME:DOWNLOAD_URL##'
        Archive = '##CHANGE_ME:ARCHIVE_NAME##'
        % Type defines how the instruction set will be installed
        % extract, install or extract_and_install
        Type
        DisplayName = '##CHANGE_ME:3P TOOL NAME##*'
        LicenseUrl = 'http://##CHANGE_ME:LICENSE_URL##*'
        SuccessReturnCodesInfo
        DestinationFolderName = '##CHANGE_ME:FOLDER_NAME##';
    end
    
    
    properties (Access = private)
        InstructionSetJavaBuilderObj
    end
    methods
        
        function obj = InstructionSetBuilder(type)
            
            validTypes = {'extract'}; %'install', 'extract_and_install' not available yet
            validatestring(type,validTypes,'InstructionSetBuilder',1);
            
            obj.Type = lower(type);
        end
        
        function isObj = create(obj, folder, name)
            % create - Creates an InstructionSet object
            % Generates an InstructionSet file from the object. The folder
            % argument is required and specifies the folder in which the
            % InstructionSet file gets generated. Please refer to the
            % InstructionSetBuilder (help InstructionSetBuilder) class for
            % more details
            
            validateattributes(folder, {'char'},{'nonempty'},'create', 'folder');
            if nargin > 2
                validateattributes(name, {'char'},{'nonempty'},'create', 'name');
            end
            isObj = obj.build();
            version = obj.getCurrentVersion();
            
            if ~exist('name')
                name = [lower(obj.DisplayName) '_' version '.xml'];
            end
            
            file = fullfile(folder, name);
            str = sprintf('o-- Writing Instruction Set file %s', file);
            
            isObj.output(file);
            assert(exist(file)==2,sprintf('Instruction Set %s did not get created',file));
            
        end
        
        
        
        %% Property Setters
        function obj = set.DisplayName(obj, name)
            validateattributes(name,{'char'},{'nonempty'});
            obj.DisplayName = name;
        end
        
        function obj = set.DestinationFolderName(obj, folder)
            validateattributes(folder,{'char'},{});
            obj.DestinationFolderName = folder;
        end
        
        function obj = set.Archive(obj, name)
            validateattributes(name,{'char'},{'nonempty'});
            obj.Archive = name;
        end
        
        function obj = set.DownloadUrl(obj, url)
            validateattributes(url,{'char'},{'nonempty'});
            try
                java.net.URL(url);
            catch
                error('InstructionBuilder:setup:invalidurl','%s is not a valid URL',url);
            end
            obj.DownloadUrl = url;
        end
        
        function obj = set.LicenseUrl(obj, url)
            validateattributes(url,{'char'},{'nonempty'});
            try
                java.net.URL(url);
            catch
                error('InstructionBuilder:setup:invalidurl','%s is not a valid URL',url);
            end
            obj.LicenseUrl = url;
        end
        
        
        function obj = set.SuccessReturnCodesInfo(obj, info)
            validateattributes(info,{'struct','array'},{'nonempty'});
            assert(isfield(info,'codes'),'SuccessReturnCodesInfo must have a fieldname - codes');
            assert(isfield(info,'messages'),'SuccessReturnCodesInfo must have a fieldname - messages');
            
            
            for i = 1:numel(info)
                obj.SuccessReturnCodesInfo(i).codes = info(i).codes;
                if ischar(info(i).messages)
                    obj.SuccessReturnCodesInfo(i).messages = {info(i).messages};
                else
                    obj.SuccessReturnCodesInfo(i).messages = info(i).messages;
                end
            end
        end
        
        
        
    end
    
    methods (Access=private)
        
        
        function instructionSetObject = build(obj)
            % Method to build the Instruction Set Object
            str = sprintf('o-- Building Instruction Set Object for %s', obj.DisplayName);
            
            % Aggregate the install commands
            switch lower(obj.Type)
                case 'extract'
                    installType = obj.createExtractType(obj.DestinationFolderName);
                otherwise
            end
            
            compoundInstallCmd = installType(1);
            
            % Create the InstructionSetModel object
            instructionSetModel = com.mathworks.instructionset.InstructionSetModel(...
                obj.DownloadUrl, obj.Archive, compoundInstallCmd, ...
                obj.DisplayName, obj.LicenseUrl, '', false);
            
            % Create a builder Object
            obj.InstructionSetJavaBuilderObj = ...
                com.mathworks.instructionset.InstructionSet.makeBuilder(...
                matlabroot, instructionSetModel);
            
            % Add Windows Registry PreChecks
            
            % Create the Instruction Set Object
            instructionSetObject = obj.InstructionSetJavaBuilderObj.build();
        end
        
        
    end
    
    methods (Static, Access = private)
        function extractType = createExtractType(destFolder)
            % Method to create extract type object
            zipType = javaMethod('valueOf',...
                'com.mathworks.instructionset.ExtractInstallType$ArchiveType',...
                'ZIP_ARCHIVE');
            if ~isempty(destFolder)
                extractType = com.mathworks.instructionset.ExtractInstallType(zipType, destFolder);
            else
                extractType = com.mathworks.instructionset.ExtractInstallType(zipType);
            end
        end
        
        function verStr = getCurrentVersion()
%             verStr = hwconnectinstaller.util.getCurrentRelease;
%             verStr = lower(regexprep(verStr,'\W',''));
            verStr = version('-release');
        end
    end
end


