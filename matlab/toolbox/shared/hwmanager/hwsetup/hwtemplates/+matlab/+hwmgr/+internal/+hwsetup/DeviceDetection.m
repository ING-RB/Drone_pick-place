classdef DeviceDetection < matlab.hwmgr.internal.hwsetup.TemplateBase
    % DEVICEDETECTION - Template to enable the creation of screen that
    % lets users to enable the end-user to detect the devices, drives(SD card),
    % serial ports etc. connected to the host machine.
    %
    % DEVICEDETECTION Properties
    %   Title(Inherited)    Title for the screen specified as a Label widget
    %   Description         Description for the screen specified as a Label
    %                       widget
    %   SelectionLabel      Text describing the user to connect a device and
    %                       detection of the devices, drives, serial ports etc.
    %   SelectionDropDown   Pop-up menu to display the list of devices/drives to choose
    %                       specified as a DropDown widget
    %   RefreshButton       Button that on press refreshes the list of items
    %                       in the DropDown widget(SelectionDropDown property)
    %   ConnectionImage  Image displaying how to connect the device,
    %                       drive(SD Card) to the host machine
    %
    %   DEVICEDETECTION Methods(Inherited)
    %   show                Display the template/screen
    %   logMessage          log diagnostic messages to a file
    %   getNextScreenID     Return the Next Screen ID (name of the class)
    %   getPreviousScreenID Return the Previous Screen ID (name of the class)

    % Copyright 2016-2021 The MathWorks, Inc.

    properties(Access = {?matlab.hwmgr.internal.hwsetup.TemplateBase,...
            ?hwsetuptest.util.TemplateBaseTester})
        % Description - Description for the screen (Label)
        Description
        % SelectionLabel - Text describing the user to connect a device
        % detection of the devices, drives, serial ports etc
        SelectionLabel
        % SelectionDropDown - Pop-up menu to display the list of devices/drives to
        % choose from (DropDown)
        SelectionDropDown
        % RefreshButton - Button that on press refreshes the list of items
        % in the DropDown widget(SelectionDropDown property)
        RefreshButton
        % Image displaying how to connect the device,
        % drive(SD Card) to the host machine
        ConnectionImage
    end

    methods
        function obj = DeviceDetection(varargin)
            obj@matlab.hwmgr.internal.hwsetup.TemplateBase(varargin{:});

            if obj.TemplateLayout == matlab.hwmgr.internal.hwsetup.TemplateLayout.GRID
                widgetParent = obj.ContentGrid;
            else
                widgetParent = obj.ContentPanel;
            end

            % Create the widgets and parent them to the content panel
            obj.Description = matlab.hwmgr.internal.hwsetup.Label.getInstance(widgetParent);
            obj.SelectionLabel = matlab.hwmgr.internal.hwsetup.Label.getInstance(widgetParent);
            obj.SelectionDropDown = matlab.hwmgr.internal.hwsetup.DropDown.getInstance(widgetParent);
            obj.RefreshButton = matlab.hwmgr.internal.hwsetup.Button.getInstance(widgetParent);
            obj.ConnectionImage = matlab.hwmgr.internal.hwsetup.Image.getInstance(widgetParent);


            % Set Title
            obj.Title.Text = '<Select a Drive>';

            % Set Description Properties
            obj.Description.Text = ['<Insert the SD Card in the host computer.',...
                newline, newline,...
                'Select the drive port that corresponds to the device.>'];
            obj.Description.Color = matlab.hwmgr.internal.hwsetup.util.Color.BackgroundColorInput ;

            % Set SelectionLabel Properties
            obj.SelectionLabel.Text = '<Drive:>';
            obj.SelectionLabel.Color = matlab.hwmgr.internal.hwsetup.util.Color.BackgroundColorInput ;

            % Set RefreshButton Properties
            obj.RefreshButton.Text = message('hwsetup:template:DeviceDetectionRefreshButtonText').getString;
            obj.RefreshButton.Color = matlab.hwmgr.internal.hwsetup.util.Color.BackgroundColorHighlightFocus;
            obj.RefreshButton.FontColor = matlab.hwmgr.internal.hwsetup.util.Color.ColorTertiary;

            if obj.TemplateLayout == matlab.hwmgr.internal.hwsetup.TemplateLayout.GRID
                % set up grid layout
                obj.ContentGrid.RowHeight = {'fit', 22, 'fit'};
                obj.ContentGrid.ColumnWidth = {'fit', '1x', 70};

                % arrange widgets
                obj.Description.Row = 1;
                obj.Description.Column = [1, 3];

                obj.SelectionLabel.Row = 2;
                obj.SelectionLabel.Column = 1;

                obj.SelectionDropDown.Row = 2;
                obj.SelectionDropDown.Column = 2;

                obj.RefreshButton.Row = 2;
                obj.RefreshButton.Column = 3;

                obj.ConnectionImage.Row = 3;
                obj.ConnectionImage.Column = [1, 3];
            else
                % set widget positions
                obj.Description.Position = [20, 310, 430, 60];
                obj.SelectionLabel.Position = [20, 280, 60, 20];
                obj.SelectionDropDown.Position = [70, 280, 100, 20];
                obj.RefreshButton.Position = [190, 280, 70, 22];
                obj.ConnectionImage.Position = [20, 20, 250, 200];
            end
        end
    end
end