classdef LaunchExamples < matlab.hwmgr.internal.hwsetup.TemplateBase
    % LAUNCHEXAMPLES - Template to enable the creation of screen
    % to notify the end user that the hardware setup is complete and
    % enable him to launch the support package examples
    %
    % LAUNCHEXAMPLES Properties
    %   Title(Inherited)  Title for the screen specified as a Label widget
    %   Description       Description for the screen specified as a Label
    %                     widget
    %   LaunchCheckbox    Checkbox to launch the support package examples
    %                     using SSI API
    %
    %   LAUNCHEXAMPLES Methods(Inherited)
    %   show                Display the template/screen
    %   logMessage          log diagnostic messages to a file
    %   getPreviousScreenID Return the Previous Screen ID (name of the class)

    % Copyright 2016-2022 The MathWorks, Inc.

    properties(Access = {?matlab.hwmgr.internal.hwsetup.TemplateBase,...
            ?hwsetuptest.util.TemplateBaseTester})
        % Description - Description for the screen (Label)
        Description
        %LaunchCheckbox - Checkbox to launch the support package examples
        LaunchCheckbox
    end

    methods
        function obj = LaunchExamples(varargin)
            obj@matlab.hwmgr.internal.hwsetup.TemplateBase(varargin{:});

            if obj.TemplateLayout == matlab.hwmgr.internal.hwsetup.TemplateLayout.GRID
                widgetParent = obj.ContentGrid;
            else
                widgetParent = obj.ContentPanel;
            end
            obj.Description = matlab.hwmgr.internal.hwsetup.Label.getInstance(widgetParent);

            % Set Title
            obj.Title.Text = message('hwsetup:template:LaunchExamplesTitle').getString;

            % Set Description Properties
            obj.Description.Text = message('hwsetup:template:LaunchExamplesDescription', obj.Workflow.Name).getString;
            obj.Description.Color = matlab.hwmgr.internal.hwsetup.util.Color.BackgroundColorInput;

            obj.LaunchCheckbox = matlab.hwmgr.internal.hwsetup.CheckBox.getInstance(widgetParent);
            obj.LaunchCheckbox.Text = message('hwsetup:template:LaunchExamplesCheckboxText').getString;
            obj.LaunchCheckbox.Value = true;
            obj.LaunchCheckbox.Visible = 'off';

            % Set HelpText properties containing default text(�lorem ipsum�) to empty strings
            obj.HelpText.AboutSelection = '';
            obj.HelpText.WhatToConsider = '';

            % Set callback when finish button is pushed
            obj.NextButton.ButtonPushedFcn = @obj.launchExamplesAndCloseUI;

            if isempty(obj.Workflow.LaunchExamplesFcn)
                % Get the support package root if it is not created yet issue a
                % warning to the user and do not display the LaunchCheckbox
                % since Examples are not available
                spkgRoot = matlabshared.supportpkg.internal.getSupportPackageRootNoCreate();
                spkgBaseCode = obj.Workflow.getBaseCode();

                if isempty(spkgRoot)
                    warningMsgId = 'hwsetup:template:LaunchExamplesCorruptSPRoot';
                    warning(warningMsgId, message(warningMsgId).getString)
                    return;
                end

                % Keep checkbox enabled if Examples are available
                if ~isempty(spkgBaseCode)
                    hasExamples = matlabshared.supportpkg.internal.ssi.getBaseCodesHavingExamples(...
                        cellstr(spkgBaseCode), spkgRoot);
                    if ~isempty(hasExamples)
                        obj.LaunchCheckbox.Visible = 'on';
                    end
                end
            end


            if obj.TemplateLayout == matlab.hwmgr.internal.hwsetup.TemplateLayout.GRID
                % set up grid layout
                obj.ContentGrid.RowHeight = {'fit', 'fit'};
                obj.ContentGrid.ColumnWidth = {'1x'};

                % arrange widgets
                obj.Description.Row = 1;
                obj.LaunchCheckbox.Row = 2;
            else
                % set widget positions
                obj.Description.Position = [20, 330, 430, 40];
                obj.LaunchCheckbox.Position = [20, 300, 430, 20];
            end
        end

        function launchExamplesAndCloseUI(obj, ~, ~)
            % LAUNCHEXAMPLESANDCLOSEUI - Callback when finish button is pushed that launches the
            % example page and call finish method to close HW Set up
            % window

            launchExamplesFcn = obj.Workflow.LaunchExamplesFcn;
            if ~isempty(launchExamplesFcn)
                if ~isempty(obj.LaunchCheckbox) && ~isempty(findprop(obj.LaunchCheckbox,'Value')) && obj.LaunchCheckbox.Value
                    feval(launchExamplesFcn)
                end
            else
                % Get the support package root. If it has not been created yet issue a
                % warning to the user and do not attempt to launch the examples
                currentSPRoot = matlabshared.supportpkg.internal.getSupportPackageRootNoCreate;

                if isempty(currentSPRoot)
                    corruptSPRootMSGID = 'hwsetup:template:LaunchExamplesCorruptSPRoot';
                    warning(corruptSPRootMSGID, message(corruptSPRootMSGID).getString)

                elseif obj.LaunchCheckbox.Visible && isprop(obj.LaunchCheckbox, 'Value') && obj.LaunchCheckbox.Value
                    matlabshared.supportpkg.internal.ssi.openExamplesForBaseCodes(...
                        cellstr(obj.Workflow.getBaseCode()), currentSPRoot);
                end
            end
            matlab.hwmgr.internal.hwsetup.TemplateBase.finish([], [], obj);
        end
    end
end
