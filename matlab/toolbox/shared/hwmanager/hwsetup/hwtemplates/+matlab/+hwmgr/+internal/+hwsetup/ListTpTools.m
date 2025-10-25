classdef ListTpTools < matlab.hwmgr.internal.hwsetup.TemplateBase
    % LISTTPTOOLS - Template to enable the creation of screen that
    % lets users to enable the end-user to list the 3P tools that needs
    % to be downloaded.
    %
    % ListTpTools Properties
    %   Title(Inherited)    Title for the screen specified as a Label widget
    %   Description         Description for the screen specified as a Label
    %                       widget.
    %   ListTpDownloadTable Table like text area specified as a TpDownloadTable
    %                       widget to list third party softwares that has
    %                       to be downloaded.
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
        %ListTpDownloadTable - TpDownloadTable widget to list third party
        %software tools to be downloaded
        ListTpDownloadTable
    end

    methods
        function obj = ListTpTools(varargin)
            obj@matlab.hwmgr.internal.hwsetup.TemplateBase(varargin{:});

            if obj.TemplateLayout == matlab.hwmgr.internal.hwsetup.TemplateLayout.GRID
                widgetParent = obj.ContentGrid;
            else
                widgetParent = obj.ContentPanel;
            end

            % Create the widgets and parent them to the content panel
            obj.Description = matlab.hwmgr.internal.hwsetup.Label.getInstance(widgetParent);
            obj.ListTpDownloadTable = matlab.hwmgr.internal.hwsetup.TpDownloadTable.getInstance(widgetParent);

            % Set Title
            obj.Title.Text = '<Install Third-Party Tools>';

            % Set Description Properties
            obj.Description.Text = '<Use of this support package requires following 3P tools:>' ;
            obj.Description.Color = matlab.hwmgr.internal.hwsetup.util.Color.BackgroundColorInput;

            % Set HelpText Properties - Show only WhatToConsider section by
            %default and remove AboutSelection
            obj.HelpText.AboutSelection = '';
            obj.HelpText.WhatToConsider = ['&lt;Do you have the listed ' ...
                'third party softwares installed on this software?'...
                'If not, click the hyperlink and download.&gt;'];

            if obj.TemplateLayout == matlab.hwmgr.internal.hwsetup.TemplateLayout.GRID
                % set up grid layout
                obj.ContentGrid.RowHeight = {'fit', 'fit'};
                obj.ContentGrid.ColumnWidth = {'1x'};

                % arrange widgets
                obj.Description.Row = 1;
                obj.ListTpDownloadTable.Row = 2;
            else
                % set widget positions
                obj.Description.Position = [20, 310, 430, 60];
                obj.ListTpDownloadTable.Position = [20, 220, 400, 100];
            end
        end
    end
end