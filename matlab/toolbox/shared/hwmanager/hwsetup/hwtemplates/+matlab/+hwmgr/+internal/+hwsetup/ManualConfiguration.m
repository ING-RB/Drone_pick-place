classdef ManualConfiguration < matlab.hwmgr.internal.hwsetup.TemplateBase
    % MANUALCONFIGURATION - Template to enable the creation of screen that
    % guides the user to perform hardware-host, on-host connections etc.
    %
    % MANUALCONFIGURATION Properties
    %   Title(Inherited)            Title for the screen specified as a Label widget
    %   ConfigurationInstructions   Instructions for the users specified as
    %                               a Label widget
    %   ConfigurationImage          Annotated Image to better illustrate
    %                               the Instructions specified as an Image
    %                               widget
    %   MANUALCONFIGURATION Methods(Inherited)
    %   show                Display the template/screen
    %   logMessage          log diagnostic messages to a file
    %   getNextScreenID     Return the Next Screen ID (name of the class)
    %   getPreviousScreenID Return the Previous Screen ID (name of the class)

    %  Copyright 2016-2021 The MathWorks, Inc.
    
    properties(Access = {?matlab.hwmgr.internal.hwsetup.TemplateBase,...
            ?hwsetuptest.util.TemplateBaseTester})
        % ConfigurationInstructions - Instructions for the user to help
        % them set up their hardware connections, preferably listed as a
        % numbered list (Label)
        ConfigurationInstructions
        % ConfigurationImage - Image to illustrate the instructions (Image)
        ConfigurationImage
    end

    methods
        function obj = ManualConfiguration(varargin)
            obj@matlab.hwmgr.internal.hwsetup.TemplateBase(varargin{:});

            if obj.TemplateLayout == matlab.hwmgr.internal.hwsetup.TemplateLayout.GRID
                widgetParent = obj.ContentGrid;
            else
                widgetParent = obj.ContentPanel;
            end

            obj.ConfigurationInstructions = matlab.hwmgr.internal.hwsetup.Label.getInstance(widgetParent);
            obj.ConfigurationImage = matlab.hwmgr.internal.hwsetup.Image.getInstance(widgetParent);

            obj.Title.Text = '<Manual Configuration>';

            obj.ConfigurationInstructions.Text = ['<Make connections as shown in the figure.', newline ...
                '1. Lorem ipsum dolor sit amet, consectetur adipiscing elit Curabitur finibus eros risus, sit amet iaculis metus egestas placerat.',...
                newline,...
                '2. Nunc pellentesque aliquam dui, eget rhoncus magna sodales id.', newline,...
                ':>'];

            if obj.TemplateLayout == matlab.hwmgr.internal.hwsetup.TemplateLayout.GRID
                % set up grid layout
                obj.ContentGrid.RowHeight = {'fit', 'fit'};
                obj.ContentGrid.ColumnWidth = {'1x'};

                % arrange widgets
                obj.ConfigurationInstructions.Row = 1;
                obj.ConfigurationImage.Row = 2;
            else
                % set widget positions
                obj.ConfigurationInstructions.Position = [20, 200, 430, 175];
                obj.ConfigurationImage.Position = [20, 20, 230, 165];
            end
        end
    end
end