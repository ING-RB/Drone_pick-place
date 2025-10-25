classdef WriteToHardware < matlab.hwmgr.internal.hwsetup.TemplateBase
    % WRITETOHARDWARE - Template to enable the writing of firmware, App,
    % bitstream etc. to the hardware device
    %
    % WRITETOHARDWARE Properties
    %   Title(Inherited)  Title for the screen specified as a Label widget
    %   Description       Description for the screen specified as a Label
    %                     widget
    %   WriteProgress     Progress bar to indicate the percentage of
    %                     activity complete specified as a ProgressBar
    %                     widget
    %   WriteButton       Button that on-click initiates the write activity
    %
    %   WRITETOHARDWARE Methods(Inherited)
    %   show                Display the template/screen
    %   logMessage          log diagnostic messages to a file
    %   getNextScreenID     Return the Next Screen ID (name of the class)
    %   getPreviousScreenID Return the Previous Screen ID (name of the class)

    % Copyright 2016-2021 The MathWorks, Inc.

    properties(Access = {?matlab.hwmgr.internal.hwsetup.TemplateBase,...
            ?hwsetuptest.util.TemplateBaseTester})
        % Description - Description for the screen (Label)
        Description

        % WriteProgress - Progress Bar indicating the % of activity
        % complete. for activities where it is not possible to estimate the
        % percent of activity complete, the progress bar can be made
        % non-deterministic by setting Indeterminate property to true (ProgressBar)
        WriteProgress

        % WriteButton - Button that on click begins the activity of writing
        % to the hardware (Button)
        WriteButton
    end

    methods
        function obj = WriteToHardware(varargin)
            obj@matlab.hwmgr.internal.hwsetup.TemplateBase(varargin{:});

            if obj.TemplateLayout == matlab.hwmgr.internal.hwsetup.TemplateLayout.GRID
                widgetParent = obj.ContentGrid;
            else
                widgetParent = obj.ContentPanel;
            end

            obj.Description = matlab.hwmgr.internal.hwsetup.Label.getInstance(widgetParent);
            obj.WriteProgress = matlab.hwmgr.internal.hwsetup.ProgressBar.getInstance(widgetParent);
            obj.WriteButton = matlab.hwmgr.internal.hwsetup.Button.getInstance(widgetParent);

            % Set Title
            obj.Title.Text = '<Write Firmware>';

            % Set Description Properties
            obj.Description.Text = ['<The write process will download a Linux image on the SD Card.',...
                'The write operation can take several minutes.>'];
            % Set WriteProgress Properties
            obj.WriteProgress.Value = 0;

            % Set WriteProgress Properties
            obj.WriteButton.Text = 'Write';
            obj.WriteButton.Color = matlab.hwmgr.internal.hwsetup.util.Color.BackgroundColorHighlightFocus;
            obj.WriteButton.FontColor = matlab.hwmgr.internal.hwsetup.util.Color.ColorTertiary;

            if obj.TemplateLayout == matlab.hwmgr.internal.hwsetup.TemplateLayout.GRID
                % set up grid layout
                obj.ContentGrid.RowHeight = {'fit', 22};
                obj.ContentGrid.ColumnWidth = {'1x', 100};

                % arrange widgets
                obj.Description.Row = 1;
                obj.Description.Column = [1, 2];

                obj.WriteProgress.Row = 2;
                obj.WriteProgress.Column = 1;

                obj.WriteButton.Row = 2;
                obj.WriteButton.Column = 2;
            else
                % set widget positions
                obj.Description.Position = [20, 320, 430, 50];
                obj.WriteProgress.Position = [20, 256, 300, 22];
                obj.WriteButton.Position = [350, 250, 86, 22];
            end
        end
    end
end