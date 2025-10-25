classdef ManualDownloadTpTools < matlab.hwmgr.internal.hwsetup.TemplateBase
    % MANUALDOWNLOADTPTOOLS - Template to enable the creation of screen that
    % lets users to enable the end-user to list instructions to manually
    % download third-party tools
    %
    % DownloadAndInstallTpTools Properties
    %   Title(Inherited)            Title for the screen specified as a Label 
    %                               widget
    %
    %   Description                 Label widget to specify description
    %
    %   Location                    Edit box to display location entered
    %
    %   BrowseButton                Button to open file browser to specify
    %                               third-party tool location
    %
    %   DownloadAndInstallStatus    Text to display status/error
    %
    %   ManualDownloadTpTools Methods(Inherited)
    %   show                Display the template/screen
    %   logMessage          log diagnostic messages to a file
    %   getNextScreenID     Return the Next Screen ID (name of the class)
    %   getPreviousScreenID Return the Previous Screen ID (name of the class)

    % Copyright 2022 The MathWorks, Inc.

    properties(Access = {?matlab.hwmgr.internal.hwsetup.TemplateBase,...
            ?hwsetuptest.util.TemplateBaseTester})
        % Description- Description for the screen (Label)
        Description

        % Location- edit box to display location
        Location

        % BrowseButton- Button to open file browser to specify third-party 
        % tool location
        BrowseButton

        % DownloadAndInstallStatus- Text to display status/error 
        DownloadAndInstallStatus
    end

    methods
        function obj = ManualDownloadTpTools(varargin)
            obj@matlab.hwmgr.internal.hwsetup.TemplateBase(varargin{:});

            if obj.TemplateLayout == matlab.hwmgr.internal.hwsetup.TemplateLayout.GRID
                widgetParent = obj.ContentGrid;
            else
                widgetParent = obj.ContentPanel;
            end

            % Create the widgets and parent them to the content panel
            obj.Description = matlab.hwmgr.internal.hwsetup.HTMLText.getInstance(widgetParent);
            obj.Location = matlab.hwmgr.internal.hwsetup.EditText.getInstance(widgetParent);
            obj.BrowseButton = matlab.hwmgr.internal.hwsetup.Button.getInstance(widgetParent);
            obj.DownloadAndInstallStatus = matlab.hwmgr.internal.hwsetup.HTMLText.getInstance(widgetParent);

            % set Title
            obj.Title.Text = '<Instructions to Download Third-Party Tools>';

            % Description properties
            obj.Description.Text = ['The following third-party tools need to be installed.',...
                'Click the Install button to start the install process.'];

            % Location properties
            obj.Location.TextAlignment = 'left';

            % Install button properties
            obj.BrowseButton.Color = matlab.hwmgr.internal.hwsetup.util.Color.BackgroundColorHighlightFocus;
            obj.BrowseButton.FontColor = matlab.hwmgr.internal.hwsetup.util.Color.ColorTertiary;
            obj.BrowseButton.Text = 'Browse';

            % Install status properties
            obj.DownloadAndInstallStatus.Text = 'Install status';

            % Set HelpText Properties - Show only WhatToConsider section by
            %default and remove AboutSelection
            obj.HelpText.AboutSelection = '';
            obj.HelpText.WhatToConsider =  ['The installation process will take between 10 and 20 minutes and may require User Account Control permissions.',...
                'If this request times out, the installation will fail.',...
                'Watch the complete installation to ensure that this step completes correctly.'];

            if obj.TemplateLayout == matlab.hwmgr.internal.hwsetup.TemplateLayout.GRID
                % set up grid layout
                obj.ContentGrid.RowHeight = {'fit', 22, 'fit'};
                obj.ContentGrid.ColumnWidth = {'1x', 100};

                % arrange widgets
                obj.Description.Row = 1;
                obj.Description.Column = [1, 2];

                obj.Location.Row = 2;
                obj.Location.Column = 1;

                obj.BrowseButton.Row = 2;
                obj.BrowseButton.Column = 2;

                obj.DownloadAndInstallStatus.Row = 3;
                obj.DownloadAndInstallStatus.Column = 1;
            else
                % set widget positions
                obj.Description.Position = [20, 250, 430, 130];
                obj.Location.Position = [20, 310, 300, 22];
                obj.BrowseButton.Position = [340, 310, 70, 22];
                obj.DownloadAndInstallStatus.Position = [20, 150, 320, 150];
            end
        end
    end
end