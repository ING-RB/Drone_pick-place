classdef SelectionWithRadioGroup < matlab.hwmgr.internal.hwsetup.TemplateBase
    % SELECTIONWITHRADIOGROUP - Template to enable the creation of screen that
    % lets users to select an option from the available radio button group
    % and displays and an image to illustrate the option when the user
    % selects it.
    %
    % SELECTIONWITHDROPDOWN Properties
    %   Title(Inherited)    Title for the screen specified as a Label widget
    %   Description         Description for the screen specified as a Label
    %                       widget
    %   SelectionRadioGroup Radio button group to display the list of items to choose
    %                       specified as a RadioGroup widget
    %   SelectedImage       Image corresponding to the selected item in the
    %                       radio button group.
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
        % SelectionRadioGroup - Radio button group to display the list of items to choose
        % from (RadioGroup)
        SelectionRadioGroup
        % SelectedImage - Image corresponding to the selected Item in the
        % radio button group (Image)
        SelectedImage
    end

    methods
        function obj = SelectionWithRadioGroup(varargin)
            obj@matlab.hwmgr.internal.hwsetup.TemplateBase(varargin{:});

            if obj.TemplateLayout == matlab.hwmgr.internal.hwsetup.TemplateLayout.GRID
                widgetParent = obj.ContentGrid;
            else
                widgetParent = obj.ContentPanel;
            end

            % Create the widgets and parent them to the content panel
            obj.Description = matlab.hwmgr.internal.hwsetup.Label.getInstance(widgetParent);
            obj.SelectionRadioGroup = matlab.hwmgr.internal.hwsetup.RadioGroup.getInstance(widgetParent);
            obj.SelectedImage = matlab.hwmgr.internal.hwsetup.Image.getInstance(widgetParent);

            % Set Title
            obj.Title.Text = '<Configure Network Settings>';

            % Set Description Properties
            obj.Description.Text = '<Please select the network configuration from the following options>';

            % Set SelectionRadioGroup Properties
            obj.SelectionRadioGroup.Title = '<Network Settings>:';

            if obj.TemplateLayout == matlab.hwmgr.internal.hwsetup.TemplateLayout.GRID
                % set up grid layout
                obj.ContentGrid.RowHeight = {'fit', 'fit', 'fit'};
                obj.ContentGrid.ColumnWidth = {'1x'};

                % arrange widgets
                obj.Description.Row = 1;
                obj.SelectionRadioGroup.Row = 2;
                obj.SelectedImage.Row = 3;
            else
                % set widget positions
                obj.Description.Position = [20, 310, 430, 60];
                obj.SelectionRadioGroup.Position = [20, 240, 445, 100];
                obj.SelectedImage.Position = [20, 40, 320, 200];
            end
        end
    end
end
