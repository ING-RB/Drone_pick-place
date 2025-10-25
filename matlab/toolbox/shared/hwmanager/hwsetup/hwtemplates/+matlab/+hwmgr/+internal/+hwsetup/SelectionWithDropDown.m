classdef SelectionWithDropDown < matlab.hwmgr.internal.hwsetup.TemplateBase
    % SELECTIONWITHDROPDOWN - Template to enable the creation of screen that
    % lets users select the type of hardware, device, board etc.
    %
    % SELECTIONWITHDROPDOWN Properties
    %   Title(Inherited)  Title for the screen specified as a Label widget
    %   Description       Description for the screen specified as a Label
    %                     widget
    %   SelectionDropDown Pop-up menu to display the list of items to choose
    %                     specified as a DropDown widget
    %   SelectionLabel     Text describing the category of the items in the
    %                      pop-up menu e.g. hardware, devices etc.
    %                      specified as a Label
    %   ImageFiles         Cell array of fullpaths to the image files. The
    %                      number of elements in ImageFiles should be equal
    %                      to the number of items in the pop-up menu
    %   HelpForSelection   Cell array of character vectors to specify the
    %                      the details about the selected item. These will
    %                      be rendered in the HelpText panel under the
    %                      "About Your Selection" section.
    %   SelectedImage      Image corresponding to the selected item in the
    %                      drop-down list.
    %
    %   SELECTIONWITHDROPDOWN Methods(Inherited)
    %   show                Display the template/screen
    %   logMessage          log diagnostic messages to a file
    %   getNextScreenID     Return the Next Screen ID (name of the class)
    %   getPreviousScreenID Return the Previous Screen ID (name of the class)

    % Copyright 2016-2021 The MathWorks, Inc.

    properties(Access = {?matlab.hwmgr.internal.hwsetup.TemplateBase,...
            ?hwsetuptest.util.TemplateBaseTester})
        % Description - Description for the screen (Label)
        Description
        % SelectionDropDown - Pop-up menu to display the list of items to choose
        % from (DropDown)
        SelectionDropDown
        % SelectionLabel - Text describing the category of the items in the
        % pop-up menu e.g. hardware, devices etc. (Label)
        SelectionLabel
        % SelectedImage - Image corresponding to the selected Item in the
        % pop-up menu (Image)
        SelectedImage
    end

    methods
        function obj = SelectionWithDropDown(varargin)
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
            obj.SelectedImage = matlab.hwmgr.internal.hwsetup.Image.getInstance(widgetParent);

            % Set Title
            obj.Title.Text = '<Select a Hardware Board>';

            % Set Description Properties
            obj.Description.Text = '<Please select a device from the following options>';
            obj.Description.Color = matlab.hwmgr.internal.hwsetup.util.Color.BackgroundColorInput;

            % Set SelectionLabel Properties
            obj.SelectionLabel.Text = '<Board:>';
            obj.SelectionLabel.Color = matlab.hwmgr.internal.hwsetup.util.Color.BackgroundColorInput;

            if obj.TemplateLayout == matlab.hwmgr.internal.hwsetup.TemplateLayout.GRID
                % set up grid layout
                obj.ContentGrid.RowHeight = {'fit', 22, 'fit'};
                obj.ContentGrid.ColumnWidth = {'fit', '1x'};

                % arrange widgets
                obj.Description.Row = 1;
                obj.Description.Column = [1, 2];

                obj.SelectionLabel.Row = 2;
                obj.SelectionLabel.Column = 1;

                obj.SelectionDropDown.Row = 2;
                obj.SelectionDropDown.Column = 2;

                obj.SelectedImage.Row = 3;
                obj.SelectedImage.Column = [1, 2];
            else
                % set widget positions
                obj.Description.Position = [20, 330, 430, 40];
                obj.SelectionLabel.Position = [20, 310, 100, 20];
                obj.SelectionDropDown.Position = [120, 310, 200, 20];
                obj.SelectedImage.Position = [20, 40, 320, 270];
            end
        end
    end
end