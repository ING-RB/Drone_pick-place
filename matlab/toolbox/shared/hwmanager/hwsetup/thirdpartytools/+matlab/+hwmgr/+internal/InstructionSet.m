classdef InstructionSet < handle
    %INSTRUCTIONSETINTERFACE acts as a wrapper for matlab.internal.InstructionSet
    %class. Provides helper apis for interacting with instruction sets.

    % Copyright 2022 The MathWorks, Inc.

    properties (Access = private)
        % MLInstructionSet handle to matlab.internal.InstructionSet object
        MLInstructionSet
    end

    properties (Access = private, Constant)
        SUCCESS_STATE = 2;
    end

    methods
        function obj = InstructionSet(instrset)
            % INSTRUCTIONSET constructor that accepts an instruction
            % set file and initializes InstructionSetObj
            validateattributes(instrset, {'char','strings'}, {'nonempty'});
            obj.MLInstructionSet = matlab.internal.InstructionSet(instrset);
        end
    end

    %----------------------------------------------------------------------
    % methods to query instruction set properties
    %----------------------------------------------------------------------
    methods
        function out = getDisplayName(obj)
            out = char(obj.MLInstructionSet.getDisplayName());
        end

        function out = getLicenseUrl(obj)
            out = char(obj.MLInstructionSet.getLicenseUrl());
        end
        
        function out = getDownloadUrl(obj)
            out = char(obj.MLInstructionSet.getDownloadUrl());
        end

        function out = getArchiveName(obj)
            out = char(obj.MLInstructionSet.getArchiveName());
        end

         function out = getInstructionSetName(obj)
             % GETINSTRUCTIONSETNAME returns the name of the instruction 
             % set to be used as the folder

            [~, name, ext] = fileparts(fileparts(fileparts(obj.MLInstructionSet.FilePath)));
            out = [name, ext];
         end

         function out = getDownloadsFolder(~)
             out = fullfile(matlabshared.supportpkg.internal.getSupportPackageRootNoCreate,...
                 'downloads');
         end

         function out = getInstallFolder(obj)
             spkgRoot = matlabshared.supportpkg.internal.getSupportPackageRootNoCreate();
             out = fullfile(spkgRoot, '3P.instrset', obj.getInstructionSetName());
         end

         function out = isDownloadRequired(obj)
             % ISDOWNLOADREQUIRED returns true if the tool needs to be
             % downloaded, otherwise returns false
             out = ~obj.isArchiveAvailable(obj.getDownloadsFolder());
         end

         function out = isInstalled(obj)
             % ISINSTALLED returns true if the tool has been
             % installed, otherwise returns false

             out = ~isempty(matlab.internal.get3pInstallLocation(...
                 obj.getInstructionSetName));
         end

         function out = isArchiveAvailable(obj, folder)
             % ISARCHIVEAVAILABLE returns true if archive exists in the
             % download folder

             out = false;
             if exist(fullfile(folder, obj.getArchiveName), 'file')
                 out = true;
             end
         end

         function out = isElevationRequired(obj)
             % ISELEVATIONREQUIRED returns true if the instruction set
             % requires elevation to be installed

            out = obj.MLInstructionSet.isElevationRequired();
         end

         function out = getFilePath(obj)

             out = obj.MLInstructionSet.FilePath;
         end
    end

    %----------------------------------------------------------------------
    % action methods
    %----------------------------------------------------------------------
    methods
        function [status, msg] = download(obj)
            % DOWNLOAD perform the download. MLInstructionSet API could 
            % either return a status or throw an error

            status = false;
            obj.MLInstructionSet.setDownloadFolder(obj.getDownloadsFolder());
            try                
                status = obj.MLInstructionSet.download();
                if status == obj.SUCCESS_STATE
                    status = true;
                    msg = '';
                else
                    msg = message('hwsetup:thirdpartytools:DownloadError', obj.getDisplayName()).getString;
                end
            catch ex                
                msg = ex.message;
            end
        end

        function [status, msg] = install(obj)
            % INSTALL perform the installation. MLInstructionSet API could 
            % either return a status or throw an error

            status = false;
            try
                installFolder = obj.getInstallFolder();
                obj.createFolder(installFolder);
                obj.MLInstructionSet.setDownloadFolder(obj.getDownloadsFolder());
                obj.MLInstructionSet.setInstallFolder(installFolder);
                istatus = obj.MLInstructionSet.install();

                if istatus == obj.SUCCESS_STATE
                    status = true;
                    msg = '';
                else
                    msg = message('hwsetup:thirdpartytools:InstallError', obj.getDisplayName()).getString;
                end
            catch ex
                msg = ex.message;
            end
        end
    end

    %----------------------------------------------------------------------
    % helper methods
    %----------------------------------------------------------------------
    methods (Access = 'protected')
        function createFolder(~, name)
            % CREATEFOLDER - creates a folder using the given name if it
            % doesn't exist

            if ~exist(name, 'dir')
                [status, msg] = mkdir(name);
                if ~status
                    error(message('hwsetup:thirdpartytools:FolderCreationError', name, msg));
                end
            end
        end
    end
end