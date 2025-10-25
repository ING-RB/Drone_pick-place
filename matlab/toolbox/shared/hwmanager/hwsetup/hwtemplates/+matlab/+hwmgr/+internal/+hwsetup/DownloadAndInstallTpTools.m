classdef DownloadAndInstallTpTools < matlab.hwmgr.internal.hwsetup.TemplateBase
    % DOWNLOADANDINSTALLTPTOOLS - Template to enable the creation of screen that
    % lets users to enable the end-user to list and download third-party
    % tools
    %
    % DownloadAndInstallTpTools Properties
    %   Title(Inherited)            Title for the screen specified as a Label 
    %                               widget
    %
    %   Description                 Label widget to specify description
    %
    %   TpDownloadAndInstallTable   TpDownloadAndInstallStatusTable widget to
    %                               list third-party tools and license links
    %
    %   InstallButton               Button to start the download and
    %                               install
    %                               
    %   DownloadAndInstallStatus    Text to display status/error
    %
    %   DownloadAndInstallTpTools Methods(Inherited)
    %   show                Display the template/screen
    %   logMessage          log diagnostic messages to a file
    %   getNextScreenID     Return the Next Screen ID (name of the class)
    %   getPreviousScreenID Return the Previous Screen ID (name of the class)

    % Copyright 2022 The MathWorks, Inc.

    properties(Access = {?matlab.hwmgr.internal.hwsetup.TemplateBase,...
            ?hwsetuptest.util.TemplateBaseTester,...
            ?hwsetup.testtool.StandardTestCase})
        % Description- Description for the screen (Label)
        Description

        % TpDownloadAndInstallTable- TpDownloadAndInstallStatusTable widget
        % to list third party software tools to be downloaded
        TpDownloadAndInstallTable

        % InstallButton- Button widget to start the download and install
        % process
        InstallButton

        % DownloadAndInstallStatus- HTMLText widget to display status
        DownloadAndInstallStatus
    end

    methods
        function obj = DownloadAndInstallTpTools(varargin)
            obj@matlab.hwmgr.internal.hwsetup.TemplateBase(varargin{:});

            if obj.TemplateLayout == matlab.hwmgr.internal.hwsetup.TemplateLayout.GRID
                widgetParent = obj.ContentGrid;
            else
                widgetParent = obj.ContentPanel;
            end

            % Create the widgets and parent them to the content panel
            obj.Description = matlab.hwmgr.internal.hwsetup.Label.getInstance(widgetParent);
            obj.TpDownloadAndInstallTable = matlab.hwmgr.internal.hwsetup.TpDownloadAndInstallStatusTable.getInstance(widgetParent);
            obj.InstallButton = matlab.hwmgr.internal.hwsetup.Button.getInstance(widgetParent);
            obj.DownloadAndInstallStatus = matlab.hwmgr.internal.hwsetup.HTMLText.getInstance(widgetParent);

            % set Title
            obj.Title.Text = '<Download and Install Third-party Tools>';

            % Description properties
            obj.Description.Text = ['The following third-party tools need to be installed.',...
                'Click the Install button to start the install process.'];
            obj.Description.Color = matlab.hwmgr.internal.hwsetup.util.Color.BackgroundColorInput;

            % Install button properties
            obj.InstallButton.Text = 'Install';
            obj.InstallButton.Color = matlab.hwmgr.internal.hwsetup.util.Color.BackgroundColorHighlightFocus;
            obj.InstallButton.FontColor = matlab.hwmgr.internal.hwsetup.util.Color.ColorTertiary;

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
                obj.ContentGrid.RowHeight = {'fit', '1x', 24, '1x'};
                obj.ContentGrid.ColumnWidth = {'1x', 100};

                % arrange widgets
                obj.Description.Row = 1;
                obj.Description.Column = [1, 2];

                obj.TpDownloadAndInstallTable.Row = 2;
                obj.TpDownloadAndInstallTable.Column = [1, 2];

                obj.InstallButton.Row = 3;
                obj.InstallButton.Column = 2;

                obj.DownloadAndInstallStatus.Row = [3, 4];
                obj.DownloadAndInstallStatus.Column = 1;
            else
                % set widget positions
                obj.Description.Position = [20, 290, 430, 80];
                obj.TpDownloadAndInstallTable.Position = [20, 100, 410, 200];
                obj.InstallButton.Position = [340, 40, 80, 24];
                obj.DownloadAndInstallStatus.Position = [20, 20, 320, 60];
            end
        end
    end
end