classdef ManualDownload < matlab.hwmgr.internal.hwsetup.TemplateBase
    % MANUALDOWNLOAD - Template to enable the creation of a screen that
    % provides end-users with instructions to manually download third-party
    % tools.
    %
    % ManualDownload Properties:
    %   Title(Inherited)               - Title for the screen specified as a Label
    %                                    widget.
    %
    %   DescriptionLabel               - Description label for the setup screen.
    %
    %   TpDownloadAndInstallTable      - Table widget listing third-party software tools
    %                                    to be downloaded along with their respective
    %                                    licenses and download links.
    %
    %   ValidateDescriptionLabel       - Label for the validation section description.
    %
    %   LocationEditText               - Edit text box for users to enter
    %                                    the download location.
    %
    %   BrowseButton                   - Button to browse for the download location.
    %
    %   ValidateButton                 - Button to initiate validation of the third-party
    %                                    tool downloads.
    %
    %   ValidationStatusTable          - Widget to display the validation status
    %
    % ManualDownloadAndInstall Methods(Inherited):
    %   show                           - Display the template/screen.
    %   logMessage                     - Log diagnostic messages to a file.
    %   getNextScreenID                - Return the Next Screen ID (name of the class).
    %   getPreviousScreenID            - Return the Previous Screen ID (name of the class).
    %
    % See also
    % matlab.hwmgr.internal.hwsetup.thirdpartytools.ManualDownloadAndInstall,
    % matlab.hwmgr.internal.hwsetup.thirdpartytools.AutoInstall,
    % matlab.hwmgr.internal.hwsetup.thirdpartytools.AutoDownloadAndInstall
    %

    % Copyright 2024 The MathWorks, Inc.

    properties(Access = {?matlab.hwmgr.internal.hwsetup.TemplateBase,...
            ?hwsetuptest.util.TemplateBaseTester,...
            ?hwsetup.testtool.StandardTestCase})

        % DescriptionLabel - Description label for the setup screen.
        DescriptionLabel

        % TpDownloadAndInstallTable - Table widget listing third-party software tools to be downloaded.
        TpDownloadAndInstallTable

        % ValidateDescriptionLabel - Label for the validation section description.
        ValidateDescriptionLabel

        % LocationEditText - Edit text box for users to enter the installation location.
        LocationEditText

        % BrowseButton - Button to browse for installation location.
        BrowseButton

        % ValidateButton - Button to initiate validation of the third-party tool installation.
        ValidateButton

        % ValidationStatusTable - Widget to display the validation status, typically as HTML text.
        ValidationStatusTable

        % BusyOverlay - Widget to enable busy overlay
        BusyOverlay

        % DownloadFolder
        DownloadFolder
    end

    properties(Abstract, Access = protected)
        % InstructionSetNames - cell array of the instruction set names used
        % by this template
        InstructionSetNames (1, :) cell
    end

    properties(Access = protected)
        % Property to hold the object representing the instruction set
        InstructionSetObj
    end

    methods
        function obj = ManualDownload(varargin)

            obj@matlab.hwmgr.internal.hwsetup.TemplateBase(varargin{:});
            obj.TemplateLayout =  matlab.hwmgr.internal.hwsetup.TemplateLayout.GRID;

            % Retrieve the matching InstructionSet object by name for the
            obj.InstructionSetObj = obj.Workflow.getInstructionSet(obj.InstructionSetNames);

            % create all the UI widgets for the template
            obj.createWidgets();

            % Set values to the UI components reflecting the manual download and
            % install instructions for the third-party (tp) tool
            obj.initializeWidgets();
        end
    end

    methods(Access = private)

        function createWidgets(obj)
            %createWidgets method to create UI components for the setup screen.

            obj.ContentGrid.Visible = 'on';
            widgetParent = obj.ContentGrid;

            obj.ContentGrid.RowHeight = {'fit', 'fit', 34, 24, 24, 'fit'};
            obj.ContentGrid.ColumnWidth = {100, '1x', 100};

            row = 1;

            % Create the main description label and set its properties
            mainDescription = matlab.hwmgr.internal.hwsetup.Label.getInstance(widgetParent);
            mainDescription.Column = [1, 3];
            mainDescription.Row = row;
            obj.DescriptionLabel = mainDescription;

            % Create the table for third-party tool download and installation
            tpDownloadandInstallTable = matlab.hwmgr.internal.hwsetup.TpDownloadTable.getInstance(widgetParent);
            tpDownloadandInstallTable.Column = [1, 3];
            tpDownloadandInstallTable.Row = row + 1;
            tpDownloadandInstallTable.Version={};
            obj.TpDownloadAndInstallTable = tpDownloadandInstallTable;

            % Create the validation description label and set its properties
            validationDescription = matlab.hwmgr.internal.hwsetup.Label.getInstance(widgetParent);
            validationDescription.Column = [1, 3];
            validationDescription.Row = row + 2;
            obj.ValidateDescriptionLabel = validationDescription;

            % Create the edit text field for the installation location
            location = matlab.hwmgr.internal.hwsetup.EditText.getInstance(widgetParent);
            location.Column = [1, 2];
            location.Row = row + 3;

            obj.LocationEditText = location;

            % Create the browse button and set its properties
            browseButton = matlab.hwmgr.internal.hwsetup.Button.getInstance(widgetParent);
            browseButton.Column = 3;
            browseButton.Row = row + 3;
            browseButton.ButtonPushedFcn =  @(~, ~)obj.browseButtonPushedFcn;
            obj.BrowseButton = browseButton;

            % Create the validate button and assign its callback function
            validateButton = matlab.hwmgr.internal.hwsetup.Button.getInstance(widgetParent);
            validateButton.ButtonPushedFcn = @obj.validateButtonPushedFcn; % Callback function for when the button is pressed
            validateButton.Column = 1;
            validateButton.Row = row + 4;
            obj.ValidateButton = validateButton;

            % Create the status table for validation feedback and set its properties
            validateStatusTable = matlab.hwmgr.internal.hwsetup.StatusTable.getInstance(widgetParent);
            validateStatusTable.Column = [1, 3];
            validateStatusTable.Row = row + 5;
            validateStatusTable.Visible = 'off';
            validateStatusTable.Border = 'off';
            obj.ValidationStatusTable = validateStatusTable;

            busyOverlay = matlab.hwmgr.internal.hwsetup.BusyOverlay.getInstance(obj.Workflow.Window);
            busyOverlay.Text = '';
            busyOverlay.Visible = 'off';
            obj.BusyOverlay = busyOverlay;
        end

      

        function updateTpDownloadAndInstallTable(obj)
            % UPDATETPDOWNLOADANDINSTALLTABLE Updates the table with
            % third-party tool names, license URLs, and installation status.

            displayNames = cellfun(@(x) x.getDisplayName(), obj.InstructionSetObj, 'UniformOutput', false);
            downloadurl = cellfun(@(x) x.getDownloadUrl(), obj.InstructionSetObj, 'UniformOutput', false);
            htmlLinks = cellfun(@(url) ['<a href="' url '">Link</a>'], downloadurl, 'UniformOutput', false);
            obj.TpDownloadAndInstallTable.Name = displayNames;
            obj.TpDownloadAndInstallTable.Details = htmlLinks;
        end
    end

    methods(Access = protected)

          function initializeWidgets(obj)
            % initializeWidgets method to set values for UI components in the setup screen.

            obj.Title.Text = getString(message('hwsetup:template:ManualDownloadTitle'));

            obj.DescriptionLabel.Text = getString(message('hwsetup:template:ManualDownloadDescription'));

            obj.LocationEditText.TextAlignment = 'left';

            obj.ValidateDescriptionLabel.Text = getString(message('hwsetup:template:ManualDownloadValidateDescription'));

            obj.BrowseButton.Color = matlab.hwmgr.internal.hwsetup.util.Color.BackgroundColorHighlightFocus;
            obj.BrowseButton.FontColor = matlab.hwmgr.internal.hwsetup.util.Color.ColorTertiary;
            obj.BrowseButton.Text = getString(message('hwsetup:template:ValidateLocationBrowseButtonText'));

            obj.ValidateButton.Color = matlab.hwmgr.internal.hwsetup.util.Color.BackgroundColorHighlightFocus;
            obj.ValidateButton.FontColor = matlab.hwmgr.internal.hwsetup.util.Color.ColorTertiary;
            obj.ValidateButton.Text = getString(message('hwsetup:template:ValidateButtonText'));

            obj.HelpText.AboutSelection = '';

            obj.HelpText.WhatToConsider = getString(message('hwsetup:template:ManualDownloadWhatToConsider'));

            [displayNames, htmlLinks] = matlab.hwmgr.internal.hwsetup.util.getNamesAndLicenseForTools(obj.InstructionSetObj, true);
            obj.TpDownloadAndInstallTable.Name = displayNames;
            obj.TpDownloadAndInstallTable.Details = htmlLinks;
        end
        function browseButtonPushedFcn(obj, ~, ~)
            % browseButtonPushedFcn - This method is designed to be used as
            % callback for a Browse button to open the file explorer dialog
            % and allow the user to select a directory. Once a directory is
            % selected, the directory path is set to the 'Text' property
            % of the 'Location' widget.
            %
            % You can override this method if you want to add additional
            % functionality in this callback (not recommended)

            % Open the file explorer dialog to select a directory
            selectedPath = obj.LocationEditText.Text;
            dirName = uigetdir(selectedPath);
            
            % Check if a directory was selected (dirName is not 0)
            if dirName
                % Update the Location text field with the selected directory
                obj.LocationEditText.Text = dirName;
            end

            % Bring the main application window to the front
            obj.Workflow.Window.bringToFront();
        end

        function validateButtonPushedFcn(obj, ~, ~)
            % This function is triggered when the validate button is pushed.

            % Pre-validation setup
            obj.preValidate();

            % Validation
            obj.validate();

            % Post-validation setup
            obj.postValidate();
        end

        function preValidate(obj)
            % preValidate setup
            % disable all user interaction widgets
            obj.disableScreen();
        end

        function status = validate(obj)
            % validate method used to check if all the archives are
            % downladed in the LocationEditField Text.

            status = false;

            % Check if the specified directory exists
            if exist(obj.LocationEditText.Text, 'dir') == 7
                % Retrieve directory contents excluding '.' and '..'
                contents = dir(obj.LocationEditText.Text);
                fileNames = {contents(~ismember({contents.name}, {'.', '..'})).name};

                numMatchingArchives = 0;

                % Directly iterate through each InstructionSetObj
                for i = 1:numel(obj.InstructionSetObj)
                    % Derive the ArchiveName using the getArchiveName method
                    archiveName = obj.InstructionSetObj{i}.getArchiveName();

                    % Use vectorized comparison to check for existence
                    if any(strcmp(archiveName, fileNames))
                        % Increment counter for matching archives
                        numMatchingArchives = numMatchingArchives + 1;
                    end
                end

                % Check if all archive names have a match in the directory
                status = numMatchingArchives == numel(obj.InstructionSetObj);
            end

            if ~status
                obj.ValidateButton.Text = message('hwsetup:template:RetryButtonText').getString;
                obj.ValidateDescriptionLabel.Text = message('hwsetup:template:AutoDownloadAndInstallRetryDescription').getString;
                obj.ValidationStatusTable.Steps = {message('hwsetup:template:DownloadValidationError').getString()};
                obj.ValidationStatusTable.Status = {matlab.hwmgr.internal.hwsetup.StatusIcon.Fail};
                obj.ValidationStatusTable.Visible = 'on';
                obj.enableScreen();
                obj.NextButton.Enable = 'off';
            else
                obj.ValidationStatusTable.Steps = {message('hwsetup:template:DownloadValidationPass').getString()};
                obj.ValidationStatusTable.Status = {matlab.hwmgr.internal.hwsetup.StatusIcon.Pass};
                obj.ValidationStatusTable.Visible = 'on';
                % if all archives found copy to downloadFolder
                obj.DownloadFolder = obj.LocationEditText.Text;
                if ~exist( obj.InstructionSetObj{1}.getDownloadsFolder, 'dir')
                    mkdir( obj.InstructionSetObj{1}.getDownloadsFolder);
                end
                for k = 1:length(obj.InstructionSetObj)
                    % Create the full path for source and destination
                    src = fullfile(obj.LocationEditText.Text, obj.InstructionSetObj{k}.getArchiveName);
                    dst = fullfile(obj.InstructionSetObj{k}.getDownloadsFolder, obj.InstructionSetObj{k}.getArchiveName);
                    copyfile(src,  dst);
                end
                obj.enableScreen();
                
            end
        end

        function updateInstructionSets(obj, newValue)
            %UPDATEINSTRUCTIONSETS method updates both the
            % InstructionSetNames (conceptually) and InstructionSets Object
            % It assumes derived classes have updated the list of
            % InstructionSetNames accordingly.

            obj.InstructionSetNames = newValue;
            % Update InstructionSets based on the new InstructionSetNames
            obj.InstructionSetObj = obj.Workflow.getInstructionSet(newValue);
        end

        function postValidate(obj)
            %postValidation

            
        end
    end
end
