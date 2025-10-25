classdef ManualDownloadAndInstall < matlab.hwmgr.internal.hwsetup.TemplateBase
    % MANUALDOWNLOADANDINSTALLL - Template to enable the creation of a screen 
    % that provides end-users with instructions to manually download and 
    % install third-party tools.
    %
    % ManualDownloadAndInstall Properties:
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
    %   LocationEditText               - Edit text box for users to enter the installation
    %                                    location.
    %
    %   BrowseButton                   - Button to browse for the installation location.
    %
    %   ValidateButton                 - Button to initiate validation of the third-party
    %                                    tool installation.
    %
    %   ValidationStatusTable          - Widget to display the validation status, typically
    %                                    as HTML text.
    %
    % ManualDownloadAndInstall Methods(Inherited):
    %   show                           - Display the template/screen.
    %   logMessage                     - Log diagnostic messages to a file.
    %   getNextScreenID                - Return the Next Screen ID (name of the class).
    %   getPreviousScreenID            - Return the Previous Screen ID (name of the class).
    %
    % See also TEMPLATEBASE
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
    end

    properties(Abstract, Access = protected)

        InstructionSetName (1, 1) string
    end

    properties(Access = private)
        % instruction set obj
        % associated with this manual download and install process.
        InstructionSetObj (1, 1)
    end

    methods
        function obj = ManualDownloadAndInstall(varargin)

            obj@matlab.hwmgr.internal.hwsetup.TemplateBase(varargin{:});
            obj.TemplateLayout =  matlab.hwmgr.internal.hwsetup.TemplateLayout.GRID;

            % Retrieve the matching InstructionSet object by name for the
            % manual download and installation process
            instrsetObj = obj.Workflow.getInstructionSet(obj.InstructionSetName);
            obj.InstructionSetObj = instrsetObj{1};
            % create all the UI widgets for the template
            obj.createWidgets();            

            % Set values to the UI widgets reflecting the manual download and
            % install instructions for the third-party tool
            obj.initializeWidgets();
        end
    end

    methods(Abstract, Access = protected)

        % Abstract method to validate button is pushed callback
        validateButtonPushedFcn(obj, src, evt);
    end

    methods(Access = private)

        function createWidgets(obj)
            %createWidgets method to create UI widgets for the template
            
            obj.ContentGrid.Visible = 'on';
            widgetParent = obj.ContentGrid;
            
            % Set the row heights and column widths for the content grid
            obj.ContentGrid.RowHeight = {'fit', '1x', 34, 24, 24, '1x'};
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

        function initializeWidgets(obj)
            % initializeWidgets method to set values for UI widgets in the
            % template

            % Set the title text for the setup screen using the display name from the instruction set object
            obj.Title.Text = getString(message('hwsetup:thirdpartytools:ManualDownloadAndInstallTitle', obj.InstructionSetObj.getDisplayName));

            % Set the main description text for the setup screen
            obj.DescriptionLabel.Text = getString(message('hwsetup:thirdpartytools:ManualDownloadAndInstallDescription'));
            
            % set Location Edit Text
            obj.LocationEditText.TextAlignment = 'left';
            
            % Set the validation description text for the setup screen
            obj.ValidateDescriptionLabel.Text = getString(message('hwsetup:thirdpartytools:ManualDownloadAndInstallValidateDescription'));

            % Set the text for the browse button
            obj.BrowseButton.Color = matlab.hwmgr.internal.hwsetup.util.Color.BackgroundColorHighlightFocus;
            obj.BrowseButton.FontColor = matlab.hwmgr.internal.hwsetup.util.Color.ColorTertiary;
            obj.BrowseButton.Text = getString(message('hwsetup:template:ValidateLocationBrowseButtonText'));

            % Set the text properties for the validate button
            obj.ValidateButton.Color = matlab.hwmgr.internal.hwsetup.util.Color.BackgroundColorHighlightFocus;
            obj.ValidateButton.FontColor = matlab.hwmgr.internal.hwsetup.util.Color.ColorTertiary;
            obj.ValidateButton.Text = getString(message('hwsetup:template:ValidateButtonText'));

            % Configure the HelpText properties
            % set the AboutSelection text
            obj.HelpText.AboutSelection = '';

            % set the WhatToConsider text
            obj.HelpText.WhatToConsider = getString(message('hwsetup:thirdpartytools:ManualDownloadAndInstallWhatToConsider'));
            
            % set TpDownloadAndInstallTable
            [displayNames, htmlLinks] = matlab.hwmgr.internal.hwsetup.util.getNamesAndLicenseForTools(obj.InstructionSetObj, true);

            obj.TpDownloadAndInstallTable.Details = {obj.TpDownloadAndInstallTable.Details{1}};
            obj.TpDownloadAndInstallTable.Name = displayNames;
            obj.TpDownloadAndInstallTable.Details = htmlLinks;
            obj.TpDownloadAndInstallTable.Version = {'Not Detected'};
        end
    end

    methods(Access = protected)
        function browseButtonPushedFcn(obj, ~, ~)
            % OPENFILEEXPLORER - This method is designed to be used as
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
    end
end
