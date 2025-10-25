classdef AutoInstall < matlab.hwmgr.internal.hwsetup.TemplateBase
    % AUTOINSTALL - Template to guide users through the process of
    % automatically install third-party tools.
    %
    % AutoInstall Properties:
    %   DescriptionLabel            - Description label for the setup screen.
    %   TpDownloadAndInstallTable  - Table listing third-party software tools
    %                                 to be downloaded along with their respective
    %                                 licenses and download links.
    %   InstallDescriptionLabel    - Label for the installation section description.
    %   InstallButton              - Button to initiate validation of the third-party
    %                                 tool installation.
    %   InstallStatusTable         - Widget to display the installation status.
    %
    % AutoInstall Methods(Inherited):
    %   show                        - Display the template/screen.
    %   logMessage                  - Log diagnostic messages to a file.
    %   getNextScreenID             - Return the Next Screen ID (class name).
    %   getPreviousScreenID         - Return the Previous Screen ID (class name).
    %
    % See also
    % matlab.hwmgr.internal.hwsetup.thirdpartytools.ManualDownloadAndInstall,
    % matlab.hwmgr.internal.hwsetup.thirdpartytools.ManualDownload,
    % matlab.hwmgr.internal.hwsetup.thirdpartytools.AutoDownloadAndInstall
    %

    % Copyright 2024 The MathWorks, Inc.

    properties (Access = {?matlab.hwmgr.internal.hwsetup.TemplateBase,...
            ?hwsetuptest.util.TemplateBaseTester,...
            ?hwsetup.testtool.StandardTestCase})
        % DescriptionLabel - Description label for the setup screen.
        DescriptionLabel

        % TpDownloadAndInstallTable - Table listing third-party software tools to be downloaded.
        TpDownloadAndInstallTable

        % InstallDescriptionLabel - Label for the installation section description.
        InstallDescriptionLabel

        % InstallButton - Button to initiate validation of the third-party tool installation.
        InstallButton

        % InstallStatusTable - Widget to display the installation status.
        InstallStatusTable
    end

    properties (Abstract, Access = protected)
        % InstructionSetNames - Abstract property that must be implemented in subclasses.
        % This property should hold the name of the instruction set as a string.
        InstructionSetNames (1, :) cell
    end

    properties (Access = private)
        % InstructionSets - Object representing the instruction set associated
        %                   with this auto download and install process.
        InstructionSets
    end

    methods
        function obj = AutoInstall(varargin)
            %AutoDownloadAndInstall
            obj@matlab.hwmgr.internal.hwsetup.TemplateBase(varargin{:});
            obj.TemplateLayout =  matlab.hwmgr.internal.hwsetup.TemplateLayout.GRID;

            %get Instruction set based on the names
            obj.InstructionSets = obj.Workflow.getInstructionSet(obj.InstructionSetNames);

            % create all the UI widgets for the template
            obj.createWidgets();

            % Set values to the UI components reflecting the auto download
            % and install instructions for the third-party (tp) tool
            obj.initializeWidgets();
        end
    end % END public method

    methods(Access = private)

        function createWidgets(obj)
            %createWidgets method to create UI components for the setup screen.

            obj.ContentGrid.Visible = 'on';
            widgetParent = obj.ContentGrid;
            obj.ContentGrid.RowHeight = {'fit', 'fit', 24, 24, 'fit'};
            obj.ContentGrid.ColumnWidth = {100, '1x'};

            row = 1;

            % Create the main description label and set its properties
            mainDescription = matlab.hwmgr.internal.hwsetup.Label.getInstance(widgetParent);
            mainDescription.Column = [1, 2];
            mainDescription.Row = row;
            obj.DescriptionLabel = mainDescription;

            % Create the table for third-party tool download and installation
            tpDownloadandInstallTable = matlab.hwmgr.internal.hwsetup.TpDownloadAndInstallStatusTable.getInstance(widgetParent);
            tpDownloadandInstallTable.Column = [1, 2];
            tpDownloadandInstallTable.Row = row + 1;
            obj.TpDownloadAndInstallTable = tpDownloadandInstallTable;

            % Create the validation description label and set its properties
            installDescription = matlab.hwmgr.internal.hwsetup.Label.getInstance(widgetParent);
            installDescription.Column = [1, 2];
            installDescription.Row = row + 2;
            obj.InstallDescriptionLabel = installDescription;

            % Create the validate button and assign its callback function
            installButton = matlab.hwmgr.internal.hwsetup.Button.getInstance(widgetParent);
            installButton.ButtonPushedFcn = @obj.installButtonPushedFcn; % Callback function for when the button is pressed
            installButton.Column = 1;
            installButton.Row = row + 3;
            obj.InstallButton = installButton;

            % Create the status table for validation feedback and set its properties
            installStatusTable = matlab.hwmgr.internal.hwsetup.StatusTable.getInstance(widgetParent);
            installStatusTable.Column = [1, 2];
            installStatusTable.Row = row + 4;
            installStatusTable.Visible = 'off';
            obj.InstallStatusTable = installStatusTable;
        end


    end

    methods(Access = protected)
        function installButtonPushedFcn(obj, ~, ~)
            % installButtonPushedFcn  is callback function for Install
            % button

            % pre-install setup
            obj.preInstall();

            % start download and install process
            obj.install();

            % post-install setup
            obj.postInstall();
        end

        function preInstall(obj)
            % preInstall used to Disable relevant buttons before
            % installation. This method can be overwritten for
            % supportpackage requirements

            obj.NextButton.Enable = 'off';
            obj.InstallButton.Enable = 'off';
        end

        function postInstall(obj)
            %postInstall used to run the setup post installation process.
            %this includes update the ui based on the install status.

            % If all TpTools are not installed, set the Install button text to Retry
            if ~matlab.hwmgr.internal.util.areAllTpToolsInstalled(obj.InstructionSets)
                obj.updateInstallButtonForRetry();
            else
                obj.updateInstallStatusForSuccess();
            end
            % Enable the buttons
            obj.enableButtons();
        end

        function install(obj, ~, ~)
            %install  starts the install of thirdparty tools

             try
                for i = 1:numel(obj.InstructionSets)
                    tpName = obj.TpDownloadAndInstallTable.Name{i};
                    if ~obj.InstructionSets{i}.isInstalled
                        obj.setBusy(i);
                        obj.logMessage(['Installing ' tpName]);
                        [status, msg] = obj.InstructionSets{i}.install;
                        if ~status
                            obj.setFail(i, tpName, msg);
                            continue;
                        end
                        obj.logMessage(['Registering ' tpName]);
                        [status, msg] = obj.register(obj.InstructionSets{i});
                        if status
                            obj.setSuccess(i);
                        else
                            obj.setFail(i, tpName, msg);
                        end
                    else
                        obj.setSuccess(i);
                    end
                end
            catch
                % Ignore exception here as TemplateBase displays the errordlg
                % Enable the buttons in case of any errors
                obj.updateInstallButtonForRetry();
            end
        end

        function [status, msg ] = register(obj, instructionSetobj)
            %register - Registers a third-party tool by creating a registry
            % file with installation details.

            spkgRoot = matlabshared.supportpkg.internal.getSupportPackageRootNoCreate();
            name = instructionSetobj.getInstructionSetName;
            [~, arch, ~] = fileparts(instructionSetobj.getFilePath);
            registryFileLocation = fullfile(spkgRoot, 'appdata', '3p', arch, name);
            registryFileName = fullfile(registryFileLocation, [name, '_install_info.txt']);
            % Create the registry file with installation details.
            [status, msg] = obj.createRegistryFile(instructionSetobj, registryFileLocation, registryFileName);
        end

        function [status, msg] = createRegistryFile(obj, instructionSetobj,...
                registryFileLocation, registryFileName)
            %createRegistryFile Creates and updates a registry file for
            % a third-party tool installation.

            status = true;
            msg = '';
            try
                if ~exist(registryFileLocation, 'dir')
                    [status, msg] = mkdir(registryFileLocation);
                    if ~status
                        error(message('hwsetup:thirdpartytools:FolderCreationError', name, msg));
                    end
                end
                [fid, ~] = fopen(registryFileName, 'w');
                if fid < 0
                    msg = message('hwsetup:thirdpartytools:RegisterError', obj.TpToolName).getString;
                    status = false;
                    return;
                end
                fprintf(fid, 'installLocation = %s', instructionSetobj.getInstallFolder);
                fclose(fid);
                [fid, ~] = fopen(fullfile(registryFileLocation, '.installedWithHWSetup'), 'w');
                fclose(fid);
            catch ex
                % If any error occurs during the process, catch the exception,
                % set the status to false, and prepare the error message.
                status = false;
                msg = message('hwsetup:thirdpartytools:RegisterError', obj.TpToolName).getString;
            end
        end

        function updateInstructionSets(obj, newValue)
            %UPDATEINSTRUCTIONSETS method updates both the
            % InstructionSetNames (conceptually) and InstructionSets Object
            % It assumes derived classes have updated the list of
            % InstructionSetNames accordingly.

            obj.InstructionSetNames = newValue;
            % Update InstructionSets based on the new InstructionSetNames
            obj.InstructionSets = obj.Workflow.getInstructionSet(newValue);
        end

        function enableButtons(obj)
            %enableButtons used to enable the navigation buttons

            obj.NextButton.Enable = 'on';
            obj.InstallButton.Enable = 'on';
            obj.CancelButton.Enable = 'on';
        end

        function updateInstallButtonForRetry(obj)
            % updateInstallButtonForRetry method update install button for
            % retry upon failure

            
            obj.InstallButton.Enable = 'on';
            obj.InstallButton.Text = message('hwsetup:template:RetryButtonText').getString;
            obj.InstallDescriptionLabel.Text = message('hwsetup:template:AutoDownloadAndInstallRetryDescription').getString;
            filePath = strrep(['file:/' obj.Workflow.HWSetupLogger.FilePath],'\','/');
            obj.HelpText.Additional = ['<br><h1>' message('hwsetup:template:TroubleshootingTitleText').getString ...
                '</h1>' message('hwsetup:template:TroubleshootingInfo', filePath).getString];
            obj.InstallStatusTable.Steps = {message('hwsetup:thirdpartytools:InstallStatusError').getString()};
            obj.InstallStatusTable.Status = {matlab.hwmgr.internal.hwsetup.StatusIcon.Fail};
            obj.InstallStatusTable.Visible = 'on';
            obj.NextButton.Enable = 'off';
        end

        function updateInstallStatusForSuccess(obj)
            %updateInstallStatusForSuccess method to update the install
            %status to sucess upon sucessful install

            obj.InstallStatusTable.Steps = {message('hwsetup:template:InstallSuccessMessage').getString()};
            obj.InstallStatusTable.Status = {matlab.hwmgr.internal.hwsetup.StatusIcon.Pass};
            obj.InstallStatusTable.Visible = 'on';
        end

        function setBusy(obj, idx)
            %setBusy Set the busy status for the 3P tool when starting the
            % download and install

            obj.TpDownloadAndInstallTable.Status{idx} = matlab.hwmgr.internal.hwsetup.StatusIcon.Busy;
        end

        function setFail(obj, idx, tpName, msg)
            %SETFAIL Set the failed icon in status

            obj.logMessage(['Error Downloading ' tpName ' ' msg]);
            obj.TpDownloadAndInstallTable.Status{idx} = matlab.hwmgr.internal.hwsetup.StatusIcon.Fail;
        end

        function setSuccess(obj, idx)
            %setSuccess Set the pass icon in status and clear error
            % messages if any

            obj.TpDownloadAndInstallTable.Status{idx} = matlab.hwmgr.internal.hwsetup.StatusIcon.Pass;
        end

        function out = getAll3PToolsToInstall(obj)
            %getAll3PToolsToInstall find all 3P tools to install

            out = {};
            for i = 1:numel(obj.InstructionSets)
                if ~obj.InstructionSets{i}.isInstalled
                    out{end+1} = obj.InstructionSets{i}; %#ok<AGROW>
                end
            end
        end

        function initializeWidgets(obj)
            %initializeWidgets method to set values for UI components in
            % the setup screen.

            obj.Title.Text = getString(message('hwsetup:template:AutoInstallTitle'));

            obj.DescriptionLabel.Text = getString(message('hwsetup:template:AutoDownloadAndInstallDescription'));

            obj.InstallDescriptionLabel.Text = getString(message('hwsetup:template:AutoDownloadAndInstallInstallDescription'));

            obj.InstallButton.Color = matlab.hwmgr.internal.hwsetup.util.Color.BackgroundColorHighlightFocus;
            obj.InstallButton.FontColor = matlab.hwmgr.internal.hwsetup.util.Color.ColorTertiary;
            obj.InstallButton.Text = getString(message('hwsetup:template:InstallButtonText'));

            obj.HelpText.AboutSelection = '';

            obj.HelpText.WhatToConsider = getString(message('hwsetup:template:AutoDownloadAndInstallWhatToConsider'));

            [tpToolNames, licenseURLs] = matlab.hwmgr.internal.hwsetup.util.getNamesAndLicenseForTools(obj.InstructionSets, false);

            obj.TpDownloadAndInstallTable.Status = repmat({''}, 1,  numel(tpToolNames));
            obj.TpDownloadAndInstallTable.Name = tpToolNames;
            obj.TpDownloadAndInstallTable.LicenseURL = licenseURLs;
        end
    end % END protected method
end% END class
