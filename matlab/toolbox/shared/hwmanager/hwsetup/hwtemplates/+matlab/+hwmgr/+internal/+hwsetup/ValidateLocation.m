classdef ValidateLocation < matlab.hwmgr.internal.hwsetup.TemplateBase
    % VALIDATELOCATION - Template to enable the creation of screen that
    % lets users to enable the end-user to validate a particular location
    % in the filesystem (may be third party software install location).
    %
    % ValidateLocation Properties
    %   Title(Inherited)    Title for the screen specified as a Label widget
    %   Description         Description for the screen specified as a Label
    %                       widget.
    %   ValidateEditText    Text box area to show install location that has
    %                       to be validated.
    %   BrowseButton        Button that on press opens a filesystem browser
    %                       for user to pick the correct install location.
    %
    %   ValidateLocation Methods(Inherited)
    %   show                Display the template/screen
    %   logMessage          log diagnostic messages to a file
    %   getNextScreenID     Return the Next Screen ID (name of the class)
    %   getPreviousScreenID Return the Previous Screen ID (name of the class)

    % Copyright 2016-2021 The MathWorks, Inc.

    properties(Access = {?matlab.hwmgr.internal.hwsetup.TemplateBase,...
            ?hwsetuptest.util.TemplateBaseTester})
        % Description - Description for the screen (Label)
        Description
        % ValidateEditText - Text box area to show install location that has
        % to be validated.
        ValidateEditText
        % BrowseButton - Button that on press opens a filesystem browser
        % for user to pick the correct install location.
        BrowseButton
    end

    methods
        function obj = ValidateLocation(varargin)
            obj@matlab.hwmgr.internal.hwsetup.TemplateBase(varargin{:});

            if obj.TemplateLayout == matlab.hwmgr.internal.hwsetup.TemplateLayout.GRID
                widgetParent = obj.ContentGrid;
            else
                widgetParent = obj.ContentPanel;
            end

            % Create the widgets and parent them to the content panel
            obj.Description = matlab.hwmgr.internal.hwsetup.Label.getInstance(widgetParent);
            obj.ValidateEditText = matlab.hwmgr.internal.hwsetup.EditText.getInstance(widgetParent);
            obj.BrowseButton = matlab.hwmgr.internal.hwsetup.Button.getInstance(widgetParent);

            % Set Title
            obj.Title.Text = '<Validate the location of installed 3P software>';

            % Set Description Properties
            obj.Description.Text = '<Specify the installation location of third party software>' ;
            obj.Description.Color = matlab.hwmgr.internal.hwsetup.util.Color.BackgroundColorInput;

            % Set ValidateEditText Properties
            obj.ValidateEditText.TextAlignment = 'left';

            % Set BrowseButton Properties
            obj.BrowseButton.Text = message('hwsetup:template:ValidateLocationBrowseButtonText').getString;
            obj.BrowseButton.Color = matlab.hwmgr.internal.hwsetup.util.Color.BackgroundColorHighlightFocus;
            obj.BrowseButton.FontColor = matlab.hwmgr.internal.hwsetup.util.Color.ColorTertiary;
            obj.BrowseButton.ButtonPushedFcn = @obj.browseDirectory;

            % Set helpText Properties - Show only WhatToConsider section by default and remove
            % AboutSelection
            obj.HelpText.AboutSelection = '';
            obj.HelpText.WhatToConsider = ['&lt;If location shown is',...
                ' incorrect, please browse and select the correct the location.>'];

            if obj.TemplateLayout == matlab.hwmgr.internal.hwsetup.TemplateLayout.GRID
                % set up grid layout
                obj.ContentGrid.RowHeight = {'fit', 22};
                obj.ContentGrid.ColumnWidth = {'1x', 70};

                % arrange widgets
                obj.Description.Row = 1;
                obj.Description.Column = [1, 2];

                obj.ValidateEditText.Row = 2;
                obj.ValidateEditText.Column = 1;

                obj.BrowseButton.Row = 2;
                obj.BrowseButton.Column = 2;
            else
                % set widget positions
                obj.Description.Position = [20, 310, 430, 60];
                obj.ValidateEditText.Position = [20, 310, 300, 20];
                obj.BrowseButton.Position = [340, 310, 70, 22];
            end
        end

        function browseDirectory(obj, ~, ~)
            % browseDirectory - Callback when browse button is pushed that launches the
            % file browsing window set to the directory indicated by obj.ValidateEditText.Text
            dir = uigetdir(obj.ValidateEditText.Text);

            if dir % If the user cancel's the file browser, uigetdir returns 0.
                % When a new location is selected, then set that location value
                % back to show it in edit text area. (ValidateEditText.Text).
                obj.ValidateEditText.Text = dir;
            end
        end
    end
end