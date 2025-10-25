classdef VerifyHardwareSetup < matlab.hwmgr.internal.hwsetup.TemplateBase
    % VERIFYHARDWARESETUP - Template to enable the creation of screen that
    % lets users to enable the end-user to detect the devices, drives(SD card),
    % serial ports etc. connected to the host machine.
    %
    % VERIFYHARDWARESETUP Properties
    %   Title(Inherited)    Title for the screen specified as a Label widget
    %   DeviceInfoTable     Table that displays the device specific
    %                       information
    %   StatusTable         Table that displays the steps executed to test
    %                       connection to the device, the status for each
    %                       step and any additional information for each
    %                       step
    %   TestConnButton      Button that on click initiates the process of
    %                       testing connection to the device.
    %
    %   VERIFYHARDWARESETUP Methods(Inherited)
    %   show                Display the template/screen
    %   logMessage          log diagnostic messages to a file
    %   getNextScreenID     Return the Next Screen ID (name of the class)
    %   getPreviousScreenID Return the Previous Screen ID (name of the class)

    % Copyright 2016-2021 The MathWorks, Inc.

    properties(Access = {?matlab.hwmgr.internal.hwsetup.TemplateBase,...
            ?hwsetuptest.util.TemplateBaseTester})
        % DeviceInfoTable - Device information like COM Port, IP Address
        % etc.  (DeviceInfoTable)
        DeviceInfoTable
        % StatusTable - Steps, Status and additional information per step
        % for each activity performed when testing the connection to the
        % device (StatusTable)
        StatusTable
        % TestConnButton - Button that on-click initiates the Test
        % Connection callback (Button)
        TestConnButton
    end

    methods
        function obj = VerifyHardwareSetup(varargin)
            obj@matlab.hwmgr.internal.hwsetup.TemplateBase(varargin{:});

            if obj.TemplateLayout == matlab.hwmgr.internal.hwsetup.TemplateLayout.GRID
                widgetParent = obj.ContentGrid;
            else
                widgetParent = obj.ContentPanel;
            end

            % Create the widgets and parent them to the content panel
            obj.DeviceInfoTable = matlab.hwmgr.internal.hwsetup.DeviceInfoTable.getInstance(widgetParent);
            obj.StatusTable = matlab.hwmgr.internal.hwsetup.StatusTable.getInstance(widgetParent);
            obj.TestConnButton = matlab.hwmgr.internal.hwsetup.Button.getInstance(widgetParent);

            % set Title
            obj.Title.Text = '<Test Hardware Connection>';

            % set DeviceInfoTable properties
            obj.DeviceInfoTable.ColumnWidth = 285;

            % set StatusTable properties
            obj.StatusTable.ColumnWidth = [20, 410];

            % set Test Connection Button
            obj.TestConnButton.Text = '<Test Connection>';
            obj.TestConnButton.Color = matlab.hwmgr.internal.hwsetup.util.Color.BackgroundColorHighlightFocus;
            obj.TestConnButton.FontColor = matlab.hwmgr.internal.hwsetup.util.Color.ColorTertiary;

            if obj.TemplateLayout == matlab.hwmgr.internal.hwsetup.TemplateLayout.GRID
                % set up grid layout
                obj.ContentGrid.RowHeight = {100, 22, 100};
                obj.ContentGrid.ColumnWidth = {140, '1x'};

                % arrange widgets
                obj.DeviceInfoTable.Row = 1;
                obj.DeviceInfoTable.Column = [1, 2];

                obj.TestConnButton.Row = 2;
                obj.TestConnButton.Column = 1;

                obj.StatusTable.Row = 3;
                obj.StatusTable.Column = [1, 2];
            else
                % set widget positions
                % 390 pixels - Total height of root panel, 390-20(offset)-64(height of DIT)
                % 470 pixels - Total width of root panel, 20 offset in left and
                % right gives 430 as total width
                obj.DeviceInfoTable.Position = [20, 280, 430, 90];
                obj.StatusTable.Position = [20, 120, 430, 100];% 306 -20(offset) -64(height of ST)
                obj.TestConnButton.Position = [20, 250, 143, 22];
            end
        end
    end
end
