classdef PropertyEditorDialog < controllib.ui.internal.dialog.AbstractDialog
    % Property Editor Dialog for Controls plots
    %
    % dlg = controllib.widget.internal.cstprefs.PropertyEditorDialog.getInstance();
    % show(dlg);

    % The dialog is singleton and contains methods to add/remove tabs.

    %   Copyright 2020-2022 The MathWorks, Inc.
    properties
        % TargetTag - string
        %   String that can be used to compare current and next target.
        TargetTag string
    end

    properties(Dependent)
        % Updating - logical
        %   Set Updating to true to show a progress bar. Set to false to remove progress bar.
        Updating
    end

    properties (Access=private)
        GridLayout      matlab.ui.container.GridLayout
        TabGroup        matlab.ui.container.TabGroup
        Tabs            matlab.ui.container.Tab
        TabLabels       string
        ButtonPanel     controllib.widget.internal.buttonpanel.ButtonPanel
        CloseButton     matlab.ui.control.Button
        ProgressBar
    end

    events
        PropertyEditorBeingClosed
    end

    methods
        function show(this)
            show@controllib.ui.internal.dialog.AbstractDialog(this);
        end

        function addTab(this,tabLabel,tabContent)
            % addTab(this,tabLabel,tabContent)
            %   tabLabel (string) is title of tab
            %   tabContent is container placed in the tab
            newTab = uitab(this.TabGroup);
            newTab.Title = tabLabel;
            this.Tabs = [this.Tabs,newTab];
            this.TabLabels = [this.TabLabels,tabLabel];
            g = uigridlayout(newTab,[1 1]);
            g.Scrollable = 'on';
            tabContent.Parent = g;
        end

        function selectedTabLabel = getSelectedTabLabel(this)
            % selectedTabLabel = getSelectedTabLabel(this)
            selectedTab = this.TabGroup.SelectedTab;
            selectedTabLabel = '';
            if ~isempty(selectedTab) && isvalid(selectedTab)
                selectedTabLabel = selectedTab.Title;
            end
        end

        function selectTab(this,tabLabel)
            % selectTab(this,tabLabel)
            %   tabLabel (string) is title of tab to select/show
            tab = this.Tabs(this.TabLabels == tabLabel);
            if ~isempty(tab)
                this.TabGroup.SelectedTab = tab;
            end
        end

        function deleteTab(this,tabLabel)
            % deleteTab(this,tabLabel)
            %   tabLabel (string) is title of tab to delete
            idx = find(this.TabLabels == tabLabel);
            if ~isempty(idx)
                delete(tab(idx));
                this.Tabs(idx) = [];
                this.TabLabels(idx) = [];
            end
        end

        function deleteAllTabs(this)
            % deleteAllTabs(this)
            delete(this.Tabs);
            this.Tabs = matlab.ui.container.Tab.empty;
            this.TabLabels = string.empty;
        end

        function Updating = get.Updating(this)
            % Return true if progress bar is active
            if isempty(this.ProgressBar) || ~isvalid(this.ProgressBar)
                Updating = false;
            else
                Updating = true;
            end
        end

        function set.Updating(this,Updating)
            % Show progress bar if set to true. Delete progress bar if set to false
            arguments
                this
                Updating (1,1) logical
            end
            if Updating
                this.ProgressBar = uiprogressdlg(getWidget(this),...
                    "Title",getString(message('Controllib:gui:strPropertyEditor')),"Indeterminate",true);
            else
                delete(this.ProgressBar);
            end
        end
    end

    methods (Access = protected)
        function buildUI(this)
            % Parent Layout
            this.GridLayout = uigridlayout(this.UIFigure,[2 1]);
            this.GridLayout.RowHeight = {'1x','fit'};
            this.GridLayout.ColumnWidth = {'1x'};
            this.GridLayout.Padding = 0;
            this.GridLayout.Scrollable = "on";
            % Tabs
            this.TabGroup = uitabgroup(this.GridLayout);
            % Button Panel
            this.ButtonPanel = controllib.widget.internal.buttonpanel.ButtonPanel(...
                this.GridLayout,"Help",'Commit',1);
            this.ButtonPanel.HelpButton.ButtonPushedFcn = ...
                @(es,ed) cbHelpButton(this);
            buttonPanelWidget = getWidget(this.ButtonPanel);
            buttonPanelWidget.Layout.Row = 2;
            buttonPanelWidget.Padding = [10 10 10 0];
            this.CloseButton = uibutton(buttonPanelWidget,'Text',...
                getString(message('Controllib:gui:strClose')));
            this.CloseButton.Layout.Column = 3;
            this.CloseButton.ButtonPushedFcn = @(es,ed) close(this);
            buttonPanelWidget.ColumnWidth{3} = this.ButtonPanel.ButtonWidth;
            % Set dialog size
            this.UIFigure.Position(3:4) = [430 360];
        end

        function connectUI(this)
            L = addlistener(this,'CloseEvent',@(es,ed) close(this));
            registerUIListeners(this,L,'DialogClose');
        end
    end

    methods (Access = private)
        function this = PropertyEditorDialog()
            this = this@controllib.ui.internal.dialog.AbstractDialog;
            this.Name = 'PropertyEditorDialog';
            this.Title = getString(message('Controllib:gui:strPropertyEditor'));
            % Build uifigure and dialog widgets
            buildDialog(this);
%             % Need to call "show" to create uifigure and call buildUI(this)
%             show(this);
%             % Hide dialog while instantiating
%             hide(this);
        end

        function cbHelpButton(~)
            % RE: This dialog serves both CST and SRO and Ident
            % Precedence: CST DOC, IDENT DOC, SDO DOC
            if isempty(ver('control')) || ~license('test','Control_Toolbox')
                if isempty(ver('ident')) || ~ license('test','Identification_Toolbox')
                    utSloptimGUIHelp('axes_properties');
                else
                    identguihelp('response_properties');
                end
            else
                ctrlguihelp('response_properties');
            end
        end

        function layout = findTabLayout(this,tabLabel)
            tab = this.Tabs(this.TabLabels == tabLabel);
            layout = [];
            if ~isempty(tab)
                layout = tab.Children;
            end
        end
    end

    methods (Static)
        function singleObj = getInstance
            % Return singleton instance
            mlock
            persistent localObj
            if isempty(localObj) || ~isvalid(localObj)
                localObj = controllib.chart.internal.widget.PropertyEditorDialog;
            end
            singleObj = localObj;
        end
    end

    methods (Hidden)
        function w = qeGetWidgets(this)
            w.TabGroup = this.TabGroup;
            w.Tabs = this.Tabs;
            w.CloseButton = this.CloseButton;
            w.HelpButton = this.ButtonPanel.HelpButton;
        end

        function closeAndDeleteDialog(es,~)
            delete(es);
        end
    end
end