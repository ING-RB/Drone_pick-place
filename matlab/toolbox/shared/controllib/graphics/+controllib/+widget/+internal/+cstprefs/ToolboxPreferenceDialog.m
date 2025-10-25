classdef ToolboxPreferenceDialog < handle
    %% Toolbox preferences dialog.
    % Common toolbox preference dialog used for Control System and System
    % Identification toolboxes.

    % Copyright 2021 The MathWorks, Inc.

    %% Propertires
    properties(Access=private)
        PreferencePanel
        ButtonPanel
        ToolboxPreferences
    end

    %% Constructor & destructor
    methods
        function this = ToolboxPreferenceDialog(tbxprefs)
            %% Constructs a toolbox preference dialog object.

            this.ToolboxPreferences = tbxprefs;
            buildPreferencePanel(this)
        end

        function delete(this)
            %% Releases resources.

            delete(this.PreferencePanel)
            clear this
        end

    end

    %% Public methods
    methods
        function show(this)
            %% Shows the dialog.

            if isempty(this.PreferencePanel) || ~isvalid(this.PreferencePanel) || ...
                    isempty(this.PreferencePanel.UIFigure) || ...
                    ~isvalid(this.PreferencePanel.UIFigure)
                buildPreferencePanel(this)
            end
            this.PreferencePanel.UIFigure.Visible = true;
        end

        function widget = getWidget(this)
            %% Returns the uifigure.

            widget = this.PreferencePanel.UIFigure;
        end
    end

    %% Private methods.
    methods (Access = private)
        function buildPreferencePanel(this)
            %% Builds preference panel.
            import controllib.widget.internal.cstprefs.ToolboxPreferencePanel

            % Delete the current preference panel.
            delete(this.PreferencePanel)

            % Build a new panel.
            showDialog = false;
            this.PreferencePanel = ToolboxPreferencePanel(...
                this.ToolboxPreferences,showDialog);
            updateDialogProperties(this)
            hideOnCloseRequest(this)
            addButtonPanel(this)
        end

        function updateDialogProperties(this)
            %% Updates dialog properties.

            this.PreferencePanel.UIFigure.Name = ...
                getString(message('Controllib:gui:strControlToolboxPreferences'));
            this.PreferencePanel.UIFigure.Position(4) = 420;
        end
            
        function addButtonPanel(this)
            %% Adds Help/OK/Cancel button panel.

            % Get current dialog layout.
            dialogLayout = this.PreferencePanel.UIFigure.Children(1);
            dialogLayout.RowHeight = [dialogLayout.RowHeight 'fit'];

            % Create button panel and get the button layout.
            buttonPanel = controllib.widget.internal.buttonpanel.ButtonPanel(...
                dialogLayout,["help" "ok" "cancel"]);
            this.ButtonPanel = buttonPanel;
            
            buttonPanelLayout = getWidget(buttonPanel);
            buttonPanelLayout.Layout.Row = numel(dialogLayout.RowHeight);
            buttonPanelLayout.Layout.Column = 1;
            buttonPanelLayout.Padding = 5;
            
            % Attach callback functions
            buttonPanel.HelpButton.ButtonPushedFcn = @(es,ed)cbHelpButton(this);            
            buttonPanel.OKButton.ButtonPushedFcn = @(es,ed)cbOKButton(this);            
            buttonPanel.CancelButton.ButtonPushedFcn = @(es,ed)cbCancelButton(this);             
        end

        function cbHelpButton(this) %#ok<MANU> 
            %% Callback function for help button.

            % This dialog serves both CST and IDENT
            % Precedence: CST DOC, IDENT DOC
            if isempty(ver('control')) || ~license('test','Control_Toolbox')
                identguihelp('toolbox_preferences');
            else
                ctrlguihelp('toolbox_preferences');
            end
        end

        function cbOKButton(this)
            %% Callback function for OK button.

            % Hide the dialog.
            this.PreferencePanel.UIFigure.Visible = false;
            
            % Save the latest preference values.
            this.PreferencePanel.commitPrefsChanges()
        end
        
        function hideOnCloseRequest(this)
            %% Hide the dialog when cross (X) button is clicked.

            fig = this.PreferencePanel.UIFigure;
            fig.CloseRequestFcn = @(src,evt)cbCancelButton(this);
        end
        
        function cbCancelButton(this)
            %% Hides the dialog and resets the tab contents.

            % Hide the dialog.
            this.PreferencePanel.UIFigure.Visible = false;

            % Reset the tab contents.
            this.PreferencePanel.reset()
        end
    end

    methods(Hidden)
        function widgets = qeGetWidgets(this)
            %% Returns widgets.

            widgets = this.PreferencePanel.qeGetWidgets();
            widgets.ButtonPanel = this.ButtonPanel;
        end

        function selectedTab = qeGetSelectedTab(this)
            %% Returns the current selected tab.

            selectedTab = this.PreferencePanel.TabGroup.SelectedTab;
        end
    end
end